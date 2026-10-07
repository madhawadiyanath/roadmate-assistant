import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';

/// Firestore access for in-app notifications
/// (`users/{uid}/notifications` sub-collection).
class NotificationService {
  final FirebaseFirestore? _dbOverride;
  NotificationService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  /// Live list, newest first (just-created docs float to the top).
  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _col(uid).limit(50).snapshots().map((s) {
      final list =
          s.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList();
      list.sort((a, b) {
        final at = a.createdAt;
        final bt = b.createdAt;
        if (at == null && bt == null) return 0;
        if (at == null) return -1;
        if (bt == null) return 1;
        return bt.compareTo(at);
      });
      return list;
    });
  }

  /// Notify [uid]. Called from the *acting* user's device (e.g. the mechanic
  /// accepting a job notifies the driver) — see the rules note on `create`.
  Future<void> send(
    String uid, {
    required String senderUid,
    required NotificationType type,
    required String title,
    String body = '',
    String requestId = '',
  }) =>
      _col(uid).add({
        ...AppNotification(
          id: '',
          type: type,
          title: title,
          body: body,
          requestId: requestId,
        ).toMap(),
        'senderUid': senderUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> markRead(String uid, String notificationId) =>
      _col(uid).doc(notificationId).update({'read': true});

  Future<void> markAllRead(String uid) async {
    final unread = await _col(uid).where('read', isEqualTo: false).get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}

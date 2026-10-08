import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';

/// Per-user inbox (`users/{uid}/notifications`).
///
/// Other users' devices write into a recipient's inbox via [send], which
/// stamps `senderUid` (Firestore rules require it to match the signed-in
/// user). Only the owner can read, mark read or delete.
/// Lists are sorted client-side (no composite index needed).
class NotificationService {
  final FirebaseFirestore? _dbOverride;

  NotificationService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notifications(String userUid) =>
      _db.collection('users').doc(userUid).collection('notifications');

  /// Write a notification into [recipientUid]'s inbox on behalf of
  /// [senderUid]. Returns the new id, or null when there is no recipient.
  Future<String?> send({
    required String recipientUid,
    required String senderUid,
    required NotificationType type,
    required String title,
    required String body,
    String requestId = '',
  }) async {
    if (recipientUid.trim().isEmpty) return null;
    assert(senderUid.isNotEmpty, 'senderUid is required by Firestore rules');

    final doc = await _notifications(recipientUid).add(AppNotification(
      id: '',
      userUid: recipientUid,
      type: type,
      title: title,
      body: body,
      read: false,
      senderUid: senderUid,
      requestId: requestId,
    ).toMap());
    return doc.id;
  }

  Future<void> createRequestAccepted({
    required String driverUid,
    required String mechanicName,
    required String senderUid,
    String requestId = '',
  }) async {
    await send(
      recipientUid: driverUid,
      senderUid: senderUid,
      type: NotificationType.accepted,
      title: 'Request accepted',
      body: '$mechanicName accepted your request and is on the way.',
      requestId: requestId,
    );
  }

  Future<void> createChatMessage({
    required String recipientUid,
    required String senderName,
    required String text,
    required String senderUid,
    String requestId = '',
  }) async {
    final preview = text.trim();
    await send(
      recipientUid: recipientUid,
      senderUid: senderUid,
      type: NotificationType.message,
      title: 'New chat message',
      body: preview.isEmpty ? '$senderName sent a message.' : '$senderName: $preview',
      requestId: requestId,
    );
  }

  /// Live inbox, newest first (just-created docs float to the top).
  Stream<List<AppNotification>> watchUserNotifications(String userUid) {
    return _notifications(userUid).limit(50).snapshots().map((s) {
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

  Future<void> markRead(String userUid, String id) =>
      _notifications(userUid).doc(id).update({'read': true});

  Future<void> markAllRead(String userUid) async {
    final unread =
        await _notifications(userUid).where('read', isEqualTo: false).get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}

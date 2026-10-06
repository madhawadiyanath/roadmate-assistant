import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_item.dart';

class NotificationService {
  final FirebaseFirestore? _dbOverride;

  NotificationService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notifications(String userUid) =>
      _db.collection('users').doc(userUid).collection('notifications');

  Future<void> add({
    required String userUid,
    required String title,
    required String body,
    String type = 'general',
    String requestId = '',
    String senderUid = '',
  }) async {
    if (userUid.trim().isEmpty) return;

    await _notifications(userUid).add(AppNotificationItem(
      id: '',
      userUid: userUid,
      title: title,
      body: body,
      type: type,
      requestId: requestId,
      senderUid: senderUid,
      read: false,
    ).toMap());
  }

  Future<void> createRequestAccepted({
    required String driverUid,
    required String mechanicName,
    String requestId = '',
  }) async {
    if (driverUid.trim().isEmpty) return;
    await add(
      userUid: driverUid,
      title: 'Request accepted',
      body: '$mechanicName accepted your request and is on the way.',
      type: 'request_accepted',
      requestId: requestId,
    );
  }

  Future<void> createChatMessage({
    required String recipientUid,
    required String senderName,
    required String text,
    String requestId = '',
    String senderUid = '',
  }) async {
    if (recipientUid.trim().isEmpty) return;

    final preview = text.trim();
    await add(
      userUid: recipientUid,
      title: 'New chat message',
      body: preview.isEmpty ? '$senderName sent a message.' : '$senderName: $preview',
      type: 'chat_message',
      requestId: requestId,
      senderUid: senderUid,
    );
  }

  Stream<List<AppNotificationItem>> watchUserNotifications(String userUid) {
    return _notifications(userUid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map(AppNotificationItem.fromDoc).toList());
  }

  Future<void> markAllRead(String userUid) async {
    final items = await _notifications(userUid).where('read', isEqualTo: false).get();
    for (final item in items.docs) {
      await item.reference.update({'read': true});
    }
  }
}

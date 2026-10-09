import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import 'notification_service.dart';

/// Per-request chat between the driver and the assigned mechanic.
/// Messages live in `requests/{requestId}/messages`.
///
/// Sorted client-side on purpose (no composite index needed).
class ChatService {
  final FirebaseFirestore? _dbOverride;
  ChatService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messages(String requestId) =>
      _db.collection('requests').doc(requestId).collection('messages');

  Future<void> send({
    required String requestId,
    required String senderUid,
    required String senderName,
    required String senderRole,
    required String text,
  }) async {
    final msg = text.trim();
    if (msg.isEmpty) return;

    await _messages(requestId).add(ChatMessage(
      id: '',
      senderUid: senderUid,
      senderName: senderName,
      senderRole: senderRole,
      text: msg,
    ).toMap());

    // Stamp the thread preview on the parent request so chat lists can
    // show unread badges from the request stream alone.
    try {
      await _db.collection('requests').doc(requestId).update({
        'lastMessageText':
            msg.length > 120 ? '${msg.substring(0, 120)}…' : msg,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderUid': senderUid,
      });
    } catch (_) {
      // Preview stamping is best-effort; the message itself is saved.
    }

    final requestDoc = await _db.collection('requests').doc(requestId).get();
    final data = requestDoc.data() ?? {};
    String recipientUid = '';
    if (senderRole == 'driver') {
      recipientUid = (data['mechanicUid'] as String? ?? '');
    } else if (senderRole == 'mechanic') {
      recipientUid = (data['driverUid'] as String? ?? '');
    }

    if (recipientUid.isNotEmpty) {
      await NotificationService(db: _db).createChatMessage(
        recipientUid: recipientUid,
        senderName: senderName,
        text: msg,
        requestId: requestId,
        senderUid: senderUid,
      );
    }
  }

  Stream<List<ChatMessage>> watch(String requestId) {
    return _messages(requestId)
        .limit(100)
        .snapshots()
        .map((s) => _oldestFirst(s.docs.map(ChatMessage.fromDoc)));
  }

  /// Record that [uid] has seen the thread (stored on their own user doc
  /// as `chatSeen: {requestId: timestamp}`).
  Future<void> markSeen({
    required String uid,
    required String requestId,
  }) async {
    if (uid.isEmpty || requestId.isEmpty) return;
    try {
      await _db.collection('users').doc(uid).update({
        'chatSeen.$requestId': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Seen-tracking is best-effort.
    }
  }

  /// Live map of requestId → seen timestamp for one user.
  Stream<Map<String, DateTime>> watchSeen(String uid) {
    if (uid.isEmpty) return Stream.value(const <String, DateTime>{});
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final out = <String, DateTime>{};
      final raw =
          (doc.data()?['chatSeen'] as Map?) ?? const <String, dynamic>{};
      raw.forEach((key, value) {
        if (value is Timestamp) {
          out['$key'] = value.toDate();
        }
      });
      return out;
    });
  }

  /// Edit own message text. Empty text is ignored.
  Future<void> edit({
    required String requestId,
    required String messageId,
    required String newText,
  }) async {
    final text = newText.trim();
    if (text.isEmpty) return;
    await _messages(requestId).doc(messageId).update({
      'text': text,
      'edited': true,
    });
  }

  /// Delete own message.
  Future<void> remove({
    required String requestId,
    required String messageId,
  }) =>
      _messages(requestId).doc(messageId).delete();

  static List<ChatMessage> _oldestFirst(Iterable<ChatMessage> items) {
    final list = items.toList();
    list.sort((a, b) {
      final at = a.createdAt;
      final bt = b.createdAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return at.compareTo(bt);
    });
    return list;
  }
}

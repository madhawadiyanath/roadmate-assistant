import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';

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
  }

  Stream<List<ChatMessage>> watch(String requestId) {
    return _messages(requestId)
        .limit(100)
        .snapshots()
        .map((s) => _oldestFirst(s.docs.map(ChatMessage.fromDoc)));
  }

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

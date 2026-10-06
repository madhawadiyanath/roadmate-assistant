import 'package:cloud_firestore/cloud_firestore.dart';

/// One chat message in `requests/{requestId}/messages/{messageId}`.
class ChatMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final String senderRole;
  final String text;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.senderRole,
    required this.text,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'senderUid': senderUid,
        'senderName': senderName,
        'senderRole': senderRole,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      senderUid: (m['senderUid'] ?? '') as String,
      senderName: (m['senderName'] ?? '') as String,
      senderRole: (m['senderRole'] ?? '') as String,
      text: (m['text'] ?? '') as String,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

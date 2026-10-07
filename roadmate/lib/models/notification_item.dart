import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationItem {
  final String id;
  final String userUid;
  final String title;
  final String body;
  final String type;
  final String requestId;
  final String senderUid;
  final bool read;
  final DateTime? createdAt;

  const AppNotificationItem({
    required this.id,
    required this.userUid,
    required this.title,
    required this.body,
    this.type = 'general',
    this.requestId = '',
    this.senderUid = '',
    this.read = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userUid': userUid,
        'title': title,
        'body': body,
        'type': type,
        if (requestId.isNotEmpty) 'requestId': requestId,
        if (senderUid.isNotEmpty) 'senderUid': senderUid,
        'read': read,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory AppNotificationItem.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppNotificationItem(
      id: doc.id,
      userUid: (data['userUid'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      body: (data['body'] ?? '') as String,
      type: (data['type'] ?? 'general') as String,
      requestId: (data['requestId'] ?? '') as String,
      senderUid: (data['senderUid'] ?? '') as String,
      read: (data['read'] ?? false) as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

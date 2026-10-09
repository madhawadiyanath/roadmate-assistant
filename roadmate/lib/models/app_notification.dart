import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  accepted,
  arriving,
  message,
  completed,
  receipt,
  cancelled;

  /// Also understands the legacy strings written before this enum existed
  /// (`request_accepted`, `chat_message`); anything unknown reads as a
  /// plain [message].
  static NotificationType fromString(String? v) {
    switch (v) {
      case 'request_accepted':
        return NotificationType.accepted;
      case 'chat_message':
        return NotificationType.message;
    }
    return NotificationType.values
        .firstWhere((t) => t.name == v, orElse: () => NotificationType.message);
  }
}

/// One entry in a user's inbox — `users/{uid}/notifications/{id}`.
///
/// This is the single notification model: `AppNotificationItem` (the
/// original class in notification_item.dart) is now an alias of it, so the
/// dashboards keep working unchanged.
class AppNotification {
  final String id;
  final String userUid;
  final NotificationType type;
  final String title;
  final String body;
  final bool read;
  final String senderUid;
  final String requestId;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    this.userUid = '',
    required this.type,
    required this.title,
    required this.body,
    this.read = false,
    this.senderUid = '',
    this.requestId = '',
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (userUid.isNotEmpty) 'userUid': userUid,
        'type': type.name,
        'title': title,
        'body': body,
        'read': read,
        'senderUid': senderUid,
        if (requestId.isNotEmpty) 'requestId': requestId,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) =>
      AppNotification(
        id: id,
        userUid: (map['userUid'] ?? '') as String,
        type: NotificationType.fromString(map['type'] as String?),
        title: (map['title'] ?? '') as String,
        body: (map['body'] ?? '') as String,
        read: (map['read'] ?? false) as bool,
        senderUid: (map['senderUid'] ?? '') as String,
        requestId: (map['requestId'] ?? '') as String,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}

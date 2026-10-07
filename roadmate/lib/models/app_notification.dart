import 'package:cloud_firestore/cloud_firestore.dart';

/// Decides the icon/colour of a notification row.
enum NotificationType {
  accepted,
  arriving,
  message,
  completed,
  receipt,
  cancelled,
  general;

  static NotificationType fromString(String? v) => NotificationType.values
      .firstWhere((t) => t.name == v, orElse: () => NotificationType.general);
}

/// In-app notification — Firestore doc in `users/{uid}/notifications/{id}`.
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final bool read;

  /// Optional link to `requests/{requestId}`.
  final String requestId;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body = '',
    this.read = false,
    this.requestId = '',
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'title': title,
        'body': body,
        'read': read,
        'requestId': requestId,
      };

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) =>
      AppNotification(
        id: id,
        type: NotificationType.fromString(m['type'] as String?),
        title: (m['title'] ?? '') as String,
        body: (m['body'] ?? '') as String,
        read: (m['read'] ?? false) as bool,
        requestId: (m['requestId'] ?? '') as String,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );
}

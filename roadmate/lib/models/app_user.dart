import 'package:cloud_firestore/cloud_firestore.dart';

/// User roles in RoadMate. Stored as string in Firestore (`users/{uid}.role`).
enum AppRole {
  driver('driver'),
  mechanic('mechanic');

  const AppRole(this.value);
  final String value;

  static AppRole fromString(String? v) =>
      AppRole.values.firstWhere((r) => r.value == v, orElse: () => AppRole.driver);
}

/// App user profile — Auth uid is the Firestore doc id (`users/{uid}`).
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final AppRole role;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.value,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        name: (map['name'] ?? '') as String,
        email: (map['email'] ?? '') as String,
        phone: (map['phone'] ?? '') as String,
        role: AppRole.fromString(map['role'] as String?),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}

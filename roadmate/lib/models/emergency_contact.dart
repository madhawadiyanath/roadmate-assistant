import 'package:cloud_firestore/cloud_firestore.dart';

/// Relationship tag on the Emergency Contacts cards.
enum ContactRelation {
  family('Family'),
  spouse('Spouse'),
  friend('Friend'),
  colleague('Colleague'),
  other('Other');

  const ContactRelation(this.label);
  final String label;

  static ContactRelation fromString(String? v) => ContactRelation.values
      .firstWhere((r) => r.name == v, orElse: () => ContactRelation.other);
}

/// Someone notified when the driver asks for urgent help —
/// Firestore doc in `users/{uid}/emergencyContacts/{id}`.
class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final ContactRelation relation;
  final DateTime? createdAt;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relation = ContactRelation.other,
    this.createdAt,
  });

  /// "Kamala Perera" -> "KP" for the round avatar.
  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final last = parts.length > 1 ? parts.last[0] : '';
    return (parts.first[0] + last).toUpperCase();
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'relation': relation.name,
      };

  factory EmergencyContact.fromMap(String id, Map<String, dynamic> m) =>
      EmergencyContact(
        id: id,
        name: (m['name'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        relation: ContactRelation.fromString(m['relation'] as String?),
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );
}

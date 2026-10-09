import 'package:cloud_firestore/cloud_firestore.dart';

enum ContactRelation {
  family('Family'),
  spouse('Spouse'),
  friend('Friend'),
  colleague('Colleague');

  const ContactRelation(this.label);
  final String label;

  static ContactRelation fromString(String? v) => ContactRelation.values
      .firstWhere((r) => r.name == v, orElse: () => ContactRelation.family);
}

/// Someone notified in an emergency — `users/{uid}/emergencyContacts/{id}`.
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
    this.relation = ContactRelation.family,
    this.createdAt,
  });

  /// Avatar letters: "Kamala Perera" → "KP", "Ruwan" → "R", blank → "?".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'relation': relation.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory EmergencyContact.fromMap(String id, Map<String, dynamic> map) =>
      EmergencyContact(
        id: id,
        name: (map['name'] ?? '') as String,
        phone: (map['phone'] ?? '') as String,
        relation: ContactRelation.fromString(map['relation'] as String?),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}

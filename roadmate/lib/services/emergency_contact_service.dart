import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/emergency_contact.dart';

/// Firestore CRUD for emergency contacts (`users/{uid}/emergencyContacts`).
/// Sorted client-side (no composite index needed).
class EmergencyContactService {
  final FirebaseFirestore? _dbOverride;
  EmergencyContactService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _contacts(String uid) =>
      _db.collection('users').doc(uid).collection('emergencyContacts');

  /// Live list, oldest first (the order the driver added them in).
  Stream<List<EmergencyContact>> watchContacts(String uid) {
    return _contacts(uid).snapshots().map((s) => _oldestFirst(
        s.docs.map((d) => EmergencyContact.fromMap(d.id, d.data()))));
  }

  Future<String> addContact(String uid, EmergencyContact contact) async {
    final doc = await _contacts(uid).add(EmergencyContact(
      id: '',
      name: contact.name.trim(),
      phone: contact.phone.trim(),
      relation: contact.relation,
    ).toMap());
    return doc.id;
  }

  /// Edit a contact. Keeps the original `createdAt` (and list position).
  Future<void> updateContact(String uid, EmergencyContact contact) {
    final map = EmergencyContact(
      id: contact.id,
      name: contact.name.trim(),
      phone: contact.phone.trim(),
      relation: contact.relation,
    ).toMap()
      ..remove('createdAt');
    return _contacts(uid).doc(contact.id).update(map);
  }

  Future<void> deleteContact(String uid, String id) =>
      _contacts(uid).doc(id).delete();

  /// Oldest first; just-created docs (timestamp pending) go last.
  static List<EmergencyContact> _oldestFirst(
      Iterable<EmergencyContact> items) {
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

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/emergency_contact.dart';

/// Firestore CRUD for emergency contacts
/// (`users/{uid}/emergencyContacts` sub-collection).
class EmergencyContactService {
  final FirebaseFirestore? _dbOverride;
  EmergencyContactService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('emergencyContacts');

  /// Live list, oldest first so the order stays stable as contacts are added.
  Stream<List<EmergencyContact>> watchContacts(String uid) {
    return _col(uid).snapshots().map((s) {
      final list =
          s.docs.map((d) => EmergencyContact.fromMap(d.id, d.data())).toList();
      list.sort((a, b) {
        final at = a.createdAt;
        final bt = b.createdAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1; // just-created goes last
        if (bt == null) return -1;
        return at.compareTo(bt);
      });
      return list;
    });
  }

  Future<String> addContact(String uid, EmergencyContact contact) async {
    final doc = await _col(uid).add({
      ...contact.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateContact(String uid, EmergencyContact contact) =>
      _col(uid).doc(contact.id).update(contact.toMap());

  Future<void> deleteContact(String uid, String contactId) =>
      _col(uid).doc(contactId).delete();
}

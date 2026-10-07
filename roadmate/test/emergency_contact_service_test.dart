import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/emergency_contact.dart';
import 'package:roadmate/services/emergency_contact_service.dart';

void main() {
  const uid = 'u1';

  test('initials: two words, one word, extra spaces, blank', () {
    EmergencyContact c(String n) =>
        EmergencyContact(id: '1', name: n, phone: '0');
    expect(c('Kamala Perera').initials, 'KP');
    expect(c('ruwan silva').initials, 'RS');
    expect(c('Sunil').initials, 'S');
    expect(c('  Dilini   Anne   Perera ').initials, 'DP');
    expect(c('   ').initials, '?');
  });

  test('model round-trips and unknown relation falls back', () {
    // toMap() uses FieldValue; install the fake factory before touching it.
    FakeFirebaseFirestore();
    const contact = EmergencyContact(
        id: 'a',
        name: 'Dilini Perera',
        phone: '+94713456789',
        relation: ContactRelation.spouse);
    // createdAt is a server-side FieldValue, only present once stored.
    final back = EmergencyContact.fromMap(
        'a', contact.toMap()..remove('createdAt'));
    expect(back.name, 'Dilini Perera');
    expect(back.relation, ContactRelation.spouse);
    expect(back.relation.label, 'Spouse');
    expect(EmergencyContact.fromMap('b', {'name': 'X', 'phone': '1'}).relation,
        ContactRelation.family);
  });

  test('add, edit and delete contacts', () async {
    final db = FakeFirebaseFirestore();
    final service = EmergencyContactService(db: db);

    final a = await service.addContact(
      uid,
      const EmergencyContact(
          id: '', name: '  Kamala Perera ', phone: ' +94772345678 '),
    );
    final b = await service.addContact(
      uid,
      const EmergencyContact(
          id: '',
          name: 'Ruwan Silva',
          phone: '+94764567890',
          relation: ContactRelation.friend),
    );

    var list = await service.watchContacts(uid).first;
    expect(list, hasLength(2));
    final first = list.firstWhere((c) => c.id == a);
    expect(first.name, 'Kamala Perera'); // trimmed
    expect(first.phone, '+94772345678');
    expect(first.relation, ContactRelation.family);
    final createdAt = first.createdAt;
    expect(createdAt, isNotNull);

    await service.updateContact(
      uid,
      EmergencyContact(
          id: a,
          name: 'Kamala P',
          phone: '+94770000000',
          relation: ContactRelation.colleague),
    );
    list = await service.watchContacts(uid).first;
    final edited = list.firstWhere((c) => c.id == a);
    expect(edited.name, 'Kamala P');
    expect(edited.relation, ContactRelation.colleague);
    expect(edited.createdAt, createdAt); // position preserved

    await service.deleteContact(uid, b);
    list = await service.watchContacts(uid).first;
    expect(list.map((c) => c.id), [a]);
  });

  test('contacts list oldest first', () async {
    final db = FakeFirebaseFirestore();
    final col = db.collection('users').doc(uid).collection('emergencyContacts');
    await col.doc('new').set({
      'name': 'New',
      'phone': '2',
      'relation': 'friend',
      'createdAt': DateTime(2026, 5, 2),
    });
    await col.doc('old').set({
      'name': 'Old',
      'phone': '1',
      'relation': 'family',
      'createdAt': DateTime(2026, 5, 1),
    });
    final list = await EmergencyContactService(db: db).watchContacts(uid).first;
    expect(list.map((c) => c.id), ['old', 'new']);
  });
}

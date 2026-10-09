import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/services/auth_service.dart';

/// Profile CRUD roundtrip against a fake Firestore.
void main() {
  test('updateProfile saves name/phone, returns fresh profile', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('u1').set({
      'name': 'Kasun',
      'email': 'k@e.com',
      'phone': '',
      'role': 'driver',
      'vehicle': 'Legacy Car',
      'plate': 'OLD 0001',
    });
    final auth = AuthService(db: db);

    final updated = await auth.updateProfile(
      uid: 'u1',
      name: '  Kasun Perera ',
      phone: ' +94771234567 ',
    );

    expect(updated.name, 'Kasun Perera');
    expect(updated.phone, '+94771234567');
    expect(updated.email, 'k@e.com');

    // Vehicle fields are not part of the profile edit any more: whatever
    // is stored there is left exactly as it was.
    final doc = (await db.collection('users').doc('u1').get()).data()!;
    expect(doc['vehicle'], 'Legacy Car');
    expect(doc['plate'], 'OLD 0001');
    expect(doc['role'], 'driver');
  });

  test('adminUpdateRole changes role and nothing else', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('u1').set({
      'name': 'Kasun',
      'email': 'k@e.com',
      'phone': '',
      'role': 'driver',
    });
    final auth = AuthService(db: db);

    await auth.adminUpdateRole(uid: 'u1', role: AppRole.mechanic);
    var profile = await auth.getProfile('u1');
    expect(profile?.role, AppRole.mechanic);
    expect(profile?.name, 'Kasun');

    await auth.adminUpdateRole(uid: 'u1', role: AppRole.admin);
    profile = await auth.getProfile('u1');
    expect(profile?.role, AppRole.admin);
  });
}

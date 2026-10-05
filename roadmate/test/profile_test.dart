import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/services/auth_service.dart';

/// Profile CRUD roundtrip against a fake Firestore.
void main() {
  test('updateProfile saves and returns fresh profile', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('u1').set({
      'name': 'Kasun',
      'email': 'k@e.com',
      'phone': '',
      'role': 'driver',
      'vehicle': '',
      'plate': '',
    });
    final auth = AuthService(db: db);

    final updated = await auth.updateProfile(
      uid: 'u1',
      name: 'Kasun Perera',
      phone: '+94771234567',
      vehicle: 'Toyota Axio',
      plate: 'ABC 1234',
    );

    expect(updated.name, 'Kasun Perera');
    expect(updated.phone, '+94771234567');
    expect(updated.vehicleDisplay, 'Toyota Axio • ABC 1234');

    final reread = await auth.getProfile('u1');
    expect(reread?.vehiclePlate, 'ABC 1234');
  });
}

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/garage.dart';
import 'package:roadmate/services/garage_service.dart';

/// Garage directory CRUD: mechanic saves listing, driver reads it.
void main() {
  test('garage listing saved and listed open-first', () async {
    final db = FakeFirebaseFirestore();
    final garages = GarageService(db: db);

    await garages.saveMyGarage(const GarageProfile(
      ownerUid: 'mech1',
      name: 'City Auto Garage',
      area: 'Colombo 03',
      phone: '+94112345678',
      services: ['Flat Tyre', 'Towing'],
      rating: 4.8,
      jobsDone: 240,
      open: true,
    ));
    await garages.saveMyGarage(const GarageProfile(
      ownerUid: 'mech2',
      name: 'Night Owl Repairs',
      area: 'Nugegoda',
      phone: '+94112876543',
      services: ['Jump Start'],
      rating: 4.5,
      jobsDone: 96,
      open: false,
    ));

    final mine = await garages.getMyGarage('mech1');
    expect(mine?.name, 'City Auto Garage');
    expect(mine?.services, ['Flat Tyre', 'Towing']);

    final all = await garages.watchGarages().first;
    expect(all, hasLength(2));
    // Open garages first.
    expect(all.first.ownerUid, 'mech1');
    expect(all.first.open, isTrue);
  });
}

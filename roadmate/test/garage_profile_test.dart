import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/garage_profile.dart';
import 'package:roadmate/services/garage_service.dart';

void main() {
  test('GarageProfile CRUD roundtrip against fake Firestore', () async {
    final db = FakeFirebaseFirestore();
    final service = GarageService(db: db);
    const uid = 'mech_garage_001';

    // 1. Initial should be null
    final initial = await service.getGarageProfile(uid);
    expect(initial, isNull);

    // 2. Save Garage Profile
    const profile = GarageProfile(
      ownerUid: uid,
      garageName: 'Southern Auto Express',
      registrationNumber: 'PV-99124',
      hotline: '0779988776',
      address: 'No. 45, Galle Road, Matara',
      latitude: 5.9549,
      longitude: 80.5550,
      operatingHours: '07:30 AM - 08:30 PM',
      is24Hours: false,
      isOpen: true,
      facilities: ['Hydraulic Lift', 'Wheel Alignment'],
    );

    await service.saveGarageProfile(uid, profile);

    // 3. Read profile
    final saved = await service.getGarageProfile(uid);
    expect(saved, isNotNull);
    expect(saved!.garageName, 'Southern Auto Express');
    expect(saved.registrationNumber, 'PV-99124');
    expect(saved.hotline, '0779988776');
    expect(saved.address, 'No. 45, Galle Road, Matara');
    expect(saved.latitude, 5.9549);
    expect(saved.longitude, 80.5550);
    expect(saved.hasLocation, isTrue);
    expect(saved.isOpen, isTrue);
    expect(saved.facilities.length, 2);

    // 4. Watch Stream
    final streamVal = await service.watchGarageProfile(uid).first;
    expect(streamVal, isNotNull);
    expect(streamVal!.garageName, 'Southern Auto Express');

    // 5. Toggle Open Status
    await service.toggleOpenStatus(uid, false);
    final afterToggle = await service.getGarageProfile(uid);
    expect(afterToggle!.isOpen, isFalse);

    // 6. Update Profile
    final updated = saved.copyWith(
      garageName: 'Southern Auto Express & 24/7 Recovery',
      is24Hours: true,
      operatingHours: 'Open 24 Hours',
    );
    await service.saveGarageProfile(uid, updated);

    final finalProfile = await service.getGarageProfile(uid);
    expect(finalProfile!.garageName,
        'Southern Auto Express & 24/7 Recovery');
    expect(finalProfile.is24Hours, isTrue);
  });
}

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/mechanic_service.dart';
import 'package:roadmate/services/mechanic_service_service.dart';

void main() {
  test('MechanicService CRUD roundtrip against fake Firestore', () async {
    final db = FakeFirebaseFirestore();
    final service = MechanicServiceService(db: db);
    const uid = 'mech_123';

    // 1. Add Service
    final newService = const MechanicService(
      id: '',
      title: 'Battery Booster Jumpstart',
      category: ServiceCategory.battery,
      basePrice: 2500,
      estimatedDurationMinutes: 20,
      description: 'Quick roadside jumpstart',
      isAvailable: true,
    );

    final id = await service.addService(uid, newService);
    expect(id, isNotEmpty);

    // 2. Read Single Service
    final retrieved = await service.getService(uid, id);
    expect(retrieved, isNotNull);
    expect(retrieved!.title, 'Battery Booster Jumpstart');
    expect(retrieved.basePrice, 2500);
    expect(retrieved.category, ServiceCategory.battery);
    expect(retrieved.durationText, '20 mins');
    expect(retrieved.formattedPrice, 'Rs. 2500');

    // 3. Watch Stream
    final list = await service.watchServices(uid).first;
    expect(list.length, 1);
    expect(list.first.id, id);

    // 4. Update Service
    final updated = retrieved.copyWith(
      title: 'Heavy Duty Jumpstart',
      basePrice: 3000,
    );
    await service.updateService(uid, updated);

    final afterUpdate = await service.getService(uid, id);
    expect(afterUpdate!.title, 'Heavy Duty Jumpstart');
    expect(afterUpdate.basePrice, 3000);

    // 5. Toggle Availability
    await service.toggleAvailability(uid, id, false);
    final afterToggle = await service.getService(uid, id);
    expect(afterToggle!.isAvailable, isFalse);

    // 6. Delete Service
    await service.deleteService(uid, id);
    final afterDelete = await service.getService(uid, id);
    expect(afterDelete, isNull);

    final emptyList = await service.watchServices(uid).first;
    expect(emptyList, isEmpty);
  });
}

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roadmate/models/app_notification.dart';
import 'package:roadmate/models/emergency_contact.dart';
import 'package:roadmate/models/vehicle.dart';
import 'package:roadmate/services/emergency_contact_service.dart';
import 'package:roadmate/services/notification_service.dart';
import 'package:roadmate/services/vehicle_service.dart';

const _uid = 'u1';

Vehicle _v(String make, String plate) =>
    Vehicle(id: '', make: make, model: 'X', year: 2020, plateNo: plate);

void main() {
  group('Vehicle model', () {
    test('toMap / fromMap round-trip and unknown enums fall back', () {
      final v = Vehicle(
        id: 'a',
        make: 'Toyota',
        model: 'Corolla',
        year: 2020,
        plateNo: 'CAK 1234',
        type: VehicleType.van,
        fuelType: FuelType.diesel,
        color: 'Blue',
      );
      final back = Vehicle.fromMap('a', v.toMap());
      expect(back.displayName, 'Toyota Corolla');
      expect(back.type, VehicleType.van);
      expect(back.fuelType, FuelType.diesel);
      expect(back.year, 2020);
      expect(Vehicle.fromMap('b', {'type': 'spaceship'}).type, VehicleType.car);
    });
  });

  group('VehicleService', () {
    test('first vehicle becomes default; setDefault keeps exactly one',
        () async {
      final svc = VehicleService(db: FakeFirebaseFirestore());
      final a = await svc.addVehicle(_uid, _v('Toyota', 'A1'));
      final b = await svc.addVehicle(_uid, _v('Honda', 'B2'));

      var list = await svc.watchVehicles(_uid).first;
      expect(list.where((v) => v.isDefault).map((v) => v.id), [a]);

      await svc.setDefault(_uid, b);
      list = await svc.watchVehicles(_uid).first;
      expect(list.where((v) => v.isDefault).map((v) => v.id), [b]);
      expect(list.first.id, b); // default sorts first
    });

    test('deleting the default promotes another vehicle', () async {
      final svc = VehicleService(db: FakeFirebaseFirestore());
      final a = await svc.addVehicle(_uid, _v('Toyota', 'A1'));
      final b = await svc.addVehicle(_uid, _v('Honda', 'B2'));
      await svc.deleteVehicle(_uid, a);

      final list = await svc.watchVehicles(_uid).first;
      expect(list.single.id, b);
      expect(list.single.isDefault, isTrue);
    });

    test('updateVehicle edits fields but not the default flag', () async {
      final svc = VehicleService(db: FakeFirebaseFirestore());
      final a = await svc.addVehicle(_uid, _v('Toyota', 'A1'));
      final v = (await svc.getVehicle(_uid, a))!;
      await svc.updateVehicle(_uid, v.copyWith(color: 'Red', isDefault: false));

      final after = (await svc.getVehicle(_uid, a))!;
      expect(after.color, 'Red');
      expect(after.isDefault, isTrue);
    });
  });

  group('EmergencyContactService', () {
    test('add / update / delete', () async {
      final svc = EmergencyContactService(db: FakeFirebaseFirestore());
      final id = await svc.addContact(
        _uid,
        const EmergencyContact(
            id: '',
            name: 'Kamala Perera',
            phone: '+94772345678',
            relation: ContactRelation.family),
      );
      var list = await svc.watchContacts(_uid).first;
      expect(list.single.initials, 'KP');
      expect(list.single.relation, ContactRelation.family);

      await svc.updateContact(
          _uid,
          EmergencyContact(
              id: id,
              name: 'Kamala P',
              phone: '+94772345678',
              relation: ContactRelation.spouse));
      list = await svc.watchContacts(_uid).first;
      expect(list.single.relation, ContactRelation.spouse);

      await svc.deleteContact(_uid, id);
      expect(await svc.watchContacts(_uid).first, isEmpty);
    });
  });

  group('NotificationService', () {
    test('send, then markRead / markAllRead', () async {
      final svc = NotificationService(db: FakeFirebaseFirestore());
      await svc.send(_uid,
          senderUid: 'mech1',
          type: NotificationType.accepted,
          title: 'Mechanic accepted your request');
      await svc.send(_uid,
          senderUid: 'mech1',
          type: NotificationType.arriving,
          title: 'Technician is arriving');

      var list = await svc.watchNotifications(_uid).first;
      expect(list, hasLength(2));
      expect(list.every((n) => !n.read), isTrue);

      await svc.markRead(_uid, list.first.id);
      list = await svc.watchNotifications(_uid).first;
      expect(list.where((n) => n.read), hasLength(1));

      await svc.markAllRead(_uid);
      list = await svc.watchNotifications(_uid).first;
      expect(list.every((n) => n.read), isTrue);
    });
  });
}

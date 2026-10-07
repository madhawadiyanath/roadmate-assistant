import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/vehicle.dart';
import 'package:roadmate/services/vehicle_service.dart';

Vehicle _car(String make, String model, String plate,
        {VehicleType type = VehicleType.car}) =>
    Vehicle(
      id: '',
      make: make,
      model: model,
      year: 2020,
      plateNo: plate,
      type: type,
      fuelType: 'Petrol',
      color: 'Blue',
    );

/// Garage rules: first vehicle is default, exactly one default at all
/// times, edits never move the default flag.
void main() {
  late FakeFirebaseFirestore db;
  late VehicleService service;
  const uid = 'u1';

  setUp(() {
    db = FakeFirebaseFirestore();
    service = VehicleService(db: db);
  });

  Future<List<Vehicle>> garage() => service.watchVehicles(uid).first;

  test('model round-trips through toMap/fromMap', () {
    final v = Vehicle(
      id: 'x',
      make: 'Honda',
      model: 'Beat',
      year: 2021,
      plateNo: 'BBF 5678',
      type: VehicleType.bike,
      fuelType: 'Petrol',
      color: 'Red',
      photoUrl: 'http://img/1.jpg',
    );
    // createdAt is a server-side FieldValue, only present once stored.
    final back = Vehicle.fromMap('x', v.toMap()..remove('createdAt'));
    expect(back.make, 'Honda');
    expect(back.year, 2021);
    expect(back.type, VehicleType.bike);
    expect(back.photoUrl, 'http://img/1.jpg');
    expect(back.name, 'Honda Beat');
    expect(back.display, 'Honda Beat • BBF 5678');
    expect(Vehicle.fromMap('y', {'make': 'A'}).type, VehicleType.other);
  });

  test('first saved vehicle becomes default, later ones do not', () async {
    final a = await service.addVehicle(uid, _car('Toyota', 'Corolla', 'CAK 1234'));
    final b = await service.addVehicle(uid, _car('Honda', 'Beat', 'BBF 5678'));

    final list = await garage();
    expect(list, hasLength(2));
    expect(list.first.id, a);
    expect(list.where((v) => v.isDefault).map((v) => v.id), [a]);
    expect(list.firstWhere((v) => v.id == b).isDefault, isFalse);
  });

  test('caller-supplied isDefault is ignored on add', () async {
    await service.addVehicle(uid, _car('Toyota', 'Corolla', 'CAK 1234'));
    await service.addVehicle(
      uid,
      Vehicle(
          id: '',
          make: 'Honda',
          model: 'Beat',
          year: 2021,
          plateNo: 'BBF 5678',
          isDefault: true),
    );
    expect((await garage()).where((v) => v.isDefault), hasLength(1));
  });

  test('setDefault leaves exactly one default', () async {
    await service.addVehicle(uid, _car('Toyota', 'Corolla', 'CAK 1234'));
    final b = await service.addVehicle(uid, _car('Honda', 'Beat', 'BBF 5678'));
    final c = await service.addVehicle(uid, _car('Suzuki', 'Wagon R', 'CBA 9021'));

    await service.setDefault(uid, c);
    var list = await garage();
    expect(list.where((v) => v.isDefault).map((v) => v.id), [c]);
    expect(list.first.id, c);

    await service.setDefault(uid, b);
    list = await garage();
    expect(list.where((v) => v.isDefault).map((v) => v.id), [b]);

    expect(() => service.setDefault(uid, 'missing'), throwsStateError);
    expect((await garage()).where((v) => v.isDefault), hasLength(1));
  });

  test('updateVehicle edits details but never the default flag', () async {
    final a = await service.addVehicle(uid, _car('Toyota', 'Corolla', 'CAK 1234'));
    final b = await service.addVehicle(uid, _car('Honda', 'Beat', 'BBF 5678'));

    // Edit built from a stale copy that claims the opposite flags.
    await service.updateVehicle(
      uid,
      Vehicle(
          id: a,
          make: 'Toyota',
          model: 'Axio',
          year: 2018,
          plateNo: 'CAK 1234',
          isDefault: false),
    );
    await service.updateVehicle(
      uid,
      Vehicle(
          id: b,
          make: 'Honda',
          model: 'Dio',
          year: 2022,
          plateNo: 'BBF 5678',
          isDefault: true),
    );

    final list = await garage();
    final va = list.firstWhere((v) => v.id == a);
    final vb = list.firstWhere((v) => v.id == b);
    expect(va.model, 'Axio');
    expect(va.year, 2018);
    expect(va.isDefault, isTrue);
    expect(vb.model, 'Dio');
    expect(vb.isDefault, isFalse);
    expect(va.createdAt, isNotNull);
  });

  test('deleting the default promotes another; deleting others does not',
      () async {
    final a = await service.addVehicle(uid, _car('Toyota', 'Corolla', 'CAK 1234'));
    final b = await service.addVehicle(uid, _car('Honda', 'Beat', 'BBF 5678'));
    final c = await service.addVehicle(uid, _car('Suzuki', 'Wagon R', 'CBA 9021'));

    await service.deleteVehicle(uid, b);
    var list = await garage();
    expect(list.map((v) => v.id), containsAll([a, c]));
    expect(list.where((v) => v.isDefault).map((v) => v.id), [a]);

    await service.deleteVehicle(uid, a);
    list = await garage();
    expect(list, hasLength(1));
    expect(list.single.id, c);
    expect(list.single.isDefault, isTrue);

    await service.deleteVehicle(uid, c);
    expect(await garage(), isEmpty);
    // Deleting something already gone is a no-op.
    await service.deleteVehicle(uid, c);
  });

  test('watchVehicle follows edits and emits null after delete', () async {
    final a = await service.addVehicle(uid, _car('Toyota', 'Corolla', 'CAK 1234'));
    final stream = service.watchVehicle(uid, a);
    expect((await stream.first)?.model, 'Corolla');

    await service.updateVehicle(
      uid,
      Vehicle(id: a, make: 'Toyota', model: 'Axio', year: 2020, plateNo: 'CAK 1234'),
    );
    expect((await service.watchVehicle(uid, a).first)?.model, 'Axio');

    await service.deleteVehicle(uid, a);
    expect(await service.watchVehicle(uid, a).first, isNull);
  });

  test('watchDefaultVehicle tracks the default', () async {
    expect(await service.watchDefaultVehicle(uid).first, isNull);
    await service.addVehicle(uid, _car('Toyota', 'Corolla', 'CAK 1234'));
    final b = await service.addVehicle(uid, _car('Honda', 'Beat', 'BBF 5678'));
    expect((await service.watchDefaultVehicle(uid).first)?.make, 'Toyota');
    await service.setDefault(uid, b);
    expect((await service.watchDefaultVehicle(uid).first)?.id, b);
  });

  test('vehicles are private per user', () async {
    await service.addVehicle('u1', _car('Toyota', 'Corolla', 'CAK 1234'));
    expect(await service.watchVehicles('u2').first, isEmpty);
  });
}

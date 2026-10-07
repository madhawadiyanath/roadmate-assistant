import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vehicle.dart';

/// Firestore CRUD for a driver's garage (`users/{uid}/vehicles`).
///
/// Invariant: a non-empty garage always has exactly one default vehicle.
/// Lists are sorted client-side (no composite index needed).
class VehicleService {
  final FirebaseFirestore? _dbOverride;
  VehicleService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _vehicles(String uid) =>
      _db.collection('users').doc(uid).collection('vehicles');

  /// Live garage: default vehicle first, then newest first.
  Stream<List<Vehicle>> watchVehicles(String uid) {
    return _vehicles(uid).snapshots().map(
        (s) => _ordered(s.docs.map((d) => Vehicle.fromMap(d.id, d.data()))));
  }

  /// Live view of one vehicle; emits null once it is deleted.
  Stream<Vehicle?> watchVehicle(String uid, String id) {
    return _vehicles(uid).doc(id).snapshots().map((d) =>
        d.exists && d.data() != null ? Vehicle.fromMap(d.id, d.data()!) : null);
  }

  /// Live default vehicle (null when the garage is empty).
  Stream<Vehicle?> watchDefaultVehicle(String uid) {
    return watchVehicles(uid).map((list) {
      for (final v in list) {
        if (v.isDefault) return v;
      }
      return null;
    });
  }

  /// Save a new vehicle and return its id. The first vehicle (or any
  /// vehicle added to a garage without a default) becomes the default;
  /// the incoming [Vehicle.isDefault] flag is ignored.
  Future<String> addVehicle(String uid, Vehicle vehicle) async {
    final existing = await _vehicles(uid).get();
    final hasDefault = existing.docs.any((d) => d.data()['isDefault'] == true);
    final map = Vehicle(
      id: '',
      make: vehicle.make.trim(),
      model: vehicle.model.trim(),
      year: vehicle.year,
      plateNo: vehicle.plateNo.trim(),
      type: vehicle.type,
      fuelType: vehicle.fuelType.trim(),
      color: vehicle.color.trim(),
      isDefault: !hasDefault,
      photoUrl: vehicle.photoUrl,
    ).toMap();
    final doc = await _vehicles(uid).add(map);
    return doc.id;
  }

  /// Edit a vehicle's details. Never touches `isDefault` or `createdAt`.
  Future<void> updateVehicle(String uid, Vehicle vehicle) {
    final map = vehicle.toMap()
      ..remove('isDefault')
      ..remove('createdAt');
    return _vehicles(uid).doc(vehicle.id).update(map);
  }

  /// Make [id] the default; every other vehicle is cleared.
  Future<void> setDefault(String uid, String id) async {
    final all = await _vehicles(uid).get();
    if (!all.docs.any((d) => d.id == id)) {
      throw StateError('Vehicle $id not found');
    }
    final batch = _db.batch();
    for (final d in all.docs) {
      final shouldBeDefault = d.id == id;
      if ((d.data()['isDefault'] == true) != shouldBeDefault) {
        batch.update(d.reference, {'isDefault': shouldBeDefault});
      }
    }
    await batch.commit();
  }

  /// Delete a vehicle. Deleting the default promotes another one.
  Future<void> deleteVehicle(String uid, String id) async {
    final ref = _vehicles(uid).doc(id);
    final snap = await ref.get();
    if (!snap.exists) return;
    final wasDefault = snap.data()?['isDefault'] == true;
    await ref.delete();
    if (!wasDefault) return;

    final rest = await _vehicles(uid).get();
    final next =
        _ordered(rest.docs.map((d) => Vehicle.fromMap(d.id, d.data())));
    if (next.isNotEmpty) await setDefault(uid, next.first.id);
  }

  /// Default first, then newest first. Docs whose server timestamp hasn't
  /// resolved yet (just created) float to the top of their group.
  static List<Vehicle> _ordered(Iterable<Vehicle> items) {
    final list = items.toList();
    list.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      final at = a.createdAt;
      final bt = b.createdAt;
      if (at == null && bt == null) return 0;
      if (at == null) return -1;
      if (bt == null) return 1;
      return bt.compareTo(at);
    });
    return list;
  }
}

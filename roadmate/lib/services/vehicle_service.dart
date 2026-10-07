import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vehicle.dart';

/// Firestore CRUD for a driver's saved vehicles
/// (`users/{uid}/vehicles` sub-collection).
class VehicleService {
  final FirebaseFirestore? _dbOverride;
  VehicleService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('vehicles');

  /// Live list: default vehicle first, then newest. Sorted client-side so no
  /// Firestore index is needed.
  Stream<List<Vehicle>> watchVehicles(String uid) {
    return _col(uid).snapshots().map((s) {
      final list = s.docs.map((d) => Vehicle.fromMap(d.id, d.data())).toList();
      list.sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        final at = a.createdAt;
        final bt = b.createdAt;
        if (at == null && bt == null) return 0;
        if (at == null) return -1; // just-created, timestamp not resolved yet
        if (bt == null) return 1;
        return bt.compareTo(at);
      });
      return list;
    });
  }

  Future<Vehicle?> getVehicle(String uid, String vehicleId) async {
    final doc = await _col(uid).doc(vehicleId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Vehicle.fromMap(doc.id, doc.data()!);
  }

  /// Adds [vehicle]; the first vehicle a user saves becomes the default.
  /// Returns the new doc id.
  Future<String> addVehicle(String uid, Vehicle vehicle) async {
    final isFirst = (await _col(uid).limit(1).get()).docs.isEmpty;
    final doc = await _col(uid).add({
      ...vehicle.copyWith(isDefault: vehicle.isDefault || isFirst).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (vehicle.isDefault && !isFirst) await setDefault(uid, doc.id);
    return doc.id;
  }

  /// Saves edits. `isDefault` is not touched here — use [setDefault].
  Future<void> updateVehicle(String uid, Vehicle vehicle) {
    final map = vehicle.toMap()..remove('isDefault');
    return _col(uid).doc(vehicle.id).update(map);
  }

  /// Makes [vehicleId] the only default vehicle.
  Future<void> setDefault(String uid, String vehicleId) async {
    final all = await _col(uid).get();
    final batch = _db.batch();
    for (final d in all.docs) {
      final shouldBe = d.id == vehicleId;
      if ((d.data()['isDefault'] ?? false) != shouldBe) {
        batch.update(d.reference, {'isDefault': shouldBe});
      }
    }
    await batch.commit();
  }

  /// Deletes a vehicle; if it was the default, the next one takes over.
  Future<void> deleteVehicle(String uid, String vehicleId) async {
    final doc = await _col(uid).doc(vehicleId).get();
    final wasDefault = (doc.data()?['isDefault'] ?? false) as bool;
    await _col(uid).doc(vehicleId).delete();
    if (!wasDefault) return;
    final rest = await _col(uid).limit(1).get();
    if (rest.docs.isNotEmpty) {
      await rest.docs.first.reference.update({'isDefault': true});
    }
  }
}

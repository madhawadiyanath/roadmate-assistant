import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/garage.dart';

/// Public garage directory (`garages` collection).
/// Sorted client-side (no composite indexes needed).
class GarageService {
  final FirebaseFirestore? _dbOverride;
  GarageService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _garages =>
      _db.collection('garages');

  /// Every open-first listing for the driver directory.
  Stream<List<GarageProfile>> watchGarages() {
    return _garages.limit(50).snapshots().map((s) {
      final list = s.docs.map(GarageProfile.fromDoc).toList();
      list.sort((a, b) {
        if (a.open != b.open) return a.open ? -1 : 1;
        if (b.rating != a.rating) return b.rating.compareTo(a.rating);
        return a.name.compareTo(b.name);
      });
      return list;
    });
  }

  Future<GarageProfile?> getMyGarage(String ownerUid) async {
    final doc = await _garages.doc(ownerUid).get();
    if (!doc.exists || doc.data() == null) return null;
    return GarageProfile.fromDoc(doc);
  }

  Future<void> saveMyGarage(GarageProfile garage) =>
      _garages.doc(garage.ownerUid).set(garage.toMap(), SetOptions(merge: true));
}

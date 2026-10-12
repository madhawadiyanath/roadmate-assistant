import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/garage_profile.dart';

/// Firestore CRUD for a garage/workshop profile (`users/{uid}/garageProfile/info`).
class GarageService {
  final FirebaseFirestore? _dbOverride;
  GarageService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _garageDoc(String uid) =>
      _db.collection('users').doc(uid).collection('garageProfile').doc('info');

  /// Live stream of garage profile for mechanic [uid].
  Stream<GarageProfile?> watchGarageProfile(String uid) {
    return _garageDoc(uid).snapshots().map((snap) =>
        snap.exists && snap.data() != null
            ? GarageProfile.fromMap(uid, snap.data()!)
            : null);
  }

  /// One-shot fetch of garage profile.
  Future<GarageProfile?> getGarageProfile(String uid) async {
    final doc = await _garageDoc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return GarageProfile.fromMap(uid, doc.data()!);
  }

  /// Save or update garage profile.
  Future<void> saveGarageProfile(String uid, GarageProfile profile) async {
    final map = profile.copyWith(ownerUid: uid).toMap();
    await _garageDoc(uid).set(map, SetOptions(merge: true));
  }

  /// Quick toggle for Garage Open/Closed status.
  Future<void> toggleOpenStatus(String uid, bool isOpen) async {
    await _garageDoc(uid).set(
      {'isOpen': isOpen, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}

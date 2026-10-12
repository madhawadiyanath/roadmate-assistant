import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mechanic_service.dart';

/// Firestore CRUD for a mechanic's offered services (`users/{uid}/services`).
///
/// Follows the same pattern as VehicleService and EmergencyContactService:
/// client-side sorted, injectable FirebaseFirestore for unit tests.
class MechanicServiceService {
  final FirebaseFirestore? _dbOverride;
  MechanicServiceService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _services(String uid) =>
      _db.collection('users').doc(uid).collection('services');

  /// Live stream of services offered by mechanic [uid].
  Stream<List<MechanicService>> watchServices(String uid) {
    return _services(uid).snapshots().map((s) => _ordered(
        s.docs.map((d) => MechanicService.fromMap(d.id, d.data()))));
  }

  /// One-shot read of a single service.
  Future<MechanicService?> getService(String uid, String serviceId) async {
    final doc = await _services(uid).doc(serviceId).get();
    if (!doc.exists || doc.data() == null) return null;
    return MechanicService.fromMap(doc.id, doc.data()!);
  }

  /// Add a new service. Returns the new document id.
  Future<String> addService(String uid, MechanicService service) async {
    final map = MechanicService(
      id: '',
      title: service.title.trim(),
      category: service.category,
      basePrice: service.basePrice,
      estimatedDurationMinutes: service.estimatedDurationMinutes,
      description: service.description.trim(),
      isAvailable: service.isAvailable,
    ).toMap();
    final doc = await _services(uid).add(map);
    return doc.id;
  }

  /// Update an existing service.
  Future<void> updateService(String uid, MechanicService service) {
    final map = service.toMap()..remove('createdAt');
    return _services(uid).doc(service.id).update(map);
  }

  /// Quick toggle for availability status of a service.
  Future<void> toggleAvailability(
      String uid, String serviceId, bool isAvailable) {
    return _services(uid).doc(serviceId).update({'isAvailable': isAvailable});
  }

  /// Permanently delete a service.
  Future<void> deleteService(String uid, String serviceId) {
    return _services(uid).doc(serviceId).delete();
  }

  /// Order: Available services first, then alphabetical by title.
  static List<MechanicService> _ordered(Iterable<MechanicService> items) {
    final list = items.toList();
    list.sort((a, b) {
      if (a.isAvailable != b.isAvailable) {
        return a.isAvailable ? -1 : 1;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return list;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_request.dart';

/// Firestore CRUD for driver assistance requests (`requests` collection).
class AssistanceService {
  final FirebaseFirestore? _dbOverride;
  AssistanceService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('requests');

  /// Create a new request for [driverUid]. Returns the new doc id.
  Future<String> createRequest({
    required String driverUid,
    required String driverName,
    required AssistanceType type,
  }) async {
    final doc = await _requests.add(ServiceRequest(
      id: '',
      driverUid: driverUid,
      driverName: driverName,
      type: type,
      status: RequestStatus.pending,
    ).toMap());
    return doc.id;
  }

  /// Live list of a driver's requests, newest first.
  Stream<List<ServiceRequest>> watchDriverRequests(String driverUid) {
    return _requests
        .where('driverUid', isEqualTo: driverUid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map(ServiceRequest.fromDoc).toList());
  }

  Future<void> cancelRequest(String requestId) =>
      _requests.doc(requestId).update({'status': RequestStatus.cancelled.name});
}

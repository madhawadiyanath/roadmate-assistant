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
    String address = '',
    double? latitude,
    double? longitude,
  }) async {
    final doc = await _requests.add(ServiceRequest(
      id: '',
      driverUid: driverUid,
      driverName: driverName,
      type: type,
      status: RequestStatus.pending,
      address: address,
      latitude: latitude,
      longitude: longitude,
    ).toMap());
    return doc.id;
  }

  /// Live list of a driver's requests, newest first.
  ///
  /// Sorted client-side on purpose: `where + orderBy` would need a
  /// Firestore composite index, without which the stream fails and the
  /// UI shows an empty list.
  Stream<List<ServiceRequest>> watchDriverRequests(String driverUid) {
    return _requests
        .where('driverUid', isEqualTo: driverUid)
        .limit(30)
        .snapshots()
        .map((s) => _newestFirst(s.docs.map(ServiceRequest.fromDoc)));
  }

  Future<void> cancelRequest(String requestId) =>
      _requests.doc(requestId).update({'status': RequestStatus.cancelled.name});

  /// Live view of one request — powers driver tracking.
  Stream<ServiceRequest?> watchRequest(String requestId) {
    return _requests.doc(requestId).snapshots().map(
        (d) => d.exists && d.data() != null ? ServiceRequest.fromDoc(d) : null);
  }

  // ---------------- Mechanic side ----------------

  /// Live list of unassigned requests — what mechanics see as "new jobs".
  Stream<List<ServiceRequest>> watchPendingRequests() {
    return _requests
        .where('status', isEqualTo: RequestStatus.pending.name)
        .limit(30)
        .snapshots()
        .map((s) => _newestFirst(s.docs.map(ServiceRequest.fromDoc)));
  }

  /// Live list of jobs assigned to one mechanic (accepted → completed).
  Stream<List<ServiceRequest>> watchMechanicJobs(String mechanicUid) {
    return _requests
        .where('mechanicUid', isEqualTo: mechanicUid)
        .limit(30)
        .snapshots()
        .map((s) => _newestFirst(s.docs.map(ServiceRequest.fromDoc)));
  }

  /// Newest first; docs whose server timestamp hasn't resolved yet
  /// (just-created) float to the top so they appear instantly.
  static List<ServiceRequest> _newestFirst(Iterable<ServiceRequest> items) {
    final list = items.toList();
    list.sort((a, b) {
      final at = a.createdAt;
      final bt = b.createdAt;
      if (at == null && bt == null) return 0;
      if (at == null) return -1;
      if (bt == null) return 1;
      return bt.compareTo(at);
    });
    return list;
  }

  /// Claim a pending request: assigns the mechanic and marks it accepted.
  Future<void> acceptRequest({
    required String requestId,
    required String mechanicUid,
    required String mechanicName,
  }) =>
      _requests.doc(requestId).update({
        'mechanicUid': mechanicUid,
        'mechanicName': mechanicName,
        'status': RequestStatus.accepted.name,
      });

  /// Advance a job: accepted → onTheWay → completed.
  Future<void> updateStatus(String requestId, RequestStatus status) =>
      _requests.doc(requestId).update({'status': status.name});
}

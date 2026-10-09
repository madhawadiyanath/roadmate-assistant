import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_request.dart';
import 'payment_service.dart';
import 'notification_service.dart';

/// Generates a stable reference code like #RM4821 at creation time.
String generateRefCode([Random? random]) {
  final r = random ?? Random();
  return '#RM${1000 + r.nextInt(9000)}';
}

/// Firestore CRUD for driver assistance requests (`requests` collection).
class AssistanceService {
  final FirebaseFirestore? _dbOverride;
  AssistanceService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('requests');

  /// Create a new request for [driverUid]. Returns the new doc id.
  /// Pass a pre-generated [refCode] when the caller must display it
  /// (e.g. the success receipt) — otherwise one is generated.
  Future<String> createRequest({
    required String driverUid,
    required String driverName,
    required AssistanceType type,
    String address = '',
    double? latitude,
    double? longitude,
    String paymentMethod = '',
    int rating = 0,
    String feedback = '',
    double totalFee = 0,
    String vehicle = '',
    String plate = '',
    String refCode = '',
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
      paymentMethod: paymentMethod,
      rating: rating,
      feedback: feedback,
      totalFee: totalFee,
      vehicle: vehicle,
      plate: plate,
      refCode: refCode.isEmpty ? generateRefCode() : refCode,
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

  /// The driver rates a finished request (1–5 stars, optional feedback
  /// and quick tags). Firestore rules allow this once, on their own
  /// completed request, and only these fields.
  Future<void> rateRequest({
    required String requestId,
    required int rating,
    String feedback = '',
    List<String> tags = const [],
  }) {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'must be between 1 and 5');
    }
    return _requests.doc(requestId).update({
      'rating': rating,
      'feedback': feedback.trim(),
      'tags': tags,
      'ratedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelRequest(String requestId) =>
      _requests.doc(requestId).update({'status': RequestStatus.cancelled.name});

  /// Edit the pickup address of a pending request.
  Future<void> updateAddress(String requestId, String address) async {
    final a = address.trim();
    if (a.isEmpty) return;
    await _requests.doc(requestId).update({'address': a});
  }

  /// Permanently delete own request: cancel first, remove the doc, then
  /// clean the chat thread. The thread-cleanup rule allows removing the
  /// whole thread once its parent doc is gone; anything left behind is
  /// invisible (orphans under a missing parent).
  Future<void> deleteRequest(String requestId) async {
    await cancelRequest(requestId);
    final msgs = await _requests.doc(requestId).collection('messages').get();
    await _requests.doc(requestId).delete();
    for (final m in msgs.docs) {
      try {
        await m.reference.delete();
      } catch (_) {
        // Best-effort cleanup.
      }
    }
  }

  /// Live list of EVERY request (admin oversight), newest first.
  Stream<List<ServiceRequest>> watchAllRequests() {
    return _requests
        .limit(50)
        .snapshots()
        .map((s) => _newestFirst(s.docs.map(ServiceRequest.fromDoc)));
  }

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
    String driverUid = '',
  }) async {
    final snap = await _requests.doc(requestId).get();
    final resolvedDriverUid = driverUid.isNotEmpty
        ? driverUid
        : (snap.data()?['driverUid'] as String? ?? '');

    await _requests.doc(requestId).update({
      'mechanicUid': mechanicUid,
      'mechanicName': mechanicName,
      'status': RequestStatus.accepted.name,
    });

    // Link the mechanic as payee on this request's transactions.
    await PaymentService(db: _db).assignPayee(
      requestId: requestId,
      mechanicUid: mechanicUid,
      mechanicName: mechanicName,
    );

    if (resolvedDriverUid.isNotEmpty) {
      await NotificationService(db: _db).createRequestAccepted(
        driverUid: resolvedDriverUid,
        mechanicName: mechanicName,
        senderUid: mechanicUid,
        requestId: requestId,
      );
    }
  }

  /// Advance a job: accepted → onTheWay → completed.
  Future<void> updateStatus(String requestId, RequestStatus status) =>
      _requests.doc(requestId).update({'status': status.name});
}

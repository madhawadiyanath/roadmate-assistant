import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/firebase_state.dart';
import '../firebase_options.dart';
import '../models/earnings_record.dart';

/// Service managing mechanic earnings in Firestore with mock seeding and offline fallback.
class EarningsService {
  final FirebaseFirestore? _dbOverride;

  EarningsService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  bool get isLiveDb =>
      _dbOverride != null ||
      (firebaseReady && !DefaultFirebaseOptions.isPlaceholder);

  CollectionReference<Map<String, dynamic>> get _earnings =>
      _db.collection('earnings');

  static final List<EarningsRecord> _inMemoryEarnings = List.of(mockEarnings);

  /// Get list of earnings records for mechanic (newest first).
  /// Automatically seeds initial [mockEarnings] if collection is empty.
  Future<List<EarningsRecord>> getEarnings({String mechanicUid = ''}) async {
    if (!isLiveDb) {
      return _filterAndSortInMemory(mechanicUid);
    }

    try {
      Query<Map<String, dynamic>> query = _earnings;
      if (mechanicUid.isNotEmpty) {
        query = query.where('mechanicUid', isEqualTo: mechanicUid);
      }
      final snap = await query.limit(50).get();
      if (snap.docs.isEmpty) {
        await _seedDefaultEarnings(mechanicUid);
        final seededSnap = await query.limit(50).get();
        final list = seededSnap.docs.map(EarningsRecord.fromDoc).toList();
        list.sort((a, b) => b.completedDate.compareTo(a.completedDate));
        return list;
      }

      final list = snap.docs.map(EarningsRecord.fromDoc).toList();
      list.sort((a, b) => b.completedDate.compareTo(a.completedDate));
      return list;
    } catch (e) {
      debugPrint('EarningsService: Error fetching earnings: $e');
      return _filterAndSortInMemory(mechanicUid);
    }
  }

  /// Live stream of earnings records for mechanic.
  Stream<List<EarningsRecord>> watchEarnings({String mechanicUid = ''}) {
    if (!isLiveDb) {
      return Stream.value(_filterAndSortInMemory(mechanicUid));
    }

    Query<Map<String, dynamic>> query = _earnings;
    if (mechanicUid.isNotEmpty) {
      query = query.where('mechanicUid', isEqualTo: mechanicUid);
    }

    return query.limit(50).snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return _filterAndSortInMemory(mechanicUid);
      }
      final list = snap.docs.map(EarningsRecord.fromDoc).toList();
      list.sort((a, b) => b.completedDate.compareTo(a.completedDate));
      return list;
    });
  }

  /// Record a new completed earning entry into Firestore.
  Future<void> recordEarning(EarningsRecord record) async {
    // Add to in-memory store
    _inMemoryEarnings.removeWhere((e) => e.transactionId == record.transactionId);
    _inMemoryEarnings.insert(0, record);
    mockEarnings.removeWhere((e) => e.transactionId == record.transactionId);
    mockEarnings.insert(0, record);

    if (!isLiveDb) return;

    try {
      final docId = record.transactionId.isNotEmpty
          ? record.transactionId
          : record.jobId.replaceAll('#', '').replaceAll(' ', '_');
      await _earnings.doc(docId).set(record.toMap());
    } catch (e) {
      debugPrint('EarningsService: Error saving earning: $e');
    }
  }

  /// Helper to calculate summary metrics from an earnings list.
  Map<String, dynamic> calculateMetrics(List<EarningsRecord> records) {
    double totalServiceCharge = 0;
    double totalPlatformFee = 0;
    double totalNet = 0;
    int completedCount = 0;

    for (final r in records) {
      totalServiceCharge += r.serviceCharge;
      totalPlatformFee += r.platformFee;
      totalNet += r.netEarnings;
      if (r.paymentStatus.toLowerCase() == 'completed') {
        completedCount++;
      }
    }

    final avgJob = completedCount > 0 ? (totalNet / completedCount) : 0.0;

    return {
      'totalServiceCharge': totalServiceCharge,
      'totalPlatformFee': totalPlatformFee,
      'totalNet': totalNet,
      'completedCount': completedCount,
      'avgJobPayout': avgJob,
    };
  }

  // --- Private Helpers ---

  Future<void> _seedDefaultEarnings(String mechanicUid) async {
    try {
      final batch = _db.batch();
      for (final e in mockEarnings) {
        final docRef = _earnings.doc(e.transactionId);
        final seeded = EarningsRecord(
          jobId: e.jobId,
          transactionId: e.transactionId,
          serviceType: e.serviceType,
          customerName: e.customerName,
          serviceCharge: e.serviceCharge,
          platformFee: e.platformFee,
          netEarnings: e.netEarnings,
          paymentStatus: e.paymentStatus,
          completedDate: e.completedDate,
          mechanicUid: mechanicUid,
        );
        batch.set(docRef, seeded.toMap());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('EarningsService: Error seeding default earnings: $e');
    }
  }

  List<EarningsRecord> _filterAndSortInMemory(String mechanicUid) {
    final list = List.of(mockEarnings);
    if (mechanicUid.isNotEmpty) {
      final filtered = list.where((e) => e.mechanicUid.isEmpty || e.mechanicUid == mechanicUid).toList();
      filtered.sort((a, b) => b.completedDate.compareTo(a.completedDate));
      return filtered;
    }
    list.sort((a, b) => b.completedDate.compareTo(a.completedDate));
    return list;
  }
}

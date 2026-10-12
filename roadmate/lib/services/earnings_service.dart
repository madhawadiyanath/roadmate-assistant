import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/firebase_state.dart';
import '../firebase_options.dart';
import '../models/earnings_record.dart';

/// Service managing mechanic earnings in Firestore with mock seeding,
/// real-time streaming, de-duplication, and CRUD operations.
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
  static final StreamController<List<EarningsRecord>> _earningsController =
      StreamController<List<EarningsRecord>>.broadcast();

  /// Public read-only access to in-memory store
  static List<EarningsRecord> get inMemoryEarnings =>
      List.unmodifiable(_inMemoryEarnings);

  /// Get list of earnings records for mechanic (newest first).
  /// Automatically seeds initial [mockEarnings] if collection is empty.
  Future<List<EarningsRecord>> getEarnings({String mechanicUid = ''}) async {
    final inMemoryMatches = _filterAndSortInMemory(mechanicUid);

    if (!isLiveDb) {
      return inMemoryMatches;
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
        final Map<String, EarningsRecord> merged = {};
        for (final e in inMemoryMatches) {
          merged[e.transactionId] = e;
        }
        for (final e in list) {
          merged[e.transactionId] = e;
        }
        final result = merged.values.toList();
        result.sort((a, b) => b.completedDate.compareTo(a.completedDate));
        return result;
      }

      final remoteList = snap.docs.map(EarningsRecord.fromDoc).toList();
      final Map<String, EarningsRecord> merged = {};
      for (final e in inMemoryMatches) {
        merged[e.transactionId] = e;
      }
      for (final e in remoteList) {
        merged[e.transactionId] = e;
      }

      final list = merged.values.toList();
      list.sort((a, b) => b.completedDate.compareTo(a.completedDate));
      return list;
    } catch (e) {
      debugPrint('EarningsService: Error fetching earnings: $e');
      return inMemoryMatches;
    }
  }

  /// Live stream of earnings records for mechanic.
  Stream<List<EarningsRecord>> watchEarnings({String mechanicUid = ''}) {
    if (!isLiveDb) {
      final initial = _filterAndSortInMemory(mechanicUid);
      return Stream<List<EarningsRecord>>.multi((controller) {
        controller.add(List.of(initial));
        final sub = _earningsController.stream.listen((allInMemory) {
          final filtered = _filterRecords(allInMemory, mechanicUid);
          controller.add(filtered);
        });
        controller.onCancel = () => sub.cancel();
      });
    }

    try {
      Query<Map<String, dynamic>> query = _earnings;
      if (mechanicUid.isNotEmpty) {
        query = query.where('mechanicUid', isEqualTo: mechanicUid);
      }

      return query.limit(50).snapshots().map((snap) {
        final remoteList = snap.docs.map(EarningsRecord.fromDoc).toList();
        final inMemoryMatches = _filterAndSortInMemory(mechanicUid);

        final Map<String, EarningsRecord> merged = {};
        for (final e in inMemoryMatches) {
          merged[e.transactionId] = e;
        }
        for (final e in remoteList) {
          merged[e.transactionId] = e;
        }

        final list = merged.values.toList();
        list.sort((a, b) => b.completedDate.compareTo(a.completedDate));
        return list;
      }).handleError((_) => _filterAndSortInMemory(mechanicUid));
    } catch (_) {
      final initial = _filterAndSortInMemory(mechanicUid);
      return Stream<List<EarningsRecord>>.multi((controller) {
        controller.add(List.of(initial));
        final sub = _earningsController.stream.listen((allInMemory) {
          final filtered = _filterRecords(allInMemory, mechanicUid);
          controller.add(filtered);
        });
        controller.onCancel = () => sub.cancel();
      });
    }
  }

  /// Record a new completed earning entry into Firestore and in-memory store.
  /// Prevents adding duplicate transactions for the same payment/job.
  Future<void> recordEarning(EarningsRecord record) async {
    // 1. De-duplication check: if a record with this transactionId already exists
    final existingIdx = _inMemoryEarnings.indexWhere((e) =>
        e.transactionId.isNotEmpty && e.transactionId == record.transactionId);

    if (existingIdx != -1) {
      // Update existing record rather than adding a duplicate
      _inMemoryEarnings[existingIdx] = record;
    } else {
      _inMemoryEarnings.insert(0, record);
    }

    final mockIdx = mockEarnings.indexWhere((e) =>
        e.transactionId.isNotEmpty && e.transactionId == record.transactionId);
    if (mockIdx != -1) {
      mockEarnings[mockIdx] = record;
    } else {
      mockEarnings.insert(0, record);
    }

    _earningsController.add(List.of(_inMemoryEarnings));

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

  /// Update an existing earning record (e.g. updating notes, tags, or status).
  Future<void> updateEarning(EarningsRecord updated) async {
    final idx = _inMemoryEarnings
        .indexWhere((e) => e.transactionId == updated.transactionId);
    if (idx != -1) {
      _inMemoryEarnings[idx] = updated;
    }

    final mIdx =
        mockEarnings.indexWhere((e) => e.transactionId == updated.transactionId);
    if (mIdx != -1) {
      mockEarnings[mIdx] = updated;
    }

    _earningsController.add(List.of(_inMemoryEarnings));

    if (!isLiveDb) return;

    try {
      final docId = updated.transactionId.isNotEmpty
          ? updated.transactionId
          : updated.jobId.replaceAll('#', '').replaceAll(' ', '_');
      await _earnings.doc(docId).set(updated.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('EarningsService: Error updating earning: $e');
    }
  }

  /// Traceable financial reversal: marks the record as reversed without destroying audit trail.
  Future<void> reverseEarning({
    required String transactionId,
    required String reason,
  }) async {
    EarningsRecord? target;
    for (final e in _inMemoryEarnings) {
      if (e.transactionId == transactionId) {
        target = e;
        break;
      }
    }
    if (target == null) {
      for (final e in mockEarnings) {
        if (e.transactionId == transactionId) {
          target = e;
          break;
        }
      }
    }
    if (target == null) return;

    final reversed = target.copyWith(
      isReversed: true,
      paymentStatus: 'Reversed',
      adjustmentReason: reason,
    );
    await updateEarning(reversed);
  }

  /// Deletes a draft or uncompleted/non-financial record.
  /// Refuses deletion of verified completed records to preserve financial integrity.
  Future<bool> deleteDraftEarning(String transactionId) async {
    final record = _inMemoryEarnings.firstWhere(
      (e) => e.transactionId == transactionId,
      orElse: () => mockEarnings.firstWhere(
        (e) => e.transactionId == transactionId,
        orElse: () => EarningsRecord(
          jobId: '',
          transactionId: '',
          serviceType: '',
          serviceCharge: 0,
          netEarnings: 0,
          completedDate: DateTime(2000),
        ),
      ),
    );

    if (record.transactionId.isEmpty ||
        (record.paymentStatus.toLowerCase() == 'completed' && !record.isReversed)) {
      // Protected financial record cannot be hard-deleted
      return false;
    }

    _inMemoryEarnings.removeWhere((e) => e.transactionId == transactionId);
    mockEarnings.removeWhere((e) => e.transactionId == transactionId);
    _earningsController.add(List.of(_inMemoryEarnings));

    if (isLiveDb) {
      try {
        await _earnings.doc(transactionId).delete();
      } catch (_) {}
    }
    return true;
  }

  /// Record a traceable adjustment or tip for a mechanic.
  Future<EarningsRecord> recordAdjustment({
    required String mechanicUid,
    required String serviceType,
    required double amount,
    String? reason,
    String? jobId,
    String? notes,
  }) async {
    final adjId = 'ADJ-${DateTime.now().millisecondsSinceEpoch % 10000000}';
    final effectiveReason = reason ?? notes ?? 'Authorized adjustment';
    final record = EarningsRecord(
      jobId: jobId ?? 'ADJ #$adjId',
      transactionId: adjId,
      serviceType: serviceType,
      customerName: 'Customer / Manual Adjustment',
      serviceCharge: amount,
      platformFee: 0,
      netEarnings: amount,
      paymentStatus: 'Completed',
      completedDate: DateTime.now(),
      mechanicUid: mechanicUid,
      notes: notes ?? effectiveReason,
      adjustmentReason: effectiveReason,
    );
    await recordEarning(record);
    return record;
  }

  /// Helper to calculate summary metrics from an earnings list.
  Map<String, dynamic> calculateMetrics(List<EarningsRecord> records) {
    double totalServiceCharge = 0;
    double totalPlatformFee = 0;
    double totalNet = 0;
    int completedCount = 0;
    int pendingCount = 0;
    double pendingAmount = 0;

    for (final r in records) {
      if (r.isCompleted) {
        totalServiceCharge += r.serviceCharge;
        totalPlatformFee += r.platformFee;
        totalNet += r.netEarnings;
        completedCount++;
      } else if (r.paymentStatus.toLowerCase() == 'pending') {
        pendingCount++;
        pendingAmount += r.netEarnings;
      }
    }

    final avgJob = completedCount > 0 ? (totalNet / completedCount) : 0.0;

    return {
      'totalServiceCharge': totalServiceCharge,
      'totalPlatformFee': totalPlatformFee,
      'totalNet': totalNet,
      'completedCount': completedCount,
      'pendingCount': pendingCount,
      'pendingAmount': pendingAmount,
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
          notes: e.notes,
          isReversed: e.isReversed,
          adjustmentReason: e.adjustmentReason,
        );
        batch.set(docRef, seeded.toMap());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('EarningsService: Error seeding default earnings: $e');
    }
  }

  List<EarningsRecord> _filterAndSortInMemory(String mechanicUid) {
    return _filterRecords(_inMemoryEarnings, mechanicUid);
  }

  List<EarningsRecord> _filterRecords(
      List<EarningsRecord> source, String mechanicUid) {
    final list = List.of(source);
    if (mechanicUid.isNotEmpty) {
      final filtered = list
          .where((e) => e.mechanicUid.isEmpty || e.mechanicUid == mechanicUid)
          .toList();
      filtered.sort((a, b) => b.completedDate.compareTo(a.completedDate));
      return filtered;
    }
    list.sort((a, b) => b.completedDate.compareTo(a.completedDate));
    return list;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/firebase_state.dart';
import '../firebase_options.dart';
import '../models/payment_method.dart';
import '../models/payment_transaction.dart';

/// Service managing payment methods and transaction history in Firestore
/// with graceful fallback and mock data seeding.
class PaymentService {
  final FirebaseFirestore? _dbOverride;

  PaymentService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  bool get isLiveDb =>
      _dbOverride != null ||
      (firebaseReady && !DefaultFirebaseOptions.isPlaceholder);

  CollectionReference<Map<String, dynamic>> _userMethods(String uid) =>
      _db.collection('users').doc(uid).collection('payment_methods');

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _db.collection('transactions');

  /// Fallback in-memory store for mock or offline sessions
  static final List<PaymentTransaction> _inMemoryTransactions =
      List.of(mockTransactions);

  /// Get current payment methods for a user.
  /// If live Firestore collection is empty, automatically seeds from [mockPaymentMethods].
  Future<List<PaymentMethod>> getPaymentMethods(String uid) async {
    final effectiveUid = uid.isEmpty ? 'default_user' : uid;

    if (!isLiveDb) {
      return List.of(mockPaymentMethods);
    }

    try {
      final snap = await _userMethods(effectiveUid).get();
      if (snap.docs.isEmpty) {
        // Seed initial default methods into Firestore
        await _seedDefaultMethods(effectiveUid);
        final seededSnap = await _userMethods(effectiveUid).get();
        final list = seededSnap.docs.map(PaymentMethod.fromDoc).toList();
        _sortMethods(list);
        return list;
      }

      final list = snap.docs.map(PaymentMethod.fromDoc).toList();
      _sortMethods(list);
      return list;
    } catch (e) {
      debugPrint('PaymentService: Error fetching methods from Firestore: $e');
      return List.of(mockPaymentMethods);
    }
  }

  /// Live stream of payment methods for a user.
  Stream<List<PaymentMethod>> watchPaymentMethods(String uid) {
    final effectiveUid = uid.isEmpty ? 'default_user' : uid;

    if (!isLiveDb) {
      return Stream.value(List.of(mockPaymentMethods));
    }

    return _userMethods(effectiveUid).snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        // Fallback or unseeded
        return List.of(mockPaymentMethods);
      }
      final list = snap.docs.map(PaymentMethod.fromDoc).toList();
      _sortMethods(list);
      return list;
    });
  }

  /// Add a new payment method.
  Future<PaymentMethod> addPaymentMethod({
    required String uid,
    required PaymentMethod method,
  }) async {
    final effectiveUid = uid.isEmpty ? 'default_user' : uid;

    // If marked default, unset default on existing methods
    if (method.isDefault) {
      await _clearDefault(effectiveUid);
    }

    if (!isLiveDb) {
      mockPaymentMethods.removeWhere((m) => m.id == method.id);
      mockPaymentMethods.insert(0, method);
      return method;
    }

    try {
      final docRef = _userMethods(effectiveUid).doc(method.id.isNotEmpty ? method.id : null);
      final generatedId = docRef.id;
      final toSave = method.copyWith(id: generatedId);
      await docRef.set(toSave.toMap());

      // Update in-memory copy
      mockPaymentMethods.removeWhere((m) => m.id == generatedId);
      mockPaymentMethods.insert(0, toSave);

      return toSave;
    } catch (e) {
      debugPrint('PaymentService: Error adding method: $e');
      // In-memory fallback
      mockPaymentMethods.insert(0, method);
      return method;
    }
  }

  /// Update an existing payment method (e.g. from EditCardScreen).
  Future<void> updatePaymentMethod({
    required String uid,
    required PaymentMethod method,
  }) async {
    final effectiveUid = uid.isEmpty ? 'default_user' : uid;

    if (method.isDefault) {
      await _clearDefault(effectiveUid, excludeId: method.id);
    }

    // Update in-memory
    final idx = mockPaymentMethods.indexWhere((m) => m.id == method.id);
    if (idx != -1) {
      mockPaymentMethods[idx] = method;
    }

    if (!isLiveDb) return;

    try {
      await _userMethods(effectiveUid).doc(method.id).set(method.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('PaymentService: Error updating method: $e');
    }
  }

  /// Delete a saved payment method.
  Future<void> deletePaymentMethod({
    required String uid,
    required String methodId,
  }) async {
    final effectiveUid = uid.isEmpty ? 'default_user' : uid;

    // Remove from in-memory
    mockPaymentMethods.removeWhere((m) => m.id == methodId);

    if (!isLiveDb) return;

    try {
      await _userMethods(effectiveUid).doc(methodId).delete();
    } catch (e) {
      debugPrint('PaymentService: Error deleting method: $e');
    }
  }

  /// Set a payment method as default and ensure all others are not default.
  Future<void> setDefaultPaymentMethod({
    required String uid,
    required String methodId,
  }) async {
    final effectiveUid = uid.isEmpty ? 'default_user' : uid;

    // Update in-memory
    for (int i = 0; i < mockPaymentMethods.length; i++) {
      final m = mockPaymentMethods[i];
      if (m.type == PaymentMethodType.card) {
        mockPaymentMethods[i] = m.copyWith(isDefault: m.id == methodId);
      }
    }

    if (!isLiveDb) return;

    try {
      final snap = await _userMethods(effectiveUid).get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        final isMatch = doc.id == methodId;
        batch.update(doc.reference, {'isDefault': isMatch});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('PaymentService: Error setting default method: $e');
    }
  }

  /// Record a completed payment transaction into Firestore.
  Future<void> recordTransaction(PaymentTransaction transaction) async {
    // Add to in-memory list
    _inMemoryTransactions.removeWhere((t) => t.transactionId == transaction.transactionId);
    _inMemoryTransactions.insert(0, transaction);
    mockTransactions.removeWhere((t) => t.transactionId == transaction.transactionId);
    mockTransactions.insert(0, transaction);

    if (!isLiveDb) return;

    try {
      await _transactions.doc(transaction.transactionId).set(transaction.toMap());
    } catch (e) {
      debugPrint('PaymentService: Error recording transaction: $e');
    }
  }

  /// Get list of transactions (newest first).
  Future<List<PaymentTransaction>> getTransactions({String driverUid = ''}) async {
    if (!isLiveDb) {
      return List.of(_inMemoryTransactions);
    }

    try {
      Query<Map<String, dynamic>> query = _transactions;
      if (driverUid.isNotEmpty) {
        query = query.where('driverUid', isEqualTo: driverUid);
      }
      final snap = await query.limit(50).get();
      if (snap.docs.isEmpty) {
        return List.of(_inMemoryTransactions);
      }
      final list = snap.docs.map(PaymentTransaction.fromDoc).toList();
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return list;
    } catch (e) {
      debugPrint('PaymentService: Error getting transactions: $e');
      return List.of(_inMemoryTransactions);
    }
  }

  /// Stream transactions live.
  Stream<List<PaymentTransaction>> watchTransactions({String driverUid = ''}) {
    if (!isLiveDb) {
      return Stream.value(List.of(_inMemoryTransactions));
    }

    Query<Map<String, dynamic>> query = _transactions;
    if (driverUid.isNotEmpty) {
      query = query.where('driverUid', isEqualTo: driverUid);
    }
    return query.limit(50).snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return List.of(_inMemoryTransactions);
      }
      final list = snap.docs.map(PaymentTransaction.fromDoc).toList();
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return list;
    });
  }

  // --- Private Helpers ---

  Future<void> _seedDefaultMethods(String uid) async {
    try {
      final batch = _db.batch();
      for (final m in mockPaymentMethods) {
        final docRef = _userMethods(uid).doc(m.id);
        batch.set(docRef, m.toMap());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('PaymentService: Error seeding methods: $e');
    }
  }

  Future<void> _clearDefault(String uid, {String? excludeId}) async {
    // In-memory
    for (int i = 0; i < mockPaymentMethods.length; i++) {
      if (mockPaymentMethods[i].id != excludeId) {
        mockPaymentMethods[i] = mockPaymentMethods[i].copyWith(isDefault: false);
      }
    }

    if (!isLiveDb) return;

    try {
      final snap = await _userMethods(uid).where('isDefault', isEqualTo: true).get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        if (doc.id != excludeId) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('PaymentService: Error clearing default: $e');
    }
  }

  void _sortMethods(List<PaymentMethod> list) {
    list.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return a.id.compareTo(b.id);
    });
  }
}

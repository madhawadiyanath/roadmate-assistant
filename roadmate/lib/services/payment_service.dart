import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/firebase_state.dart';
import '../firebase_options.dart';
import '../models/payment_method.dart';
import '../models/payment_transaction.dart';
import '../models/payments.dart';

/// Unified service managing payment methods, transactions, and earnings
/// in Firestore with in-memory fallback for offline/mock sessions.
class PaymentService {
  final FirebaseFirestore? _dbOverride;

  PaymentService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  bool get isLiveDb =>
      _dbOverride != null ||
      (firebaseReady && !DefaultFirebaseOptions.isPlaceholder);

  CollectionReference<Map<String, dynamic>> _userMethods(String uid) =>
      _db.collection('users').doc(uid).collection('payment_methods');

  CollectionReference<Map<String, dynamic>> _legacyMethods(String uid) =>
      _db.collection('users').doc(uid).collection('paymentMethods');

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _db.collection('transactions');

  CollectionReference<Map<String, dynamic>> get _txns =>
      _db.collection('transactions');

  /// Fallback in-memory store for mock or offline sessions
  static final List<PaymentTransaction> _inMemoryTransactions =
      List.of(mockTransactions);

  // ===================== MODERN PAYMENT METHODS =====================

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

      mockPaymentMethods.removeWhere((m) => m.id == generatedId);
      mockPaymentMethods.insert(0, toSave);

      return toSave;
    } catch (e) {
      debugPrint('PaymentService: Error adding method: $e');
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

  // ===================== MODERN TRANSACTIONS =====================

  /// Record a completed payment transaction into Firestore.
  Future<void> recordTransaction(PaymentTransaction transaction) async {
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

  // ===================== BACKWARD COMPATIBILITY & SHARED LOGIC =====================

  Stream<List<SavedMethod>> watchMethods(String uid) {
    return _legacyMethods(uid).snapshots().map((s) {
      final list = s.docs.map(SavedMethod.fromDoc).toList();
      list.sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return a.label.compareTo(b.label);
      });
      return list;
    });
  }

  Future<String> addCard({
    required String uid,
    required String cardNumber,
    required String expiry,
    bool makeDefault = false,
  }) async {
    final existing = await _legacyMethods(uid).get();
    final first = existing.docs.isEmpty;
    final doc = await _legacyMethods(uid).add(SavedMethod.card(
      id: '',
      cardNumber: cardNumber,
      expiry: expiry,
      isDefault: makeDefault || first,
    ).toMap());
    if (makeDefault || first) {
      await setDefault(uid: uid, methodId: doc.id);
    }

    // Also mirror to modern payment_methods
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.length <= 4 ? digits : digits.substring(digits.length - 4);
    final parts = expiry.split('/');
    final month = parts.isNotEmpty ? parts[0].trim() : '12';
    final year = parts.length > 1 ? parts[1].trim() : '30';
    await addPaymentMethod(
      uid: uid,
      method: PaymentMethod(
        id: doc.id,
        type: PaymentMethodType.card,
        brand: cardNumber.startsWith('4') ? 'Visa' : 'Mastercard',
        last4: last4,
        expiryMonth: month,
        expiryYear: year,
        isDefault: makeDefault || first,
      ),
    );

    return doc.id;
  }

  Future<void> setDefault({
    required String uid,
    required String methodId,
  }) async {
    final all = await _legacyMethods(uid).get();
    final batch = _db.batch();
    for (final d in all.docs) {
      batch.update(d.reference, {'isDefault': d.id == methodId});
    }
    await batch.commit();
    await setDefaultPaymentMethod(uid: uid, methodId: methodId);
  }

  Future<void> deleteMethod({
    required String uid,
    required String methodId,
  }) async {
    await _legacyMethods(uid).doc(methodId).delete();
    await deletePaymentMethod(uid: uid, methodId: methodId);
  }

  /// Records payment for a request. Returns the transaction id.
  Future<String> createTransaction({
    required String requestId,
    required String refCode,
    required String type,
    required String payerUid,
    required String payerName,
    required double amount,
    required String method,
    required List<FeeLine> items,
    bool paidAtOnce = true,
  }) async {
    final txn = TxnRecord(
      id: '',
      requestId: requestId,
      refCode: refCode,
      type: type,
      payerUid: payerUid,
      payerName: payerName,
      amount: amount,
      method: method,
      status: paidAtOnce ? 'paid' : 'pending',
      items: items,
      createdAt: DateTime.now(),
    );
    final doc = await _txns.add(txn.toMap());

    // Also mirror in-memory PaymentTransaction
    final pt = txn.toPaymentTransaction().copyWith(transactionId: doc.id);
    _inMemoryTransactions.removeWhere((t) => t.transactionId == doc.id);
    _inMemoryTransactions.insert(0, pt);
    mockTransactions.removeWhere((t) => t.transactionId == doc.id);
    mockTransactions.insert(0, pt);

    return doc.id;
  }

  /// Link the accepting mechanic as payee.
  Future<void> assignPayee({
    required String requestId,
    required String mechanicUid,
    required String mechanicName,
  }) async {
    final q = await _txns.where('requestId', isEqualTo: requestId).get();
    final batch = _db.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {
        'payeeUid': mechanicUid,
        'payeeName': mechanicName,
        'serviceProvider': mechanicName,
      });
    }
    await batch.commit();
  }

  /// Cash collected on completion → mark this request's txns paid.
  Future<void> collectCash(String requestId) async {
    final q = await _txns
        .where('requestId', isEqualTo: requestId)
        .where('status', isEqualTo: 'pending')
        .get();
    final batch = _db.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {'status': 'paid'});
    }
    await batch.commit();
  }

  Stream<List<TxnRecord>> _sorted(Query<Map<String, dynamic>> query) {
    return query.snapshots().map((s) {
      final list = s.docs.map(TxnRecord.fromDoc).toList();
      list.sort((a, b) {
        final at = a.createdAt;
        final bt = b.createdAt;
        if (at == null && bt == null) return 0;
        if (at == null) return -1;
        if (bt == null) return 1;
        return bt.compareTo(at);
      });
      return list;
    });
  }

  /// Driver side: everything this user paid.
  Stream<List<TxnRecord>> watchPayerTransactions(String uid) =>
      _sorted(_txns.where('payerUid', isEqualTo: uid).limit(50));

  /// Mechanic side: income — everything assigned to them.
  Stream<List<TxnRecord>> watchPayeeTransactions(String uid) =>
      _sorted(_txns.where('payeeUid', isEqualTo: uid).limit(50));

  /// Admin side: everything.
  Stream<List<TxnRecord>> watchAllTransactions() =>
      _sorted(_txns.limit(100));

  Future<TxnRecord?> getTransaction(String id) async {
    final doc = await _txns.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return TxnRecord.fromDoc(doc);
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

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payments.dart';

/// Payment methods + transactions.
///
/// - Methods: `users/{uid}/paymentMethods` (owner only).
/// - Transactions: top-level `transactions` (payer / payee / admin).
/// Sorted client-side (no composite indexes needed).
class PaymentService {
  final FirebaseFirestore? _dbOverride;
  PaymentService({FirebaseFirestore? db}) : _dbOverride = db;

  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _methods(String uid) =>
      _db.collection('users').doc(uid).collection('paymentMethods');

  CollectionReference<Map<String, dynamic>> get _txns =>
      _db.collection('transactions');

  // ---------------- Methods ----------------

  Stream<List<SavedMethod>> watchMethods(String uid) {
    return _methods(uid).snapshots().map((s) {
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
    final existing = await _methods(uid).get();
    final first = existing.docs.isEmpty;
    final doc = await _methods(uid).add(SavedMethod.card(
      id: '',
      cardNumber: cardNumber,
      expiry: expiry,
      isDefault: makeDefault || first,
    ).toMap());
    if (makeDefault || first) {
      await setDefault(uid: uid, methodId: doc.id);
    }
    return doc.id;
  }

  Future<void> setDefault({
    required String uid,
    required String methodId,
  }) async {
    final all = await _methods(uid).get();
    final batch = _db.batch();
    for (final d in all.docs) {
      batch.update(d.reference, {'isDefault': d.id == methodId});
    }
    await batch.commit();
  }

  Future<void> deleteMethod({
    required String uid,
    required String methodId,
  }) =>
      _methods(uid).doc(methodId).delete();

  // ---------------- Transactions ----------------

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
    final doc = await _txns.add(TxnRecord(
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
    ).toMap());
    return doc.id;
  }

  /// Link the accepting mechanic as payee.
  Future<void> assignPayee({
    required String requestId,
    required String mechanicUid,
    required String mechanicName,
  }) async {
    final q =
        await _txns.where('requestId', isEqualTo: requestId).get();
    final batch = _db.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {
        'payeeUid': mechanicUid,
        'payeeName': mechanicName,
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

  Stream<List<TxnRecord>> _sorted(
      Query<Map<String, dynamic>> query) {
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
}

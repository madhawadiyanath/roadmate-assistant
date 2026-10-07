import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/payments.dart';
import 'package:roadmate/services/payment_service.dart';

/// Methods CRUD + full money flow: pay → assign payee → collect cash.
void main() {
  test('card methods: add, default, delete', () async {
    final db = FakeFirebaseFirestore();
    final pay = PaymentService(db: db);

    final id1 = await pay.addCard(
      uid: 'u1',
      cardNumber: '4242424242424242',
      expiry: '08/27',
    );
    final id2 = await pay.addCard(
      uid: 'u1',
      cardNumber: '5555555555554444',
      expiry: '01/28',
    );

    var methods = await pay.watchMethods('u1').first;
    expect(methods, hasLength(2));
    // First card added becomes default; only last4 stored.
    expect(methods.firstWhere((m) => m.id == id1).isDefault, isTrue);
    expect(methods.firstWhere((m) => m.id == id1).label, 'Card •• 4242');

    await pay.setDefault(uid: 'u1', methodId: id2);
    methods = await pay.watchMethods('u1').first;
    expect(methods.firstWhere((m) => m.id == id2).isDefault, isTrue);
    expect(methods.firstWhere((m) => m.id == id1).isDefault, isFalse);

    await pay.deleteMethod(uid: 'u1', methodId: id1);
    methods = await pay.watchMethods('u1').first;
    expect(methods, hasLength(1));
  });

  test('card txn paid at once; cash pending until collected', () async {
    final db = FakeFirebaseFirestore();
    final pay = PaymentService(db: db);

    final cardTxn = await pay.createTransaction(
      requestId: 'req-card',
      refCode: '#RM1001',
      type: 'Flat Tyre',
      payerUid: 'driver1',
      payerName: 'Kasun',
      amount: 3500,
      method: 'Card •• 4242',
      items: const [FeeLine('Dispatch', 2800), FeeLine('Labour', 700)],
      paidAtOnce: true,
    );
    final cashTxn = await pay.createTransaction(
      requestId: 'req-cash',
      refCode: '#RM1002',
      type: 'Towing Service',
      payerUid: 'driver1',
      payerName: 'Kasun',
      amount: 8500,
      method: 'Cash on Site',
      items: const [FeeLine('Towing', 8500)],
      paidAtOnce: false,
    );

    var got = await pay.getTransaction(cardTxn);
    expect(got?.status, 'paid');
    got = await pay.getTransaction(cashTxn);
    expect(got?.status, 'pending');

    // Mechanic accepts → becomes payee on both.
    await pay.assignPayee(
      requestId: 'req-cash',
      mechanicUid: 'mech1',
      mechanicName: 'Nimal',
    );
    var jobs = await pay.watchPayeeTransactions('mech1').first;
    expect(jobs.map((t) => t.refCode), contains('#RM1002'));

    // Cash collected on completion → paid.
    await pay.collectCash('req-cash');
    got = await pay.getTransaction(cashTxn);
    expect(got?.status, 'paid');

    // Driver history shows both, newest first, items intact.
    final history = await pay.watchPayerTransactions('driver1').first;
    expect(history, hasLength(2));
    expect(history.map((t) => t.refCode), ['#RM1002', '#RM1001']);
    expect(
      history.firstWhere((t) => t.refCode == '#RM1001').items,
      hasLength(2),
    );
  });
}

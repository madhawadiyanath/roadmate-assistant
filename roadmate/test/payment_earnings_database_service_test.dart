import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/earnings_record.dart';
import 'package:roadmate/models/payment_method.dart';
import 'package:roadmate/models/payment_transaction.dart';
import 'package:roadmate/services/earnings_service.dart';
import 'package:roadmate/services/payment_service.dart';

void main() {
  group('PaymentService Firestore Database Integration Tests', () {
    late FakeFirebaseFirestore fakeDb;
    late PaymentService paymentService;
    const testUid = 'driver_test_123';

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
      paymentService = PaymentService(db: fakeDb);
    });

    test('Initial fetch auto-seeds default payment methods into Firestore',
        () async {
      final methods = await paymentService.getPaymentMethods(testUid);
      expect(methods, isNotEmpty);
      expect(methods.any((m) => m.brand == 'Mastercard'), isTrue);
      expect(methods.any((m) => m.brand == 'Visa'), isTrue);

      // Verify directly in Fake Firestore collection
      final snap = await fakeDb
          .collection('users')
          .doc(testUid)
          .collection('payment_methods')
          .get();
      expect(snap.docs.length, equals(methods.length));
    });

    test('Add new card persists to Firestore', () async {
      await paymentService.getPaymentMethods(testUid); // Seed

      const newCard = PaymentMethod(
        id: 'card_custom_99',
        type: PaymentMethodType.card,
        brand: 'Visa',
        last4: '5555',
        expiryMonth: '11',
        expiryYear: '30',
        holderName: 'Test Driver',
        isDefault: false,
      );

      final added = await paymentService.addPaymentMethod(
        uid: testUid,
        method: newCard,
      );
      expect(added.id, isNotEmpty);

      final fetched = await paymentService.getPaymentMethods(testUid);
      expect(fetched.any((m) => m.last4 == '5555'), isTrue);

      final doc = await fakeDb
          .collection('users')
          .doc(testUid)
          .collection('payment_methods')
          .doc('card_custom_99')
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['last4'], equals('5555'));
    });

    test('Set Default Card marks only one card as Default in Firestore',
        () async {
      await paymentService.getPaymentMethods(testUid); // Seed

      await paymentService.setDefaultPaymentMethod(
        uid: testUid,
        methodId: 'card_2',
      );

      final fetched = await paymentService.getPaymentMethods(testUid);
      final defaultCards = fetched.where((m) => m.isDefault).toList();
      expect(defaultCards.length, equals(1));
      expect(defaultCards.first.id, equals('card_2'));
    });

    test('Update Card details persists to Firestore', () async {
      await paymentService.getPaymentMethods(testUid); // Seed

      const updated = PaymentMethod(
        id: 'card_1',
        type: PaymentMethodType.card,
        brand: 'Mastercard',
        last4: '4242',
        expiryMonth: '05',
        expiryYear: '31',
        holderName: 'Updated Name',
        isDefault: true,
      );

      await paymentService.updatePaymentMethod(uid: testUid, method: updated);

      final doc = await fakeDb
          .collection('users')
          .doc(testUid)
          .collection('payment_methods')
          .doc('card_1')
          .get();
      expect(doc.data()!['holderName'], equals('Updated Name'));
      expect(doc.data()!['expiryMonth'], equals('05'));
      expect(doc.data()!['expiryYear'], equals('31'));
    });

    test('Delete card removes it permanently from Firestore', () async {
      await paymentService.getPaymentMethods(testUid); // Seed

      await paymentService.deletePaymentMethod(
        uid: testUid,
        methodId: 'card_3',
      );

      final fetched = await paymentService.getPaymentMethods(testUid);
      expect(fetched.any((m) => m.id == 'card_3'), isFalse);

      final doc = await fakeDb
          .collection('users')
          .doc(testUid)
          .collection('payment_methods')
          .doc('card_3')
          .get();
      expect(doc.exists, isFalse);
    });

    test('Record PaymentTransaction saves to Firestore transactions collection',
        () async {
      final tx = PaymentTransaction(
        transactionId: 'TXN-TEST-100',
        jobId: '#RM-5555',
        serviceType: 'Towing Service',
        serviceProvider: 'Nimal Bandara',
        serviceCharge: 3500,
        additionalCharges: 500,
        totalAmount: 4000,
        status: TransactionStatus.completed,
        driverUid: testUid,
      );

      await paymentService.recordTransaction(tx);

      final list = await paymentService.getTransactions(driverUid: testUid);
      expect(list.any((t) => t.transactionId == 'TXN-TEST-100'), isTrue);

      final doc = await fakeDb.collection('transactions').doc('TXN-TEST-100').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['totalAmount'], equals(4000.0));
    });
  });

  group('EarningsService Firestore Database Integration Tests', () {
    late FakeFirebaseFirestore fakeDb;
    late EarningsService earningsService;
    const testMechUid = 'mechanic_test_456';

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
      earningsService = EarningsService(db: fakeDb);
    });

    test('Initial fetch auto-seeds default earnings into Firestore', () async {
      final earnings = await earningsService.getEarnings(
        mechanicUid: testMechUid,
      );
      expect(earnings, isNotEmpty);

      final snap = await fakeDb.collection('earnings').get();
      expect(snap.docs.length, equals(mockEarnings.length));
    });

    test('Record new earning persists to Firestore', () async {
      final newRecord = EarningsRecord(
        jobId: '#RM-9999',
        transactionId: 'TXN-9999',
        serviceType: 'Battery Jump Start',
        customerName: 'Kamal P.',
        serviceCharge: 2500,
        platformFee: 250,
        netEarnings: 2250,
        paymentStatus: 'Completed',
        completedDate: DateTime.now(),
        mechanicUid: testMechUid,
      );

      await earningsService.recordEarning(newRecord);

      final list = await earningsService.getEarnings(mechanicUid: testMechUid);
      expect(list.any((e) => e.transactionId == 'TXN-9999'), isTrue);

      final doc = await fakeDb.collection('earnings').doc('TXN-9999').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['netEarnings'], equals(2250.0));
    });

    test('CalculateMetrics properly computes totals and average payouts', () {
      final records = [
        EarningsRecord(
          jobId: '#RM-1',
          transactionId: 'TXN-1',
          serviceType: 'Service 1',
          serviceCharge: 3000,
          platformFee: 300,
          netEarnings: 2700,
          paymentStatus: 'Completed',
          completedDate: DateTime.now(),
        ),
        EarningsRecord(
          jobId: '#RM-2',
          transactionId: 'TXN-2',
          serviceType: 'Service 2',
          serviceCharge: 5000,
          platformFee: 500,
          netEarnings: 4500,
          paymentStatus: 'Completed',
          completedDate: DateTime.now(),
        ),
      ];

      final metrics = earningsService.calculateMetrics(records);
      expect(metrics['totalNet'], equals(7200.0));
      expect(metrics['completedCount'], equals(2));
      expect(metrics['avgJobPayout'], equals(3600.0));
    });
  });
}

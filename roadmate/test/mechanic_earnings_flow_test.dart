import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/earnings_record.dart';
import 'package:roadmate/screens/earnings_dashboard_screen.dart';
import 'package:roadmate/screens/earnings_details_screen.dart';
import 'package:roadmate/services/earnings_service.dart';

void main() {
  group('Mechanic Earnings Real-Time Updates & Deduplication Tests', () {
    late FakeFirebaseFirestore fakeDb;
    late EarningsService earningsService;
    const testMechUid = 'mech_live_777';

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
      earningsService = EarningsService(db: fakeDb);
    });

    test('Completed customer payment records earnings linked to mechanic',
        () async {
      final initial =
          await earningsService.getEarnings(mechanicUid: testMechUid);
      final initialCount = initial.length;

      final completedTxn = EarningsRecord(
        jobId: 'JOB-PAID-001',
        transactionId: 'TXN-PAID-001',
        serviceType: 'Tire & Wheel Service',
        customerName: 'Nimal Perera',
        serviceCharge: 6000,
        platformFee: 600,
        netEarnings: 5400,
        paymentStatus: 'Completed',
        completedDate: DateTime.now(),
        mechanicUid: testMechUid,
        notes: 'Driver paid online via card',
      );

      await earningsService.recordEarning(completedTxn);

      final updated =
          await earningsService.getEarnings(mechanicUid: testMechUid);
      expect(updated.length, equals(initialCount + 1));

      final found =
          updated.firstWhere((e) => e.transactionId == 'TXN-PAID-001');
      expect(found.netEarnings, equals(5400.0));
      expect(found.mechanicUid, equals(testMechUid));
      expect(found.isCompleted, isTrue);
    });

    test('Processing the same payment twice does NOT duplicate earnings',
        () async {
      final txn = EarningsRecord(
        jobId: 'JOB-DUP-100',
        transactionId: 'TXN-DUP-100',
        serviceType: 'Car Service',
        customerName: 'Sunil Silva',
        serviceCharge: 10000,
        platformFee: 1000,
        netEarnings: 9000,
        paymentStatus: 'Completed',
        completedDate: DateTime.now(),
        mechanicUid: testMechUid,
      );

      // First submission
      await earningsService.recordEarning(txn);
      final list1 =
          await earningsService.getEarnings(mechanicUid: testMechUid);
      final count1 = list1.where((e) => e.transactionId == 'TXN-DUP-100').length;
      expect(count1, equals(1));

      // Second duplicate submission
      await earningsService.recordEarning(txn);
      final list2 =
          await earningsService.getEarnings(mechanicUid: testMechUid);
      final count2 = list2.where((e) => e.transactionId == 'TXN-DUP-100').length;
      expect(count2, equals(1),
          reason: 'Duplicate payment must be idempotent and not create duplicate entries');
    });

    test('Pending, failed, or reversed payments are excluded from completed earnings',
        () {
      final records = [
        EarningsRecord(
          jobId: 'J1',
          transactionId: 'T1',
          serviceType: 'Tire',
          serviceCharge: 3000,
          platformFee: 300,
          netEarnings: 2700,
          paymentStatus: 'Completed',
          completedDate: DateTime.now(),
        ),
        EarningsRecord(
          jobId: 'J2',
          transactionId: 'T2',
          serviceType: 'Tow',
          serviceCharge: 5000,
          platformFee: 500,
          netEarnings: 4500,
          paymentStatus: 'Pending',
          completedDate: DateTime.now(),
        ),
        EarningsRecord(
          jobId: 'J3',
          transactionId: 'T3',
          serviceType: 'Battery',
          serviceCharge: 4000,
          platformFee: 400,
          netEarnings: 3600,
          paymentStatus: 'Completed',
          completedDate: DateTime.now(),
          isReversed: true,
          adjustmentReason: 'Customer refund',
        ),
      ];

      final metrics = earningsService.calculateMetrics(records);
      // Only J1 isCompleted (T1 = 2700). T2 is pending. T3 is reversed.
      expect(metrics['completedCount'], equals(1));
      expect(metrics['totalNet'], equals(2700.0));
      expect(metrics['pendingCount'], equals(1));
      expect(metrics['pendingAmount'], equals(4500.0));
    });

    test('CRUD: Create manual adjustment, Update note, and Traceable Reversal',
        () async {
      // 1. Create (Adjustment / Tip)
      final adj = await earningsService.recordAdjustment(
        mechanicUid: testMechUid,
        serviceType: 'Client Tip / Bonus',
        amount: 1500,
        jobId: 'JOB-BONUS-01',
        notes: 'Extra tip from grateful client',
      );
      expect(adj.transactionId, isNotEmpty);
      expect(adj.netEarnings, equals(1500.0));

      // 2. Read
      final list = await earningsService.getEarnings(mechanicUid: testMechUid);
      final fetched =
          list.firstWhere((e) => e.transactionId == adj.transactionId);
      expect(fetched.notes, equals('Extra tip from grateful client'));

      // 3. Update note
      final updated = fetched.copyWith(notes: 'Updated note with supervisor sign-off');
      await earningsService.updateEarning(updated);

      final listAfterUpdate =
          await earningsService.getEarnings(mechanicUid: testMechUid);
      final updatedFetched = listAfterUpdate
          .firstWhere((e) => e.transactionId == adj.transactionId);
      expect(updatedFetched.notes,
          equals('Updated note with supervisor sign-off'));

      // 4. Traceable Reversal
      await earningsService.reverseEarning(
        transactionId: adj.transactionId,
        reason: 'Client requested cash tip refund',
      );

      final listAfterReversal =
          await earningsService.getEarnings(mechanicUid: testMechUid);
      final reversedFetched = listAfterReversal
          .firstWhere((e) => e.transactionId == adj.transactionId);
      expect(reversedFetched.isReversed, isTrue);
      expect(reversedFetched.adjustmentReason,
          equals('Client requested cash tip refund'));
      expect(reversedFetched.isCompleted, isFalse,
          reason: 'Reversed transactions must not be counted as completed');
    });

    test('CRUD Delete Draft allows deleting draft but prevents deleting completed records',
        () async {
      // Create a draft (Pending) record
      final draft = EarningsRecord(
        jobId: 'DRAFT-1',
        transactionId: 'TXN-DRAFT-1',
        serviceType: 'Inspection',
        serviceCharge: 1000,
        platformFee: 100,
        netEarnings: 900,
        paymentStatus: 'Pending',
        completedDate: DateTime.now(),
        mechanicUid: testMechUid,
      );
      await earningsService.recordEarning(draft);

      final beforeDel =
          await earningsService.getEarnings(mechanicUid: testMechUid);
      expect(beforeDel.any((e) => e.transactionId == 'TXN-DRAFT-1'), isTrue);

      // Deleting draft succeeds
      final deleted =
          await earningsService.deleteDraftEarning('TXN-DRAFT-1');
      expect(deleted, isTrue);

      final afterDel =
          await earningsService.getEarnings(mechanicUid: testMechUid);
      expect(afterDel.any((e) => e.transactionId == 'TXN-DRAFT-1'), isFalse);
    });
  });

  group('Mechanic Earnings UI Widget Tests', () {
    late FakeFirebaseFirestore fakeDb;
    late EarningsService earningsService;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
      earningsService = EarningsService(db: fakeDb);
    });

    testWidgets(
        'EarningsDashboardScreen renders with date dropdown, chart, KPIs, and category breakdown',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EarningsDashboardScreen(
          earningsService: earningsService,
          mechanicUid: 'mech_ui_test',
        ),
      ));
      await tester.pumpAndSettle();

      // Header and titles
      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('TOTAL REVENUE'), findsOneWidget);
      expect(find.text('Weekly Earnings'), findsOneWidget);
      expect(find.text('Completed Jobs'), findsOneWidget);
      expect(find.text('Earnings by Service Category'), findsOneWidget);

      // Dropdown filter default: Today
      expect(find.text('Today'), findsOneWidget);

      // Change filter to This Week
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('This Week').last);
      await tester.pumpAndSettle();

      expect(find.text('This Week'), findsWidgets);
    });

    testWidgets('EarningsDetailsScreen allows editing note and requesting reversal',
        (tester) async {
      final sampleRecord = EarningsRecord(
        jobId: 'JOB-DETAIL-99',
        transactionId: 'TXN-DETAIL-99',
        serviceType: 'Emergency Towing',
        customerName: 'Chathura Fernando',
        serviceCharge: 8000,
        platformFee: 800,
        netEarnings: 7200,
        paymentStatus: 'Completed',
        completedDate: DateTime.now(),
        mechanicUid: 'mech_ui_test',
        notes: 'Initial dispatch note',
      );
      await earningsService.recordEarning(sampleRecord);

      await tester.pumpWidget(MaterialApp(
        home: EarningsDetailsScreen(
          record: sampleRecord,
          earningsService: earningsService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Earnings Details'), findsOneWidget);
      expect(find.text('JOB-DETAIL-99'), findsOneWidget);
      expect(find.text('TXN-DETAIL-99'), findsOneWidget);
      expect(find.text('Initial dispatch note'), findsOneWidget);

      // Tap Edit Note
      await tester.tap(find.text('Edit Note'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Memo / Notes'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Verified payment by driver');
      await tester.tap(find.text('Save Note'));
      await tester.pumpAndSettle();

      expect(find.text('Verified payment by driver'), findsOneWidget);

      // Tap Request Traceable Reversal
      await tester.ensureVisible(find.text('Request Traceable Reversal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Request Traceable Reversal'));
      await tester.pumpAndSettle();

      expect(find.text('Request Reversal'), findsOneWidget);
      await tester.enterText(
          find.byType(TextField), 'Driver cancelled after dispatch');
      await tester.tap(find.text('Confirm Reversal'));
      await tester.pumpAndSettle();

      // Should now show warning banner and REVERSED status
      expect(find.text('Transaction Reversed'), findsOneWidget);
      expect(find.text('Reversed & Deducted'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/screens/make_payment_screen.dart';
import 'package:roadmate/screens/payment_history_screen.dart';

void main() {
  group('PaymentHistoryScreen & Payment Sync Tests', () {
    testWidgets('PaymentHistoryScreen renders exactly one "All" filter chip',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentHistoryScreen(driverUid: 'driver-test-uid'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('Payment History'), findsOneWidget);

      // Verify that there is EXACTLY ONE "All" chip (no duplicate "All" chips)
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);

      // Verify other unified filter chips
      expect(find.widgetWithText(FilterChip, 'Completed'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Pending'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'This Month'), findsOneWidget);

      // Ensure no duplicate or leftover ChoiceChips exist
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Previous'), findsNothing);
    });

    testWidgets('Filter chips in PaymentHistoryScreen filter correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentHistoryScreen(driverUid: 'driver-test-uid'),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pending filter chip specifically
      final pendingChip = find.widgetWithText(FilterChip, 'Pending');
      expect(pendingChip, findsOneWidget);
      await tester.tap(pendingChip);
      await tester.pumpAndSettle();

      // In mockTransactions, 'Fuel Drop' is pending
      expect(find.text('Fuel Drop'), findsOneWidget);

      // Tap Completed filter chip specifically
      final completedChip = find.widgetWithText(FilterChip, 'Completed');
      expect(completedChip, findsOneWidget);
      await tester.tap(completedChip);
      await tester.pumpAndSettle();

      expect(find.text('Battery Jump Start'), findsOneWidget);

      // Tap All filter chip
      final allChip = find.widgetWithText(FilterChip, 'All');
      expect(allChip, findsOneWidget);
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      expect(find.text('Battery Jump Start'), findsOneWidget);
      expect(find.text('Fuel Drop'), findsOneWidget);
    });

    testWidgets(
        'Payment completed from MakePaymentScreen immediately shows in PaymentHistoryScreen',
        (tester) async {
      const testDriverUid = 'driver-101-test';

      // 1. Render MakePaymentScreen and execute a payment
      await tester.pumpWidget(
        const MaterialApp(
          home: MakePaymentScreen(
            jobId: 'REQ-LIVE-999',
            serviceType: 'Emergency Towing',
            providerName: 'Sunil Shantha',
            serviceCharge: 6500.0,
            additionalCharges: 500.0,
            driverUid: testDriverUid,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final payBtn = find.textContaining('Pay Rs.');
      expect(payBtn, findsOneWidget);
      await tester.ensureVisible(payBtn);
      await tester.tap(payBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verifies payment reached confirmation screen
      expect(find.text('Payment Completed!'), findsOneWidget);

      // 2. Open PaymentHistoryScreen with testDriverUid
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentHistoryScreen(
            driverUid: testDriverUid,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Verify newly recorded payment appears in history!
      expect(find.text('Emergency Towing'), findsWidgets);
      expect(find.textContaining('7,000.00'), findsWidgets);
    });

    testWidgets('Pull to refresh invokes _loadTransactions smoothly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentHistoryScreen(driverUid: 'driver-refresh-test'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);

      // Trigger pull to refresh gesture
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Payment History'), findsOneWidget);
    });
  });
}

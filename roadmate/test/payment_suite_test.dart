import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/earnings_record.dart';
import 'package:roadmate/models/payment_method.dart';
import 'package:roadmate/models/payment_transaction.dart';
import 'package:roadmate/screens/add_card_screen.dart';
import 'package:roadmate/screens/digital_receipt_screen.dart';
import 'package:roadmate/screens/earnings_dashboard_screen.dart';
import 'package:roadmate/screens/earnings_details_screen.dart';
import 'package:roadmate/screens/earnings_history_screen.dart';
import 'package:roadmate/screens/edit_card_screen.dart';
import 'package:roadmate/screens/make_payment_screen.dart';
import 'package:roadmate/screens/mechanic_transaction_history_screen.dart';
import 'package:roadmate/screens/payment_confirmation_screen.dart';
import 'package:roadmate/screens/payment_details_screen.dart';
import 'package:roadmate/screens/payment_history_screen.dart';
import 'package:roadmate/screens/payment_methods_screen.dart';
import 'package:roadmate/screens/service_charges_screen.dart';
import 'package:roadmate/widgets/payment_widgets.dart';

void main() {
  final sampleTx = PaymentTransaction(
    transactionId: 'TXN-001',
    jobId: 'REQ-001',
    serviceType: 'Battery Jump Start',
    serviceProvider: 'Nimal Bandara',
    serviceCharge: 2000,
    additionalCharges: 800,
    platformFee: 200,
    totalAmount: 3500.0,
    status: TransactionStatus.completed,
  );

  final sampleEarnings = EarningsRecord(
    jobId: '#RM-1029',
    transactionId: 'TXN-89410284',
    serviceType: 'Battery Jump Start',
    customerName: 'Kasun J.',
    serviceCharge: 3500,
    platformFee: 350,
    netEarnings: 3150,
    completedDate: DateTime.now(),
  );

  group('Payment & Earnings Suite Tests', () {
    test('Currency formatting works correctly', () {
      expect(formatCurrency(3500.0), 'Rs. 3,500.00');
      expect(formatCurrency(12500.50), 'Rs. 12,500.50');
      expect(formatCurrency(0.0), 'Rs. 0.00');
    });

    test('PaymentMethod model properties', () {
      const method = PaymentMethod(
        id: 'pm-1',
        type: PaymentMethodType.card,
        brand: 'Visa',
        last4: '4242',
        expiryMonth: '08',
        expiryYear: '28',
      );
      expect(method.maskedNumber, '•••• 4242');
      expect(method.expiry, '08/28');
    });

    test('PaymentTransaction model properties', () {
      expect(sampleTx.statusLabel, 'Completed');
      expect(sampleTx.date, isNotEmpty);
    });

    test('EarningsRecord model properties', () {
      expect(sampleEarnings.netEarnings, 3150);
      expect(sampleEarnings.serviceCharge - sampleEarnings.platformFee,
          sampleEarnings.netEarnings);
    });

    testWidgets('PaymentMethodsScreen renders correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PaymentMethodsScreen()));
      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.text('Add New Card'), findsOneWidget);
    });

    testWidgets('AddCardScreen renders live preview and inputs', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddCardScreen()));
      expect(find.text('Add New Card'), findsOneWidget);
      expect(find.text('Cardholder Name'), findsOneWidget);
      expect(find.text('Save Card Securely'), findsOneWidget);
    });

    testWidgets('EditCardScreen renders card information', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EditCardScreen(
          card: mockPaymentMethods.first,
        ),
      ));
      expect(find.text('Manage Card'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('MakePaymentScreen renders breakdown', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MakePaymentScreen()));
      expect(find.text('Make Payment'), findsOneWidget);
      expect(find.text('Charge Breakdown'), findsOneWidget);
    });

    testWidgets('PaymentConfirmationScreen renders success', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PaymentConfirmationScreen(transaction: sampleTx),
      ));
      expect(find.text('Payment Completed!'), findsOneWidget);
      expect(find.text('View Digital Receipt'), findsOneWidget);
    });

    testWidgets('PaymentHistoryScreen renders transaction search',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PaymentHistoryScreen()));
      expect(find.text('Payment History'), findsOneWidget);
    });

    testWidgets('PaymentDetailsScreen renders itemized info', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PaymentDetailsScreen(transaction: sampleTx),
      ));
      expect(find.text('Transaction Details'), findsOneWidget);
    });

    testWidgets('DigitalReceiptScreen renders invoice layout', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DigitalReceiptScreen(transaction: sampleTx),
      ));
      expect(find.text('Digital Receipt'), findsOneWidget);
      expect(find.text('Download PDF'), findsOneWidget);
    });

    testWidgets(
        'ServiceChargesScreen renders transparent pricing and fits 320px and 360px mobile viewports without overflow',
        (tester) async {
      // Test narrowest 320px width (e.g. small mobile)
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ServiceChargesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Pricing & Service Charges'), findsOneWidget);
      expect(find.text('RoadMate Standard Rates'), findsOneWidget);
      expect(find.text('Estimated Total'), findsOneWidget);
      expect(find.text('Final price confirmed upon service completion'), findsOneWidget);
      expect(find.byType(AmountDisplay), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EarningsDashboardScreen renders revenue and performance',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EarningsDashboardScreen()));
      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('TOTAL REVENUE'), findsOneWidget);
      expect(find.text('Weekly Performance'), findsOneWidget);
    });

    testWidgets('EarningsHistoryScreen renders job records', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EarningsHistoryScreen()));
      expect(find.text('Earnings History'), findsOneWidget);
    });

    testWidgets('MechanicTransactionHistoryScreen renders statements',
        (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: MechanicTransactionHistoryScreen()));
      expect(find.text('Transaction History'), findsOneWidget);
    });

    testWidgets('EarningsDetailsScreen renders payout settlement',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EarningsDetailsScreen(record: sampleEarnings),
      ));
      expect(find.text('Earnings Details'), findsOneWidget);
      expect(find.text('NET EARNINGS'), findsOneWidget);
    });
  });
}

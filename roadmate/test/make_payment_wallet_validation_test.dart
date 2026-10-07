import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/payment_method.dart';
import 'package:roadmate/screens/make_payment_screen.dart';
import 'package:roadmate/screens/payment_confirmation_screen.dart';

void main() {
  setUp(() {
    // Reset mockPaymentMethods wallet balance before each test to Rs. 2,450.00
    final walletIndex =
        mockPaymentMethods.indexWhere((m) => m.type == PaymentMethodType.wallet);
    if (walletIndex != -1) {
      mockPaymentMethods[walletIndex] = mockPaymentMethods[walletIndex].copyWith(
        balance: 2450.00,
        subtitle: 'Available Balance: Rs. 2,450.00',
      );
    }
  });

  group('MakePaymentScreen Wallet Balance Validation Tests', () {
    testWidgets(
        'Requirement 1 & 2: When Wallet is selected and balance (Rs. 2,450) < total (Rs. 7,250), displays insufficient balance card with exact required amount',
        (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MakePaymentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // By default, the first card or default method is selected. Total is Rs. 7,250.00.
      expect(find.text('Rs. 7,250.00'), findsWidgets);

      // Verify no insufficient balance message yet when Card is selected
      expect(find.text('Insufficient wallet balance'), findsNothing);

      // Select RoadMate In-App Wallet
      final walletOption = find.text('RoadMate In-App Wallet');
      expect(walletOption, findsOneWidget);
      await tester.ensureVisible(walletOption);
      await tester.tap(walletOption);
      await tester.pumpAndSettle();

      // Verify Insufficient wallet balance error message
      expect(find.text('Insufficient wallet balance'), findsOneWidget);
      expect(
        find.textContaining(
            'Your wallet balance is Rs. 2,450.00, but the total payment is Rs. 7,250.00.'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
            'Please add Rs. 4,800.00 to your wallet or select another payment method.'),
        findsOneWidget,
      );

      // Verify Top Up action button is visible
      expect(find.text('Top Up Wallet'), findsOneWidget);
      expect(find.text('Select Card Instead'), findsOneWidget);
    });

    testWidgets(
        'Requirement 3: When wallet is insufficient, Pay Now button is disabled and does NOT navigate or create payment',
        (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MakePaymentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select Wallet
      final walletOption = find.text('RoadMate In-App Wallet');
      await tester.ensureVisible(walletOption);
      await tester.tap(walletOption);
      await tester.pumpAndSettle();

      // Button is disabled with 'Insufficient Wallet Balance' label
      final payButton = find.text('Insufficient Wallet Balance');
      expect(payButton, findsOneWidget);
      await tester.ensureVisible(payButton);

      // Attempt to tap the disabled button
      await tester.tap(payButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Should remain on Make Payment screen, NOT Payment Confirmation screen
      expect(find.byType(MakePaymentScreen), findsOneWidget);
      expect(find.byType(PaymentConfirmationScreen), findsNothing);
      expect(find.text('Payment Completed!'), findsNothing);
    });

    testWidgets(
        'Requirement 8: Switching back from Wallet to Card removes validation error and enables payment',
        (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MakePaymentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select Wallet
      final walletOption = find.text('RoadMate In-App Wallet');
      await tester.ensureVisible(walletOption);
      await tester.tap(walletOption);
      await tester.pumpAndSettle();
      expect(find.text('Insufficient wallet balance'), findsOneWidget);

      // Switch back to Card via "Select Card Instead" or tapping a card
      final selectCardBtn = find.text('Select Card Instead');
      await tester.ensureVisible(selectCardBtn);
      await tester.tap(selectCardBtn);
      await tester.pumpAndSettle();

      // Error message must disappear
      expect(find.text('Insufficient wallet balance'), findsNothing);
    });

    testWidgets(
        'Requirement 5: When Wallet Balance >= Total Payable, payment is allowed and proceeds to confirmation',
        (tester) async {
      // Set wallet balance to 10,000 (>= 7,250)
      final walletIndex =
          mockPaymentMethods.indexWhere((m) => m.type == PaymentMethodType.wallet);
      mockPaymentMethods[walletIndex] = mockPaymentMethods[walletIndex].copyWith(
        balance: 10000.00,
        subtitle: 'Available Balance: Rs. 10,000.00',
      );

      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MakePaymentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select Wallet
      final walletOption = find.text('RoadMate In-App Wallet');
      await tester.ensureVisible(walletOption);
      await tester.tap(walletOption);
      await tester.pumpAndSettle();

      // No error message should appear
      expect(find.text('Insufficient wallet balance'), findsNothing);

      // Tap Pay button
      final payButton = find.text('Pay Rs. 7,250.00');
      await tester.ensureVisible(payButton);
      await tester.tap(payButton);
      // Allow processing timer to tick
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Should navigate to PaymentConfirmationScreen
      expect(find.byType(PaymentConfirmationScreen), findsOneWidget);
      expect(find.text('Payment Completed!'), findsOneWidget);

      // Remaining wallet balance should be 10,000 - 7,250 = 2,750
      final updatedWallet =
          mockPaymentMethods.firstWhere((m) => m.type == PaymentMethodType.wallet);
      expect(updatedWallet.walletBalance, 2750.00);
    });

    testWidgets(
        'Requirement 8 Edge Case: Wallet balance == Total Payable (7,250.00) is allowed',
        (tester) async {
      final walletIndex =
          mockPaymentMethods.indexWhere((m) => m.type == PaymentMethodType.wallet);
      mockPaymentMethods[walletIndex] = mockPaymentMethods[walletIndex].copyWith(
        balance: 7250.00,
        subtitle: 'Available Balance: Rs. 7,250.00',
      );

      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MakePaymentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final walletOption = find.text('RoadMate In-App Wallet');
      await tester.ensureVisible(walletOption);
      await tester.tap(walletOption);
      await tester.pumpAndSettle();

      expect(find.text('Insufficient wallet balance'), findsNothing);

      final payButton = find.text('Pay Rs. 7,250.00');
      await tester.ensureVisible(payButton);
      await tester.tap(payButton);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.byType(PaymentConfirmationScreen), findsOneWidget);

      final updatedWallet =
          mockPaymentMethods.firstWhere((m) => m.type == PaymentMethodType.wallet);
      expect(updatedWallet.walletBalance, 0.0);
    });

    testWidgets(
        'Requirement 8 Edge Case: Wallet balance == 0.0 is blocked',
        (tester) async {
      final walletIndex =
          mockPaymentMethods.indexWhere((m) => m.type == PaymentMethodType.wallet);
      mockPaymentMethods[walletIndex] = mockPaymentMethods[walletIndex].copyWith(
        balance: 0.0,
        subtitle: 'Available Balance: Rs. 0.00',
      );

      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MakePaymentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final walletOption = find.text('RoadMate In-App Wallet');
      await tester.ensureVisible(walletOption);
      await tester.tap(walletOption);
      await tester.pumpAndSettle();

      expect(find.text('Insufficient wallet balance'), findsOneWidget);
      expect(
        find.textContaining('Your wallet balance is Rs. 0.00, but the total payment is Rs. 7,250.00.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Please add Rs. 7,250.00 to your wallet or select another payment method.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'Requirement 4: Top Up Wallet dialog allows adding required funds and removes insufficient state',
        (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MakePaymentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select Wallet with Rs. 2,450
      final walletOption = find.text('RoadMate In-App Wallet');
      await tester.ensureVisible(walletOption);
      await tester.tap(walletOption);
      await tester.pumpAndSettle();

      expect(find.text('Insufficient wallet balance'), findsOneWidget);

      // Tap Top Up Wallet button
      final topUpBtn = find.text('Top Up Wallet');
      await tester.ensureVisible(topUpBtn);
      await tester.tap(topUpBtn);
      await tester.pumpAndSettle();

      // Top Up dialog should appear
      expect(find.text('Top Up Now'), findsOneWidget);
      expect(find.text('Add funds to your RoadMate In-App Wallet to proceed with payment.'), findsOneWidget);

      // Perform top up
      await tester.tap(find.text('Top Up Now'));
      await tester.pumpAndSettle();

      // Dialog dismissed, wallet now has enough balance (2,450 + 4,800 = 7,250)
      expect(find.text('Insufficient wallet balance'), findsNothing);
      expect(find.text('Top Up Now'), findsNothing);
    });
  });
}

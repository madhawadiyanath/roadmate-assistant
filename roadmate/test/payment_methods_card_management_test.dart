import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/payment_method.dart';
import 'package:roadmate/screens/payment_methods_screen.dart';
import 'package:roadmate/widgets/payment_widgets.dart';

void main() {
  setUp(() {
    mockPaymentMethods = [
      const PaymentMethod(
        id: 'card_1',
        type: PaymentMethodType.card,
        label: 'Mastercard',
        last4: '4242',
        brand: 'Mastercard',
        expiryMonth: '12',
        expiryYear: '28',
        holderName: 'Kasun Jayawardena',
        isDefault: true,
      ),
      const PaymentMethod(
        id: 'card_2',
        type: PaymentMethodType.card,
        label: 'Visa',
        last4: '8921',
        brand: 'Visa',
        expiryMonth: '08',
        expiryYear: '27',
        holderName: 'Kasun Jayawardena',
        isDefault: false,
      ),
      const PaymentMethod(
        id: 'card_3',
        type: PaymentMethodType.card,
        label: 'Mastercard',
        last4: '1111',
        brand: 'Mastercard',
        expiryMonth: '03',
        expiryYear: '29',
        holderName: 'Kasun Jayawardena',
        isDefault: false,
      ),
      const PaymentMethod(
        id: 'wallet_1',
        type: PaymentMethodType.wallet,
        label: 'RoadMate In-App Wallet',
        subtitle: 'Available Balance: Rs. 2,450.00',
        isDefault: false,
      ),
      const PaymentMethod(
        id: 'cash_1',
        type: PaymentMethodType.cash,
        label: 'Cash on Service',
        subtitle: 'Pay directly to patrol specialist',
        isDefault: false,
      ),
    ];
  });

  group('Payment Methods Card Management Flow Tests', () {
    testWidgets(
        'Test 1: Open Mastercard •••• 4242 -> Edit expiration date -> Save Changes -> Return -> Verify updated expiry appears',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: PaymentMethodsScreen()));
      await tester.pumpAndSettle();

      // Verify initial cards exist
      expect(find.text('•••• 4242'), findsOneWidget);
      expect(find.text('Mastercard • Exp 12/28'), findsOneWidget);

      // Tap on Mastercard •••• 4242 to open Manage Card screen
      await tester.tap(find.text('•••• 4242'));
      await tester.pumpAndSettle();

      expect(find.text('Manage Card'), findsOneWidget);

      // Find Expiration Date field
      final expiryField = find.widgetWithText(RoadMateTextField, 'Expiration Date');
      expect(expiryField, findsOneWidget);

      final textField = find.descendant(
        of: expiryField,
        matching: find.byType(TextField),
      );

      // Change expiry date to 11/29
      await tester.enterText(textField, '11/29');
      await tester.pumpAndSettle();

      // Tap Save Changes
      final saveBtn = find.text('Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Returned to Payment Methods screen
      expect(find.text('Payment Methods'), findsOneWidget);

      // Verify the updated expiration date appears immediately in the card list
      expect(find.text('•••• 4242'), findsOneWidget);
      expect(find.text('Mastercard • Exp 11/29'), findsOneWidget);

      // Ensure no duplicate cards
      expect(find.text('•••• 4242'), findsOneWidget);
    });

    testWidgets(
        'Test 2: Open Mastercard •••• 1111 -> Remove card -> Confirm removal -> Return -> Verify card is completely removed',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: PaymentMethodsScreen()));
      await tester.pumpAndSettle();

      // Verify initial cards exist
      expect(find.text('•••• 1111'), findsOneWidget);
      expect(find.text('Mastercard • Exp 03/29'), findsOneWidget);

      // Tap on Mastercard •••• 1111
      await tester.tap(find.text('•••• 1111'));
      await tester.pumpAndSettle();

      expect(find.text('Manage Card'), findsOneWidget);

      // Tap "Remove This Card"
      final removeBtn = find.text('Remove This Card');
      await tester.ensureVisible(removeBtn);
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog should be visible
      expect(find.text('Remove Card'), findsOneWidget);

      // Tap "Remove" to confirm
      final confirmBtn = find.text('Remove');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Returned to Payment Methods screen
      expect(find.text('Payment Methods'), findsOneWidget);

      // Verify Mastercard •••• 1111 is completely removed
      expect(find.text('•••• 1111'), findsNothing);
      expect(find.text('Mastercard • Exp 03/29'), findsNothing);

      // Other cards remain
      expect(find.text('•••• 4242'), findsOneWidget);
      expect(find.text('•••• 8921'), findsOneWidget);
    });

    testWidgets(
        'Test 3: Select Visa •••• 8921 as Default in Manage Card -> Return -> Verify Visa is Default and previous default is no longer Default',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: PaymentMethodsScreen()));
      await tester.pumpAndSettle();

      // Initially, card 4242 has the Default badge
      expect(find.text('•••• 4242'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);

      // Open Visa •••• 8921
      await tester.tap(find.text('•••• 8921'));
      await tester.pumpAndSettle();

      expect(find.text('Manage Card'), findsOneWidget);

      // Toggle "Set as Default Payment Method" switch to true
      final defaultSwitch = find.byType(Switch);
      expect(defaultSwitch, findsOneWidget);
      await tester.tap(defaultSwitch);
      await tester.pumpAndSettle();

      // Save Changes
      final saveBtn = find.text('Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Returned to Payment Methods
      expect(find.text('Payment Methods'), findsOneWidget);

      // Only ONE Default badge should exist
      expect(find.text('Default'), findsOneWidget);

      // Visa •••• 8921 is now marked as default in the list
      final visaFinder = find.ancestor(
        of: find.text('•••• 8921'),
        matching: find.byType(Container),
      );
      expect(visaFinder, findsWidgets);

      // Verify in source of truth
      final visaMock = mockPaymentMethods.firstWhere((m) => m.id == 'card_2');
      final masterMock = mockPaymentMethods.firstWhere((m) => m.id == 'card_1');
      expect(visaMock.isDefault, isTrue);
      expect(masterMock.isDefault, isFalse);
    });

    testWidgets(
        'Test 4: Remove a card -> Navigate to another screen -> Return to Payment Methods -> Verify removed card is still gone',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final key = GlobalKey<NavigatorState>();

      await tester.pumpWidget(MaterialApp(
        navigatorKey: key,
        home: const PaymentMethodsScreen(),
      ));
      await tester.pumpAndSettle();

      // Verify card 1111 exists
      expect(find.text('•••• 1111'), findsOneWidget);

      // Open card 1111
      await tester.tap(find.text('•••• 1111'));
      await tester.pumpAndSettle();

      // Remove card
      final removeBtn = find.text('Remove This Card');
      await tester.ensureVisible(removeBtn);
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Back on Payment Methods
      expect(find.text('•••• 1111'), findsNothing);

      // Navigate away to another screen
      key.currentState!.push(MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Dummy Screen')),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Dummy Screen'), findsOneWidget);

      // Navigate back to Payment Methods
      key.currentState!.pop();
      await tester.pumpAndSettle();

      // Verify card 1111 is still gone!
      expect(find.text('•••• 1111'), findsNothing);
      expect(find.text('•••• 4242'), findsOneWidget);
      expect(find.text('•••• 8921'), findsOneWidget);

      // Push a brand new PaymentMethodsScreen instance (simulating navigation from dashboard)
      key.currentState!.push(MaterialPageRoute(
        builder: (_) => const PaymentMethodsScreen(),
      ));
      await tester.pumpAndSettle();

      // On new instance, card 1111 is still gone because source of truth was updated!
      expect(find.text('•••• 1111'), findsNothing);
      expect(find.text('•••• 4242'), findsOneWidget);
      expect(find.text('•••• 8921'), findsOneWidget);
    });
  });
}

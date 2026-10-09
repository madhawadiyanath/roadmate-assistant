import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/payment_method.dart';
import 'package:roadmate/screens/add_card_screen.dart';
import 'package:roadmate/screens/edit_card_screen.dart';
import 'package:roadmate/widgets/payment_widgets.dart';

void main() {
  group('Expiration Date Validation Unit Tests', () {
    final fixedNow = DateTime(2026, 10, 6);

    test('00/27 is rejected with invalid format message', () {
      expect(
        validateCardExpiry('00/27', now: fixedNow),
        'Enter a valid expiration date (MM/YY)',
      );
    });

    test('13/27 is rejected with invalid format message', () {
      expect(
        validateCardExpiry('13/27', now: fixedNow),
        'Enter a valid expiration date (MM/YY)',
      );
    });

    test('12/27 is accepted (future valid expiration date)', () {
      expect(validateCardExpiry('12/27', now: fixedNow), isNull);
    });

    test('08/27 is accepted', () {
      expect(validateCardExpiry('08/27', now: fixedNow), isNull);
    });

    test('12/28 is accepted', () {
      expect(validateCardExpiry('12/28', now: fixedNow), isNull);
    });

    test('09/26 is rejected when current date is Oct 2026 (expired)', () {
      expect(
        validateCardExpiry('09/26', now: fixedNow),
        'Card has expired',
      );
    });

    test('10/26 is accepted as current month is valid until end of month', () {
      expect(validateCardExpiry('10/26', now: fixedNow), isNull);
    });

    test('Empty or whitespace is rejected', () {
      expect(
        validateCardExpiry('', now: fixedNow),
        'Enter a valid expiration date (MM/YY)',
      );
      expect(
        validateCardExpiry('   ', now: fixedNow),
        'Enter a valid expiration date (MM/YY)',
      );
    });

    test('Invalid formats and letters are rejected', () {
      expect(
        validateCardExpiry('abc', now: fixedNow),
        'Enter a valid expiration date (MM/YY)',
      );
      expect(
        validateCardExpiry('12/2027', now: fixedNow),
        'Enter a valid expiration date (MM/YY)',
      );
      expect(
        validateCardExpiry('1/27', now: fixedNow),
        'Enter a valid expiration date (MM/YY)',
      );
      expect(
        validateCardExpiry('12/2', now: fixedNow),
        'Enter a valid expiration date (MM/YY)',
      );
    });
  });

  group('CardExpiryInputFormatter Unit Tests', () {
    final formatter = CardExpiryInputFormatter();

    test('Typing single digit 2-9 auto formats to 0X/', () {
      final res = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '8',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(res.text, '08/');
      expect(res.selection.baseOffset, 3);
    });

    test('Typing 1 leaves 1 to allow 10, 11, 12', () {
      final res = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(res.text, '1');
      expect(res.selection.baseOffset, 1);
    });

    test('Typing 1 then / formats to 01/', () {
      final res = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
        const TextEditingValue(
          text: '1/',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(res.text, '01/');
      expect(res.selection.baseOffset, 3);
    });

    test('Typing 1 then 2 formats to 12/', () {
      final res = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
        const TextEditingValue(
          text: '12',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(res.text, '12/');
      expect(res.selection.baseOffset, 3);
    });

    test('Month 00 is blocked', () {
      const oldVal = TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
      final res = formatter.formatEditUpdate(
        oldVal,
        const TextEditingValue(
          text: '00',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(res.text, '0');
    });

    test('Month > 12 is blocked', () {
      const oldVal = TextEditingValue(
        text: '1',
        selection: TextSelection.collapsed(offset: 1),
      );
      final res = formatter.formatEditUpdate(
        oldVal,
        const TextEditingValue(
          text: '13',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(res.text, '1');
    });

    test('Allows typing year after month', () {
      final res1 = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '12/',
          selection: TextSelection.collapsed(offset: 3),
        ),
        const TextEditingValue(
          text: '12/2',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(res1.text, '12/2');

      final res2 = formatter.formatEditUpdate(
        res1,
        const TextEditingValue(
          text: '12/28',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      expect(res2.text, '12/28');
    });

    test('Blocks more than 2 digits for year', () {
      const oldVal = TextEditingValue(
        text: '12/28',
        selection: TextSelection.collapsed(offset: 5),
      );
      final res = formatter.formatEditUpdate(
        oldVal,
        const TextEditingValue(
          text: '12/289',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      expect(res.text, '12/28');
    });

    test('Deleting across slash works smoothly', () {
      const oldVal = TextEditingValue(
        text: '12/',
        selection: TextSelection.collapsed(offset: 3),
      );
      final res = formatter.formatEditUpdate(
        oldVal,
        const TextEditingValue(
          text: '12',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(res.text, '1');
      expect(res.selection.baseOffset, 1);
    });
  });

  group('Manage Card Screen Expiration Date UI Tests', () {
    const testCard = PaymentMethod(
      id: 'test-card-1',
      type: PaymentMethodType.card,
      brand: 'Visa',
      last4: '4242',
      holderName: 'John Doe',
      expiryMonth: '12',
      expiryYear: '28',
      isDefault: false,
    );

    testWidgets('Manage Card displays expiration date and card mock',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(
        home: EditCardScreen(card: testCard),
      ));

      expect(find.text('Manage Card'), findsOneWidget);
      expect(find.text('12/28'), findsWidgets);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Empty expiration date displays error below field on Save',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(
        home: EditCardScreen(card: testCard),
      ));

      final expiryFinder = find.widgetWithText(RoadMateTextField, 'Expiration Date');
      expect(expiryFinder, findsOneWidget);

      final textField = find.descendant(
        of: expiryFinder,
        matching: find.byType(TextField),
      );

      await tester.enterText(textField, '');
      await tester.pumpAndSettle();

      final saveBtn = find.text('Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid expiration date (MM/YY)'),
        findsOneWidget,
      );
      // User stays on screen
      expect(find.text('Manage Card'), findsOneWidget);
    });

    testWidgets('Expired date displays "Card has expired" on Save',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(
        home: EditCardScreen(card: testCard),
      ));

      final expiryFinder = find.widgetWithText(RoadMateTextField, 'Expiration Date');
      final textField = find.descendant(
        of: expiryFinder,
        matching: find.byType(TextField),
      );

      // Past date: 01/20
      await tester.enterText(textField, '01/20');
      await tester.pumpAndSettle();

      final saveBtn = find.text('Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Card has expired'), findsOneWidget);
      expect(find.text('Manage Card'), findsOneWidget);
    });

    testWidgets('Valid future date (12/27) clears error and saves successfully',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(
        home: EditCardScreen(card: testCard),
      ));

      final expiryFinder = find.widgetWithText(RoadMateTextField, 'Expiration Date');
      final textField = find.descendant(
        of: expiryFinder,
        matching: find.byType(TextField),
      );

      // Enter valid 12/27
      await tester.enterText(textField, '12/27');
      await tester.pumpAndSettle();

      expect(find.text('12/27'), findsWidgets);

      final saveBtn = find.text('Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Card details updated successfully'), findsOneWidget);
    });
  });

  group('Add Card Screen Expiration Date UI Tests', () {
    testWidgets('AddCardScreen validates expiration date on submit',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(
        home: AddCardScreen(),
      ));

      final expiryFinder = find.widgetWithText(RoadMateTextField, 'Expires End');
      expect(expiryFinder, findsOneWidget);

      final textField = find.descendant(
        of: expiryFinder,
        matching: find.byType(TextField),
      );

      // Enter expired date
      await tester.enterText(textField, '09/26');
      await tester.pumpAndSettle();

      final saveBtn = find.text('Save Card Securely');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Card has expired'), findsOneWidget);
    });
  });
}

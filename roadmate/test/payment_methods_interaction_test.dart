import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/screens/payment_methods_screen.dart';

void main() {
  group('Payment Methods Screen Interaction Tests', () {
    testWidgets('Tapping RoadMate In-App Wallet card selects it as default',
        (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: PaymentMethodsScreen()));
      await tester.pumpAndSettle();

      // Find Wallet card
      final walletTitle = find.text('RoadMate In-App Wallet');
      expect(walletTitle, findsOneWidget);

      // Tap anywhere on the wallet card
      await tester.tap(walletTitle);
      await tester.pumpAndSettle();

      // SnackBar feedback should appear
      expect(
        find.text('RoadMate In-App Wallet set as default payment method'),
        findsOneWidget,
      );

      // Bottom sheet with wallet balance should appear
      expect(find.text('AVAILABLE BALANCE'), findsOneWidget);
      expect(find.text('Rs. 2,450.00'), findsOneWidget);

      // Wallet should now have Default badge and checkmark
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping Cash on Service card selects it as default',
        (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: PaymentMethodsScreen()));
      await tester.pumpAndSettle();

      // Find Cash on Service card
      final cashTitle = find.text('Cash on Service');
      expect(cashTitle, findsOneWidget);

      // Tap on the subtitle of Cash card
      final cashSubtitle = find.text('Pay directly to patrol specialist');
      expect(cashSubtitle, findsOneWidget);
      await tester.tap(cashSubtitle);
      await tester.pumpAndSettle();

      // SnackBar feedback should appear
      expect(
        find.text('Cash on Service set as default payment method'),
        findsOneWidget,
      );

      // Bottom sheet with cash policy should appear
      expect(find.text('CASH PAYMENT POLICY'), findsOneWidget);

      // Cash should now have Default badge and checkmark
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping arrow icon on card also triggers payment selection',
        (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: PaymentMethodsScreen()));
      await tester.pumpAndSettle();

      // Tap on chevron right icon
      final chevrons = find.byIcon(Icons.chevron_right_rounded);
      expect(chevrons, findsWidgets);
      await tester.tap(chevrons.first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    for (final width in [320.0, 360.0, 375.0, 400.0]) {
      testWidgets('Renders and interacts with zero overflow at ${width.toInt()}px width',
          (tester) async {
        tester.view.physicalSize = Size(width, 750);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: PaymentMethodsScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Other Payment Methods'), findsOneWidget);
        expect(find.text('RoadMate In-App Wallet'), findsOneWidget);
        expect(find.text('Cash on Service'), findsOneWidget);

        await tester.tap(find.text('RoadMate In-App Wallet'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });
}

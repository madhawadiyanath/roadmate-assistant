import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/screens/service_charges_screen.dart';
import 'package:roadmate/widgets/payment_widgets.dart';

void main() {
  group('Service Charges Screen Layout and Overflow Tests', () {
    testWidgets('Renders cleanly on standard 390px mobile width (iPhone 14)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ServiceChargesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Pricing & Service Charges'), findsOneWidget);
      expect(find.text('Estimated Total'), findsOneWidget);
      expect(find.text('Final price confirmed upon service completion'),
          findsOneWidget);
      expect(find.byType(AmountDisplay), findsOneWidget);
      expect(find.text('Pricing Policy'), findsOneWidget);
      expect(find.byType(RoadMatePrimaryButton), findsOneWidget);

      // Verify no exceptions or overflows were thrown during layout
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly on standard 360px mobile width (Android base)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ServiceChargesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Estimated Total'), findsOneWidget);
      expect(find.text('Final price confirmed upon service completion'),
          findsOneWidget);
      expect(find.byType(AmountDisplay), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly on ultra-narrow 320px mobile width (iPhone SE 1st gen)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ServiceChargesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Estimated Total'), findsOneWidget);
      expect(find.text('Final price confirmed upon service completion'),
          findsOneWidget);
      expect(find.byType(AmountDisplay), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Catalog item selection updates price and remains responsive',
        (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ServiceChargesScreen()));
      await tester.pumpAndSettle();

      // Scroll to catalog section
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Emergency Towing'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Base charge for Emergency Towing is 6500
      expect(find.text('Rs. 6,500.00'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/screens/driver_dashboard_screen.dart';
import 'package:roadmate/screens/service_charges_screen.dart';

void main() {
  const testDriver = AppUser(
    uid: 'driver-test-101',
    name: 'Nimal Bandara',
    email: 'nimal@example.com',
    role: AppRole.driver,
    phone: '0771234567',
  );

  group('RoadMate Payment Flow Integration Tests', () {
    testWidgets(
        'Full 4-Step Payment Flow: Pricing -> Make Payment -> Success -> Digital Receipt',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ServiceChargesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Pricing & Service Charges Screen
      expect(find.text('Pricing & Service Charges'), findsOneWidget);
      expect(find.text('Guaranteed Standard Rates'), findsOneWidget);
      expect(find.text('Estimated Charge Breakdown'), findsOneWidget);
      expect(find.text('RoadMate Standard Rates'), findsOneWidget);

      // Select Battery Jumpstart from catalog
      await tester.ensureVisible(find.text('Battery Jumpstart'));
      await tester.tap(find.text('Battery Jumpstart'));
      await tester.pumpAndSettle();

      // Tap Proceed to Payment
      final proceedBtn = find.textContaining('Proceed to Payment');
      expect(proceedBtn, findsOneWidget);
      await tester.ensureVisible(proceedBtn);
      await tester.tap(proceedBtn);
      await tester.pumpAndSettle();

      // Step 2: Make Payment Screen
      expect(find.text('Make Payment'), findsOneWidget);
      expect(find.text('Charge Breakdown'), findsOneWidget);
      expect(find.text('Select Payment Method'), findsOneWidget);

      // Verify Pay button exists
      final payBtn = find.textContaining('Pay Rs.');
      expect(payBtn, findsOneWidget);

      // Tap Pay and complete simulated payment
      await tester.ensureVisible(payBtn);
      await tester.tap(payBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Step 3: Payment Confirmation Screen
      expect(find.text('Payment Completed!'), findsOneWidget);
      expect(find.text('View Digital Receipt'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);

      // Tap View Digital Receipt
      final viewReceiptBtn = find.text('View Digital Receipt');
      await tester.ensureVisible(viewReceiptBtn);
      await tester.tap(viewReceiptBtn);
      await tester.pumpAndSettle();

      // Step 4: Digital Receipt Screen
      expect(find.text('Digital Receipt'), findsOneWidget);
      expect(find.text('Download PDF'), findsOneWidget);
      expect(find.text('Share Receipt'), findsOneWidget);
      expect(find.text('Close Receipt'), findsOneWidget);

      // Tap Download PDF - verify SnackBar appears
      final downloadBtn = find.text('Download PDF');
      await tester.ensureVisible(downloadBtn);
      await tester.tap(downloadBtn);
      await tester.pump();
      expect(find.text('Receipt downloaded successfully to your device'),
          findsOneWidget);

      // Tap Close Receipt - returns to PaymentConfirmationScreen
      final closeBtn = find.text('Close Receipt');
      await tester.ensureVisible(closeBtn);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();
      expect(find.text('Payment Completed!'), findsOneWidget);
    });

    testWidgets('Driver Dashboard renders Standard Rates & Pricing banner',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(user: testDriver),
        ),
      );
      await tester.pumpAndSettle();

      // Look for the new Pricing banner
      final banner = find.text('Standard Rates & Pricing');
      expect(banner, findsOneWidget);
      expect(find.text('Guaranteed rates, charge breakdown & payment'),
          findsOneWidget);

      // Tap banner -> navigates to ServiceChargesScreen
      await tester.ensureVisible(banner);
      await tester.tap(banner);
      await tester.pumpAndSettle();

      expect(find.text('Pricing & Service Charges'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/payment_transaction.dart';
import 'package:roadmate/screens/digital_receipt_screen.dart';
import 'package:roadmate/widgets/payment_widgets.dart';

void main() {
  final longTx = PaymentTransaction(
    transactionId: 'TXN-984712039',
    jobId: 'RM-REQ-88219',
    serviceType: 'Tire Replacement & Repair',
    serviceProvider: 'Chaminda Silva Professional Services',
    serviceCharge: 12500,
    additionalCharges: 4500,
    platformFee: 500,
    totalAmount: 17500.0,
    paymentMethod: 'Commercial Bank Visa (•••• 4242)',
    status: TransactionStatus.completed,
  );

  group('Digital Receipt Screen Responsive & Overflow Tests', () {
    for (final width in [320.0, 360.0, 375.0, 390.0, 400.0]) {
      testWidgets('Renders with zero overflow at ${width.toInt()}px width',
          (tester) async {
        final height = width == 400.0 ? 642.0 : 800.0;
        tester.view.physicalSize = Size(width, height);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp(
          home: DigitalReceiptScreen(transaction: longTx),
        ));
        await tester.pumpAndSettle();

        // Verify key information is rendered and visible
        expect(find.text('Digital Receipt'), findsOneWidget);
        expect(find.text('RoadMate'), findsOneWidget);
        expect(find.text('INVOICE NUMBER'), findsOneWidget);
        expect(find.text('INV-984712039'), findsOneWidget);
        expect(find.text('Service Reference:'), findsOneWidget);
        expect(
          find.text('RM-REQ-88219 (Tire Replacement & Repair)'),
          findsOneWidget,
        );
        expect(find.text('TOTAL PAID'), findsOneWidget);
        expect(find.byType(AmountDisplay), findsOneWidget);
        expect(find.text('Download PDF'), findsOneWidget);
        expect(find.text('Share Receipt'), findsOneWidget);

        // Verify no RenderFlex or any other layout exceptions were thrown
        expect(tester.takeException(), isNull);
      });
    }
  });
}

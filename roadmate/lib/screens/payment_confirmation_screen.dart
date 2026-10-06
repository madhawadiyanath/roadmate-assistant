import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment_transaction.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/payment_widgets.dart';
import 'digital_receipt_screen.dart';

/// Payment Confirmation screen matching the Stitch design.
class PaymentConfirmationScreen extends StatelessWidget {
  final PaymentTransaction transaction;

  const PaymentConfirmationScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            RoadMateAppHeader(
              title: 'Payment Successful',
              showBack: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Success circle indicator
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.onTertiaryContainer.withAlpha(40),
                          width: 4,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: AppColors.successText,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Payment Completed!',
                      style: AppTypography.headlineMd(color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your roadside assistance has been successfully paid.',
                      style: AppTypography.bodyMd(
                          color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Amount card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppColors.surfaceContainerHigh),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'AMOUNT PAID',
                            style: AppTypography.labelSm(
                                color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 6),
                          AmountDisplay(
                            amount: transaction.totalAmount,
                            style: AppTypography.headlineXl(
                                color: AppColors.primary),
                          ),
                          const SizedBox(height: 8),
                          StatusBadge.completed(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Transaction details summary card
                    RoadMateCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Transaction ID',
                                  style: AppTypography.bodySm(
                                      color: AppColors.onSurfaceVariant)),
                              Row(
                                children: [
                                  Text(
                                    transaction.transactionId,
                                    style: AppTypography.labelMd(
                                        color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(
                                          text: transaction.transactionId));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Transaction ID copied to clipboard'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    child: const Icon(
                                      Icons.copy_rounded,
                                      size: 16,
                                      color: AppColors.slateText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(color: AppColors.divider, height: 18),
                          InfoRow(
                            label: 'Job ID',
                            value: transaction.jobId,
                          ),
                          const Divider(color: AppColors.divider, height: 18),
                          InfoRow(
                            label: 'Service',
                            value: transaction.serviceType,
                          ),
                          const Divider(color: AppColors.divider, height: 18),
                          InfoRow(
                            label: 'Technician',
                            value: transaction.serviceProvider,
                          ),
                          const Divider(color: AppColors.divider, height: 18),
                          InfoRow(
                            label: 'Payment Method',
                            value: transaction.paymentMethod,
                          ),
                          const Divider(color: AppColors.divider, height: 18),
                          InfoRow(
                            label: 'Date & Time',
                            value: transaction.date,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // View Receipt Action Button
                    RoadMatePrimaryButton(
                      label: 'View Digital Receipt',
                      icon: Icons.receipt_long_rounded,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DigitalReceiptScreen(
                              transaction: transaction,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Back to Home button
                    RoadMateSecondaryButton(
                      label: 'Back to Home',
                      icon: Icons.home_rounded,
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

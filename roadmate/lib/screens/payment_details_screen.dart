import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment_transaction.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/payment_widgets.dart';
import 'digital_receipt_screen.dart';

/// Payment / Transaction Details screen matching the Stitch design.
class PaymentDetailsScreen extends StatelessWidget {
  final PaymentTransaction transaction;

  const PaymentDetailsScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = transaction.status == TransactionStatus.completed;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            RoadMateAppHeader(
              title: 'Transaction Details',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount & Status Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.surfaceContainerHigh),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.successBg
                                  : AppColors.pendingBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.access_time_rounded,
                              color: isCompleted
                                  ? AppColors.successText
                                  : AppColors.pendingText,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'TOTAL PAID',
                            style: AppTypography.labelSm(
                                color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          AmountDisplay(
                            amount: transaction.totalAmount,
                            style: AppTypography.headlineXl(
                                color: AppColors.primary),
                          ),
                          const SizedBox(height: 8),
                          StatusBadge(
                            label: isCompleted ? 'Completed' : 'Pending',
                            bgColor: isCompleted
                                ? AppColors.successBg
                                : AppColors.pendingBg,
                            textColor: isCompleted
                                ? AppColors.successText
                                : AppColors.pendingText,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Identification details
                    SectionHeader(title: 'Transaction Info'),
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
                                          content: Text('Copied to clipboard'),
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
                          const Divider(color: AppColors.divider, height: 16),
                          InfoRow(
                            label: 'Job Reference ID',
                            value: transaction.jobId,
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          InfoRow(
                            label: 'Date & Time',
                            value: transaction.date,
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          InfoRow(
                            label: 'Payment Method',
                            value: transaction.paymentMethod,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Service & Provider details
                    SectionHeader(title: 'Service & Technician'),
                    RoadMateCard(
                      child: Column(
                        children: [
                          InfoRow(
                            label: 'Service Type',
                            value: transaction.serviceType,
                            bold: true,
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          InfoRow(
                            label: 'Assigned Mechanic',
                            value: transaction.serviceProvider,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Cost breakdown
                    SectionHeader(title: 'Itemized Breakdown'),
                    RoadMateCard(
                      child: Column(
                        children: [
                          InfoRow(
                            label: 'Base Service Charge',
                            value: formatCurrency(transaction.serviceCharge),
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          InfoRow(
                            label: 'Travel & Spare Parts Fee',
                            value:
                                formatCurrency(transaction.additionalCharges),
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Paid',
                                style: AppTypography.titleMd(
                                    color: AppColors.primary),
                              ),
                              AmountDisplay(
                                amount: transaction.totalAmount,
                                style: AppTypography.titleMd(
                                    color: AppColors.secondaryContainer),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Digital Receipt Button
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

                    // Need help / dispute button
                    RoadMateSecondaryButton(
                      label: 'Report an Issue with this Payment',
                      icon: Icons.support_agent_rounded,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Support request logged for this transaction.'),
                          ),
                        );
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

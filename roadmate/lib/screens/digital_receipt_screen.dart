import 'package:flutter/material.dart';
import '../models/payment_transaction.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/payment_widgets.dart';

/// Digital Receipt / Invoice screen matching the Stitch design.
class DigitalReceiptScreen extends StatelessWidget {
  final PaymentTransaction transaction;

  const DigitalReceiptScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final invoiceNumber = 'INV-${transaction.transactionId.replaceAll('TXN-', '')}';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            RoadMateAppHeader(
              title: 'Digital Receipt',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // Official Receipt Document Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(12),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brand Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.shield_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        'RoadMate',
                                        style: AppTypography.headlineSm(
                                            color: AppColors.primary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge.completed(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.divider, thickness: 1),
                          const SizedBox(height: 12),

                          // Invoice No & Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('INVOICE NUMBER',
                                        style: AppTypography.labelSm(
                                            color: AppColors.onSurfaceVariant)),
                                    const SizedBox(height: 2),
                                    Text(invoiceNumber,
                                        style: AppTypography.labelLg(
                                            color: AppColors.primary),
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('DATE ISSUED',
                                        style: AppTypography.labelSm(
                                            color: AppColors.onSurfaceVariant)),
                                    const SizedBox(height: 2),
                                    Text(transaction.date,
                                        style: AppTypography.labelLg(
                                            color: AppColors.primary),
                                        textAlign: TextAlign.end),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Billed To & Service Provider
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('BILLED TO',
                                        style: AppTypography.labelSm(
                                            color: AppColors.onSurfaceVariant)),
                                    const SizedBox(height: 4),
                                    Text('Nimal Perera',
                                        style: AppTypography.titleMd(
                                            color: AppColors.primary)),
                                    Text('+94 77 123 4567',
                                        style: AppTypography.bodySm(
                                            color: AppColors.slateText)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('PROVIDER',
                                        style: AppTypography.labelSm(
                                            color: AppColors.onSurfaceVariant)),
                                    const SizedBox(height: 4),
                                    Text(transaction.serviceProvider,
                                        style: AppTypography.titleMd(
                                            color: AppColors.primary),
                                        textAlign: TextAlign.end,
                                        softWrap: true),
                                    Text('Verified Tech',
                                        style: AppTypography.bodySm(
                                            color:
                                                AppColors.onTertiaryContainer),
                                        textAlign: TextAlign.end),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Job Reference
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth < 360) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Service Reference:',
                                          style: AppTypography.bodySm(
                                              color: AppColors.onSurfaceVariant)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${transaction.jobId} (${transaction.serviceType})',
                                        style: AppTypography.labelMd(
                                            color: AppColors.primary),
                                        softWrap: true,
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Service Reference:',
                                        style: AppTypography.bodySm(
                                            color: AppColors.onSurfaceVariant)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${transaction.jobId} (${transaction.serviceType})',
                                        style: AppTypography.labelMd(
                                            color: AppColors.primary),
                                        textAlign: TextAlign.end,
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Itemized Table
                          Text('ITEMIZED CHARGES',
                              style: AppTypography.labelSm(
                                  color: AppColors.onSurfaceVariant)),
                          const SizedBox(height: 10),
                          _receiptItem(transaction.serviceType, '1x Service',
                              transaction.serviceCharge),
                          const SizedBox(height: 8),
                          _receiptItem('Travel & Spare Parts Fee', 'On-site',
                              transaction.additionalCharges),
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.divider, thickness: 1),
                          const SizedBox(height: 12),

                          // Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'TOTAL PAID',
                                  style: AppTypography.headlineSm(
                                      color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: AmountDisplay(
                                    amount: transaction.totalAmount,
                                    style: AppTypography.headlineSm(
                                      color: AppColors.secondaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Payment Method Footnote
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('Paid via ${transaction.paymentMethod}',
                                    style: AppTypography.bodySm(
                                        color: AppColors.slateText),
                                    softWrap: true),
                              ),
                              const SizedBox(width: 8),
                              Text('Status: Successful',
                                  style: AppTypography.bodySm(
                                      color: AppColors.successText)),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Watermark / Barcode mock
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  height: 38,
                                  width: 220,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppColors.outlineVariant),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '║▌║▌║█│▌║▌║▌│█║▌║',
                                      style: TextStyle(
                                        fontSize: 20,
                                        letterSpacing: 3,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  transaction.transactionId,
                                  style: AppTypography.labelSm(
                                      color: AppColors.slateText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Download & Share Actions
                    Row(
                      children: [
                        Expanded(
                          child: RoadMatePrimaryButton(
                            label: 'Download PDF',
                            icon: Icons.download_rounded,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Receipt downloaded successfully to your device'),
                                  backgroundColor: AppColors.successText,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RoadMateSecondaryButton(
                            label: 'Share Receipt',
                            icon: Icons.share_rounded,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Sharing receipt via system share dialog'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Back / Close
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Close Receipt',
                          style: AppTypography.labelLg(
                              color: AppColors.slateText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptItem(String name, String sub, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: AppTypography.titleMd(color: AppColors.primary)),
              Text(sub,
                  style: AppTypography.bodySm(color: AppColors.slateText)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatCurrency(amount),
          style: AppTypography.titleMd(color: AppColors.primary),
        ),
      ],
    );
  }
}

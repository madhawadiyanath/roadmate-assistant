import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/earnings_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/payment_widgets.dart';

/// Earnings / Job Details screen matching the Stitch design.
class EarningsDetailsScreen extends StatelessWidget {
  final EarningsRecord record;

  const EarningsDetailsScreen({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final formattedDate = dateFormat.format(record.completedDate);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            RoadMateAppHeader(
              title: 'Earnings Details',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Net earnings header card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryContainer,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(40),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'NET EARNINGS',
                            style: AppTypography.labelSm(
                                color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          AmountDisplay(
                            amount: record.netEarnings,
                            style: AppTypography.headlineXl(
                                color: AppColors.tertiaryFixed),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.tertiaryFixed, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Deposited to Wallet',
                                  style: AppTypography.labelSm(
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Job Reference Information
                    SectionHeader(title: 'Job Information'),
                    RoadMateCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Job ID',
                                  style: AppTypography.bodySm(
                                      color: AppColors.onSurfaceVariant)),
                              Text(
                                record.jobId,
                                style: AppTypography.labelLg(
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Transaction ID',
                                  style: AppTypography.bodySm(
                                      color: AppColors.onSurfaceVariant)),
                              Row(
                                children: [
                                  Text(
                                    record.transactionId,
                                    style: AppTypography.labelMd(
                                        color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(
                                          text: record.transactionId));
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
                            label: 'Service Provided',
                            value: record.serviceType,
                            bold: true,
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          InfoRow(
                            label: 'Client Name',
                            value: record.customerName.isNotEmpty
                                ? record.customerName
                                : 'Assigned Driver',
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          InfoRow(
                            label: 'Completed Date',
                            value: formattedDate,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Earnings Breakdown
                    SectionHeader(title: 'Earnings Breakdown'),
                    RoadMateCard(
                      child: Column(
                        children: [
                          InfoRow(
                            label: 'Gross Service Charge',
                            value: formatCurrency(record.serviceCharge),
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          InfoRow(
                            label: 'Platform Commission (10%)',
                            value: '- ${formatCurrency(record.platformFee)}',
                            trailing: Text(
                              '- ${formatCurrency(record.platformFee)}',
                              style: AppTypography.titleMd(
                                  color: AppColors.error),
                              textAlign: TextAlign.end,
                            ),
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Net Provider Payout',
                                style: AppTypography.titleMd(
                                    color: AppColors.primary),
                              ),
                              AmountDisplay(
                                amount: record.netEarnings,
                                style: AppTypography.titleMd(
                                    color: AppColors.onTertiaryContainer),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payout settlement info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.surfaceContainerHigh),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payout Settled to Wallet',
                                  style: AppTypography.titleMd(
                                      color: AppColors.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Available for instant withdrawal to linked bank account.',
                                  style: AppTypography.bodySm(
                                      color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Back button
                    RoadMatePrimaryButton(
                      label: 'Back to Earnings',
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.pop(context),
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
}

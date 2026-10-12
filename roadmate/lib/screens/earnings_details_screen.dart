import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/earnings_record.dart';
import '../services/earnings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/payment_widgets.dart';

/// Earnings / Job Details screen matching the Stitch design
/// with full CRUD support (Read, Update note, Traceable Reversal, Draft delete).
class EarningsDetailsScreen extends StatefulWidget {
  final EarningsRecord record;
  final EarningsService? earningsService;

  const EarningsDetailsScreen({
    super.key,
    required this.record,
    this.earningsService,
  });

  @override
  State<EarningsDetailsScreen> createState() => _EarningsDetailsScreenState();
}

class _EarningsDetailsScreenState extends State<EarningsDetailsScreen> {
  late EarningsRecord _record;
  EarningsService get _service => widget.earningsService ?? EarningsService();

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  void _showEditNoteDialog() {
    final noteController = TextEditingController(text: _record.notes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded,
                color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text('Edit Memo / Notes',
                style: AppTypography.headlineSm(color: AppColors.primary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add internal tracking notes, client feedback, or job reference memos.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter notes here...',
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newNote = noteController.text.trim();
              Navigator.pop(ctx);

              final updated = _record.copyWith(notes: newNote);
              await _service.updateEarning(updated);

              if (mounted) {
                setState(() => _record = updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction notes updated successfully.'),
                    backgroundColor: AppColors.successText,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  void _showReversalDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.history_rounded,
                color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text('Request Reversal',
                style: AppTypography.headlineSm(color: AppColors.error)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial audit rule: Completed transactions cannot be deleted. A traceable reversal will deduct Rs. ${formatCurrency(_record.netEarnings)} from earnings totals.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            const Text(
              'Adjustment Reason *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'e.g. Customer refund, Duplicate payment correction...',
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide an adjustment reason.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);

              await _service.reverseEarning(
                transactionId: _record.transactionId,
                reason: reason,
              );

              if (mounted) {
                setState(() {
                  _record = _record.copyWith(
                    isReversed: true,
                    adjustmentReason: reason,
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Transaction ${_record.transactionId} reversed and excluded from earnings.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Reversal'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDraftDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Draft Earning?'),
        content: const Text(
            'This unverified draft earning record will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.deleteDraftEarning(_record.transactionId);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Draft record deleted.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final formattedDate = dateFormat.format(_record.completedDate);
    final isReversed = _record.isReversed;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning banner if reversed
                    if (isReversed) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFDC2626), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Transaction Reversed',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Reason: ${(_record.adjustmentReason != null && _record.adjustmentReason!.isNotEmpty) ? _record.adjustmentReason! : 'Authorized financial adjustment'}. Excluded from active earnings & balance.',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF991B1B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Net earnings header card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isReversed
                              ? [
                                  const Color(0xFF475569),
                                  const Color(0xFF334155),
                                ]
                              : [
                                  AppColors.primary,
                                  AppColors.primaryContainer,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isReversed
                                    ? Colors.black
                                    : AppColors.primary)
                                .withAlpha(40),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            isReversed ? 'REVERSED NET AMOUNT' : 'NET EARNINGS',
                            style: AppTypography.labelSm(
                                color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          AmountDisplay(
                            amount: _record.netEarnings,
                            style: AppTypography.headlineXl(
                              color: isReversed
                                  ? const Color(0xFFCBD5E1)
                                  : AppColors.tertiaryFixed,
                            ),
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
                                Icon(
                                  isReversed
                                      ? Icons.cancel_outlined
                                      : Icons.check_circle_rounded,
                                  color: isReversed
                                      ? const Color(0xFFFCA5A5)
                                      : AppColors.tertiaryFixed,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isReversed
                                      ? 'Reversed & Deducted'
                                      : 'Deposited to Wallet',
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
                                _record.jobId,
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
                                    _record.transactionId,
                                    style: AppTypography.labelMd(
                                        color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(
                                          text: _record.transactionId));
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
                            value: _record.serviceType,
                            bold: true,
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          InfoRow(
                            label: 'Client Name',
                            value: _record.customerName.isNotEmpty
                                ? _record.customerName
                                : 'Assigned Driver',
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          InfoRow(
                            label: 'Completed Date',
                            value: formattedDate,
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Memo / Notes',
                                      style: AppTypography.bodySm(
                                          color: AppColors.onSurfaceVariant)),
                                  const SizedBox(height: 2),
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      _record.notes.isNotEmpty
                                          ? _record.notes
                                          : 'No notes added',
                                      style: AppTypography.bodySm(
                                          color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _showEditNoteDialog,
                                icon: const Icon(Icons.edit_outlined, size: 14),
                                label: const Text('Edit Note'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
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
                            value: formatCurrency(_record.serviceCharge),
                          ),
                          const Divider(color: AppColors.divider, height: 16),
                          InfoRow(
                            label: 'Platform Commission (10%)',
                            value: '- ${formatCurrency(_record.platformFee)}',
                            trailing: Text(
                              '- ${formatCurrency(_record.platformFee)}',
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
                                amount: _record.netEarnings,
                                style: AppTypography.titleMd(
                                    color: isReversed
                                        ? AppColors.error
                                        : AppColors.onTertiaryContainer),
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
                              color: isReversed
                                  ? const Color(0xFF64748B)
                                  : AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isReversed
                                  ? Icons.do_not_disturb_on_rounded
                                  : Icons.account_balance_wallet_rounded,
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
                                  isReversed
                                      ? 'Settlement Reversed'
                                      : 'Payout Settled to Wallet',
                                  style: AppTypography.titleMd(
                                      color: AppColors.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isReversed
                                      ? 'Adjustment recorded in accounting ledger.'
                                      : 'Available for instant withdrawal to linked bank account.',
                                  style: AppTypography.bodySm(
                                      color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Traceable Reversal / Draft Action Buttons
                    if (!isReversed && _record.isCompleted)
                      OutlinedButton.icon(
                        onPressed: _showReversalDialog,
                        icon: const Icon(Icons.history_toggle_off_rounded,
                            size: 18, color: AppColors.error),
                        label: const Text('Request Traceable Reversal'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    else if (!_record.isCompleted)
                      OutlinedButton.icon(
                        onPressed: _showDeleteDraftDialog,
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                        label: const Text('Delete Draft Earning'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    const SizedBox(height: 16),

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

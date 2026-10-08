import 'package:flutter/material.dart';

import '../config/firebase_state.dart';
import '../models/payments.dart';
import '../services/payment_service.dart';
import '../theme/app_colors.dart';
import 'receipt_screen.dart';

/// Transaction history. [mode] decides whose side is shown:
/// payer (driver), payee (mechanic income) or all (admin).
enum TxnMode { payer, payee, all }

class TransactionsScreen extends StatelessWidget {
  final String uid;
  final TxnMode mode;
  final PaymentService? paymentService;
  const TransactionsScreen({
    super.key,
    required this.uid,
    required this.mode,
    this.paymentService,
  });

  String get _title => switch (mode) {
        TxnMode.payer => 'Payment History',
        TxnMode.payee => 'Income History',
        TxnMode.all => 'Transaction History',
      };

  Stream<List<TxnRecord>> _stream(PaymentService pay) => switch (mode) {
        TxnMode.payer => pay.watchPayerTransactions(uid),
        TxnMode.payee => pay.watchPayeeTransactions(uid),
        TxnMode.all => pay.watchAllTransactions(),
      };

  @override
  Widget build(BuildContext context) {
    final pay = paymentService ?? PaymentService();
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        foregroundColor: AppColors.navy,
        title: Text(
          _title,
          style: const TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
      ),
      body: !firebaseReady
          ? const Center(
              child: Text(
                'Connect Firebase to view history.',
                style: TextStyle(color: AppColors.greyText),
              ),
            )
          : StreamBuilder<List<TxnRecord>>(
              stream: _stream(pay),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Could not load.\n${snap.error}'));
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No transactions yet.',
                      style: TextStyle(
                          color: AppColors.greyText, fontSize: 13),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _TxnRow(
                    txn: items[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReceiptScreen(record: items[i]),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  final TxnRecord txn;
  final VoidCallback onTap;
  const _TxnRow({required this.txn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final paid = txn.isPaid;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (paid
                        ? const Color(0xFF22B573)
                        : AppColors.orange)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                paid
                    ? Icons.check_circle_outline_rounded
                    : Icons.schedule_outlined,
                color: paid
                    ? const Color(0xFF22B573)
                    : AppColors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${txn.type} • ${txn.refCode}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  Text(
                    '${txn.method} • ${paid ? 'Paid' : 'Pending'}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Rs. ${txn.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

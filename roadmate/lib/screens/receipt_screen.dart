import 'package:flutter/material.dart';

import '../models/payments.dart';
import '../theme/app_colors.dart';

/// Digital receipt / invoice for one transaction.
class ReceiptScreen extends StatelessWidget {
  final TxnRecord record;
  const ReceiptScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final r = record;
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        foregroundColor: AppColors.navy,
        title: const Text(
          'Receipt',
          style:
              TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: const Color(0xFFEDF1F7), width: 1.2),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_rounded,
                          size: 22, color: AppColors.navy),
                      SizedBox(width: 6),
                      Text(
                        'RoadMate',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: r.isPaid
                          ? const Color(0xFFE6F7EE)
                          : const Color(0xFFFFEDE0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      r.isPaid ? 'PAID' : 'PENDING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: r.isPaid
                            ? const Color(0xFF22B573)
                            : AppColors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rs. ${r.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const Divider(height: 28, color: Color(0xFFEDF1F7)),
                  _line('Request', r.refCode.isEmpty ? '—' : r.refCode),
                  _line('Service', r.type.isEmpty ? '—' : r.type),
                  _line('Paid by', r.payerName.isEmpty ? '—' : r.payerName),
                  if (r.payeeName.isNotEmpty)
                    _line('Mechanic', r.payeeName),
                  _line('Method', r.method.isEmpty ? '—' : r.method),
                  _line('Date', _date(r.createdAt)),
                  if (r.items.isNotEmpty) ...[
                    const Divider(height: 24, color: Color(0xFFEDF1F7)),
                    for (final item in r.items)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.label,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.greyText,
                                ),
                              ),
                            ),
                            Text(
                              'Rs. ${item.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Taxes & toll included • support@roadmate.lk',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppColors.greyText),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.greyText),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour < 12 ? 'AM' : 'PM';
    return '${d.day} ${months[d.month - 1]} ${d.year}, $h:${d.minute.toString().padLeft(2, '0')} $ap';
  }
}

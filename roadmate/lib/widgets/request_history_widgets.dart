import 'package:flutter/material.dart';

import '../models/service_request.dart';
import '../theme/app_colors.dart';
import 'rating_widgets.dart';

const _lineColor = Color(0xFFE3E8F5);
const _iconBg = Color(0xFFEEF2FF);

/// "Today · 9:12 AM" or "28 Sep 2026 · 6:40 PM". Null = just created
/// (server timestamp not resolved yet).
String requestDateTimeLabel(DateTime? t, {DateTime? now}) {
  if (t == null) return 'Just now';
  final n = now ?? DateTime.now();
  final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final clock =
      '$hour12:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
  if (t.year == n.year && t.month == n.month && t.day == n.day) {
    return 'Today · $clock';
  }
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${t.day} ${months[t.month - 1]} ${t.year} · $clock';
}

/// 3500 → "3,500.00" (or "3,500" with [decimals] 0).
String formatAmount(double v, {int decimals = 2}) {
  final fixed = v.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return parts.length > 1 ? '$whole.${parts[1]}' : whole;
}

/// Right-hand cost text: final fee when completed, estimate while the job
/// is open, "No charge" when cancelled.
String requestCostLabel(ServiceRequest r) {
  switch (r.status) {
    case RequestStatus.cancelled:
      return 'No charge';
    case RequestStatus.completed:
      return 'Rs. ${formatAmount(r.totalFee)}';
    case RequestStatus.pending:
    case RequestStatus.accepted:
    case RequestStatus.onTheWay:
      return r.totalFee > 0
          ? 'Est. Rs. ${formatAmount(r.totalFee, decimals: 0)}'
          : 'Fee on completion';
  }
}

IconData assistanceIcon(AssistanceType t) {
  switch (t) {
    case AssistanceType.flatTyre:
      return Icons.tire_repair_rounded;
    case AssistanceType.jumpStart:
      return Icons.bolt_rounded;
    case AssistanceType.fuelDrop:
      return Icons.local_gas_station_rounded;
    case AssistanceType.towing:
      return Icons.local_shipping_outlined;
    case AssistanceType.general:
      return Icons.build_outlined;
  }
}

({String label, Color fg, Color bg}) _badge(RequestStatus s) {
  switch (s) {
    case RequestStatus.completed:
      return (
        label: 'Completed',
        fg: const Color(0xFF1C8C5A),
        bg: const Color(0xFFE6F7EE)
      );
    case RequestStatus.cancelled:
      return (
        label: 'Cancelled',
        fg: const Color(0xFFE5484D),
        bg: const Color(0xFFFDE8E8)
      );
    case RequestStatus.pending:
      return (
        label: 'Pending',
        fg: const Color(0xFFB45A06),
        bg: AppColors.peachBg
      );
    case RequestStatus.accepted:
    case RequestStatus.onTheWay:
      return (
        label: 'In Progress',
        fg: const Color(0xFFB45A06),
        bg: AppColors.peachBg
      );
  }
}

/// Small coloured status pill ("Completed", "In Progress", ...).
class RequestStatusBadge extends StatelessWidget {
  final RequestStatus status;
  const RequestStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final b = _badge(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
      decoration: BoxDecoration(
        color: b.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        b.label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: b.fg,
        ),
      ),
    );
  }
}

/// One history entry: service icon, title, date/time, request id on the
/// left; status badge and cost on the right. Completed requests also show
/// the driver's stars, or a "Rate this service" action while unrated.
class RequestHistoryCard extends StatelessWidget {
  final ServiceRequest request;
  final VoidCallback? onTap;

  /// Opens the rating screen; the action is hidden when null.
  final VoidCallback? onRate;
  final DateTime? now;

  const RequestHistoryCard({
    super.key,
    required this.request,
    this.onTap,
    this.onRate,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final r = request;
    final completed = r.status == RequestStatus.completed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _lineColor, width: 1.2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: _iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(assistanceIcon(r.type),
                          color: AppColors.navy, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.type.label,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            requestDateTimeLabel(r.createdAt, now: now),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.navyDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.refCode,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RequestStatusBadge(status: r.status),
                        const SizedBox(height: 10),
                        Text(
                          requestCostLabel(r),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (completed && r.isRated) ...[
                  const Divider(height: 22, color: _lineColor),
                  Row(
                    children: [
                      const Text(
                        'Your rating',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.greyText,
                        ),
                      ),
                      const Spacer(),
                      StarRow(rating: r.rating, size: 20),
                    ],
                  ),
                ] else if (completed && onRate != null) ...[
                  const Divider(height: 22, color: _lineColor),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: onRate,
                      icon: const Icon(Icons.star_outline_rounded, size: 20),
                      label: const Text(
                        'Rate this service',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.orange,
                        side: const BorderSide(color: AppColors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter pill with a count bubble: "All 5".
class RequestFilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const RequestFilterTab({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.fieldFill,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.navy,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.navyDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

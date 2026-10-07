import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One slice of a [DonutChart].
class DonutSegment {
  final String label;
  final int value;
  final Color color;
  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Donut chart with legend. Drawn with CustomPaint (no extra deps).
class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final String centerLabel;
  const DonutChart({
    super.key,
    required this.segments,
    this.centerLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (s, e) => s + e.value);
    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _DonutPainter(segments: segments, total: total),
            child: Center(
              child: Text(
                centerLabel.isEmpty ? '$total' : centerLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              for (final s in segments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.label,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ),
                      Text(
                        '${s.value}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final int total;
  _DonutPainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    if (total <= 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFFEDF1F7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18,
      );
      return;
    }
    double start = -math.pi / 2;
    for (final s in segments) {
      if (s.value <= 0) continue;
      final sweep = (s.value / total) * math.pi * 2;
      // Small gap between slices.
      const gap = 0.04;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start + gap / 2,
        math.max(0, sweep - gap),
        false,
        Paint()
          ..color = s.color
          ..strokeWidth = 18
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments || old.total != total;
}

/// 7-day bar chart. [values] oldest → newest (7 entries).
class WeeklyBars extends StatelessWidget {
  final List<int> values;
  const WeeklyBars({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    assert(values.length == 7);
    final maxV = values.fold<int>(1, math.max);
    final days = _last7DayLetters();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < 7; i++)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${values[i]}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greyText,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 90 * (values[i] / maxV) + 6,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: i == 6
                        ? AppColors.orange
                        : AppColors.navy.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  days[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        i == 6 ? FontWeight.w800 : FontWeight.w500,
                    color: i == 6
                        ? AppColors.navy
                        : AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static List<String> _last7DayLetters() {
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday; // 1 = Monday
    return List.generate(7, (i) {
      final d = ((today - 7 + i) % 7 + 7) % 7; // 0-based from Monday
      return letters[d];
    });
  }
}

/// Horizontal breakdown bars (label + fraction + count).
class TypeBars extends StatelessWidget {
  final List<DonutSegment> segments;
  const TypeBars({super.key, required this.segments});

  @override
  Widget build(BuildContext context) {
    final maxV = segments.fold<int>(1, (m, s) => math.max(m, s.value));
    return Column(
      children: [
        for (final s in segments)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 108,
                  child: Text(
                    s.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: maxV == 0 ? 0 : s.value / maxV,
                      minHeight: 10,
                      backgroundColor: AppColors.fieldFill,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(s.color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 26,
                  child: Text(
                    '${s.value}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// White card wrapper for one analytics block.
class AnalyticsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const AnalyticsCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
            ),
          ),
          Text(
            subtitle,
            style:
                const TextStyle(fontSize: 12, color: AppColors.greyText),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

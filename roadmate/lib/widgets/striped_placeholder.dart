import 'package:flutter/material.dart';

/// Diagonal-striped stand-in for photos (matches the Figma "profile photo" /
/// "vehicle photo" placeholders). Used until image upload exists.
class StripedPlaceholder extends StatelessWidget {
  final String label;
  final double? width;
  final double? height;
  final bool circle;
  final BorderRadius? borderRadius;

  const StripedPlaceholder({
    super.key,
    required this.label,
    this.width,
    this.height,
    this.circle = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final child = CustomPaint(
      painter: const _StripePainter(),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Color(0xFF6B7899),
          ),
        ),
      ),
    );
    final box = SizedBox(width: width, height: height, child: child);
    if (circle) return ClipOval(child: box);
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: box,
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEAEEFC),
    );
    final stripe = Paint()
      ..color = const Color(0xFFDCE3F9)
      ..strokeWidth = 9;
    const gap = 22.0;
    for (var x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(
          Offset(x, size.height), Offset(x + size.height, 0), stripe);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

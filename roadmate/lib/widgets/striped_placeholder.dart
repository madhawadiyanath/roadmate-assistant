import 'package:flutter/material.dart';

/// Diagonal-striped stand-in for a photo, with a small monospace caption
/// ("vehicle photo"). Used wherever an image isn't uploaded yet.
class StripedPlaceholder extends StatelessWidget {
  final String label;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final bool circle;

  const StripedPlaceholder({
    super.key,
    this.label = 'photo',
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = CustomPaint(
      painter: const _StripePainter(),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Color(0xFF5A6788),
            ),
          ),
        ),
      ),
    );
    return circle
        ? ClipOval(child: body)
        : ClipRRect(borderRadius: borderRadius, child: body);
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  static const _base = Color(0xFFECF0FD);
  static const _stripe = Color(0xFFDCE3FA);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _base);
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()
      ..color = _stripe
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    const gap = 16.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';

/// Stylised map card (no API key needed): blocks, highways, streets,
/// road labels and a centre pin. Swap with google_maps_flutter later.
class MiniMapIllustration extends StatelessWidget {
  const MiniMapIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniMapPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, w, h, const Radius.circular(16)),
      Paint()..color = const Color(0xFFE4EBE0),
    );

    // City blocks
    final block = Paint()..color = const Color(0xFFF1F4EE);
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.05, h * 0.06, w * 0.42, h * 0.38,
          const Radius.circular(8)),
      block,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.58, h * 0.06, w * 0.95, h * 0.32,
          const Radius.circular(8)),
      block,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.05, h * 0.62, w * 0.40, h * 0.94,
          const Radius.circular(8)),
      block,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.60, h * 0.60, w * 0.95, h * 0.94,
          const Radius.circular(8)),
      block,
    );
    // Park patch
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.46, h * 0.66, w * 0.56, h * 0.90,
          const Radius.circular(6)),
      Paint()..color = const Color(0xFFCDE6C5),
    );

    // Highways (orange) — curved expressway across the top
    final hwy = Paint()
      ..color = const Color(0xFFF5A623)
      ..strokeWidth = h * 0.055
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final hwyInner = Paint()
      ..color = const Color(0xFFFFD98A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final top = Path()
      ..moveTo(-w * 0.05, h * 0.30)
      ..quadraticBezierTo(w * 0.45, h * 0.22, w * 1.05, h * 0.28);
    canvas.drawPath(top, hwy);
    final lower = Path()
      ..moveTo(-w * 0.05, h * 0.52)
      ..quadraticBezierTo(w * 0.50, h * 0.46, w * 1.05, h * 0.50);
    canvas.drawPath(lower, hwy);
    // dashes
    for (final p in [top, lower]) {
      final m = p.computeMetrics().first;
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(
            m.extractPath(d, (d + 6).clamp(0, m.length)), hwyInner);
        d += 14;
      }
    }

    // Streets (white)
    final street = Paint()
      ..color = Colors.white
      ..strokeWidth = h * 0.035
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(w * 0.48, 0), Offset(w * 0.48, h), street); // vertical Main Ave
    canvas.drawLine(Offset(0, h * 0.44), Offset(w, h * 0.40),
        street..strokeWidth = h * 0.028);

    // Road labels
    void label(String t, double x, double y, double rot) {
      final tp = TextPainter(
        text: TextSpan(
          text: t,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: const Color(0xFF8A8F7A).withValues(alpha: 0.9),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(w * x, h * y);
      canvas.rotate(rot);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    label('GRAND EXPRESSWAY', 0.30, 0.25, -0.06);
    label('MAIN AVE', 0.52, 0.60, 1.5708);
    label('HIGH STREET', 0.30, 0.485, -0.03);

    // Centre pin glow + pin
    final c = Offset(w * 0.5, h * 0.44);
    canvas.drawCircle(c, w * 0.075, Paint()..color = Colors.red.withValues(alpha: 0.15));
    final pin = Paint()..color = const Color(0xFFE53935);
    canvas.drawCircle(Offset(c.dx, c.dy - h * 0.045), w * 0.045, pin);
    final tip = Path()
      ..moveTo(c.dx - w * 0.038, c.dy - h * 0.03)
      ..lineTo(c.dx, c.dy + h * 0.02)
      ..lineTo(c.dx + w * 0.038, c.dy - h * 0.03)
      ..close();
    canvas.drawPath(tip, pin);
    canvas.drawCircle(Offset(c.dx, c.dy - h * 0.045), w * 0.018, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

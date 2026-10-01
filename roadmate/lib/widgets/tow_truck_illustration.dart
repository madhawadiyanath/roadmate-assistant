import 'package:flutter/material.dart';

/// Small flat-style tow truck for the driver dashboard hero card.
class TowTruckIllustration extends StatelessWidget {
  const TowTruckIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TowTruckPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _TowTruckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final navy = Paint()..color = const Color(0xFF0A2A66);
    final orange = Paint()..color = const Color(0xFFFF8A1E);
    final lightOrange = Paint()..color = const Color(0xFFFFC37A);
    final glass = Paint()..color = const Color(0xFFBFD4F2);
    final tyre = Paint()..color = const Color(0xFF1A2340);
    final hub = Paint()..color = const Color(0xFFB9C4D6);

    final bedY = h * 0.52;

    // Flatbed
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.06, bedY, w * 0.62, bedY + h * 0.10,
          const Radius.circular(3)),
      orange,
    );
    // Bed stripes
    canvas.drawRect(
      Rect.fromLTWH(w * 0.10, bedY + h * 0.035, w * 0.48, h * 0.02),
      lightOrange,
    );

    // Crane arm
    canvas.drawLine(
      Offset(w * 0.58, bedY),
      Offset(w * 0.78, h * 0.18),
      Paint()
        ..color = const Color(0xFF0A2A66)
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round,
    );
    // Hook cable
    canvas.drawLine(
      Offset(w * 0.78, h * 0.18),
      Offset(w * 0.78, h * 0.34),
      Paint()
        ..color = const Color(0xFF0A2A66)
        ..strokeWidth = 2,
    );
    // Hook
    canvas.drawCircle(Offset(w * 0.78, h * 0.37), w * 0.025, orange);

    // Beacon light
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.68, h * 0.40, w * 0.76, h * 0.46,
          const Radius.circular(3)),
      orange,
    );
    canvas.drawCircle(
      Offset(w * 0.72, h * 0.375),
      w * 0.028,
      Paint()..color = const Color(0xFFFFD23C),
    );

    // Cab
    final cab = Path()
      ..moveTo(w * 0.60, bedY + h * 0.10)
      ..lineTo(w * 0.60, h * 0.46)
      ..quadraticBezierTo(w * 0.60, h * 0.42, w * 0.64, h * 0.42)
      ..lineTo(w * 0.76, h * 0.42)
      ..quadraticBezierTo(w * 0.84, h * 0.42, w * 0.87, h * 0.52)
      ..lineTo(w * 0.90, bedY + h * 0.08)
      ..lineTo(w * 0.90, bedY + h * 0.10)
      ..close();
    canvas.drawPath(cab, navy);
    // Windshield
    final shield = Path()
      ..moveTo(w * 0.64, h * 0.50)
      ..lineTo(w * 0.64, h * 0.46)
      ..lineTo(w * 0.75, h * 0.46)
      ..quadraticBezierTo(w * 0.80, h * 0.46, w * 0.82, h * 0.52)
      ..lineTo(w * 0.80, h * 0.52)
      ..close();
    canvas.drawPath(shield, glass);
    // Headlight
    canvas.drawCircle(Offset(w * 0.885, bedY + h * 0.04), 3.5, lightOrange);

    // Chassis
    canvas.drawRect(
      Rect.fromLTWH(w * 0.08, bedY + h * 0.10, w * 0.82, h * 0.05),
      navy,
    );

    // Wheels
    void wheel(double cx) {
      canvas.drawCircle(Offset(w * cx, bedY + h * 0.20), w * 0.055, tyre);
      canvas.drawCircle(Offset(w * cx, bedY + h * 0.20), w * 0.026, hub);
    }

    wheel(0.22);
    wheel(0.42);
    wheel(0.76);

    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.48, bedY + h * 0.30),
        width: w * 0.85,
        height: h * 0.06,
      ),
      Paint()..color = const Color(0xFF0A2A66).withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

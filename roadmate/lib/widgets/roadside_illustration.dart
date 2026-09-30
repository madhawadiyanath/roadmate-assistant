import 'package:flutter/material.dart';

/// Illustration that mimics the screenshot:
/// blue car + kneeling mechanic + warning triangle + city + sun.
class RoadsideIllustration extends StatelessWidget {
  const RoadsideIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RoadsidePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _RoadsidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    final bgPaint = Paint()..color = const Color(0xFFF2F6FE);
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, w, h, const Radius.circular(20)),
      bgPaint,
    );

    // Sun
    final sunPaint = Paint()..color = const Color(0xFFFFEDCB);
    canvas.drawCircle(Offset(w * 0.52, h * 0.52), w * 0.34, sunPaint);
    final sunInner = Paint()..color = const Color(0xFFFFE3AC);
    canvas.drawCircle(Offset(w * 0.52, h * 0.54), w * 0.28, sunInner);

    // Buildings (behind)
    void building(double left, double top, double right, double bottom, Color c) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          w * left, h * top, w * right, h * bottom,
          const Radius.circular(2),
        ),
        Paint()..color = c,
      );
    }

    building(0.22, 0.30, 0.30, 0.62, const Color(0xFFF0D9B5));
    building(0.31, 0.36, 0.38, 0.62, const Color(0xFFDCE6F5));
    building(0.39, 0.28, 0.48, 0.62, const Color(0xFFD3E0F2));
    building(0.49, 0.34, 0.56, 0.62, const Color(0xFFF0D9B5));
    building(0.57, 0.30, 0.65, 0.62, const Color(0xFFDCE6F5));
    building(0.66, 0.38, 0.72, 0.62, const Color(0xFFF0D9B5));

    // windows on buildings
    final winPaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
    for (double bx in [0.41, 0.45, 0.59, 0.62]) {
      for (double by = 0.34; by < 0.58; by += 0.05) {
        canvas.drawRect(
          Rect.fromLTWH(w * bx, h * by, w * 0.02, h * 0.025),
          winPaint,
        );
      }
    }

    // Clouds
    void cloud(double cx, double cy, double s) {
      final p = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(w * cx, h * cy), s, p);
      canvas.drawCircle(Offset(w * cx + s * 0.9, h * cy + s * 0.15), s * 0.75, p);
      canvas.drawCircle(Offset(w * cx - s * 0.9, h * cy + s * 0.2), s * 0.65, p);
      canvas.drawRect(
        Rect.fromLTWH(w * cx - s, h * cy, s * 2, s * 0.7),
        p,
      );
    }

    cloud(0.32, 0.26, w * 0.045);
    cloud(0.58, 0.20, w * 0.035);

    final groundY = h * 0.70;

    // Ground line
    canvas.drawRect(
      Rect.fromLTWH(w * 0.08, groundY, w * 0.84, h * 0.015),
      Paint()..color = const Color(0xFFD7DEEA),
    );
    // Ground shadow under car
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.44, groundY + h * 0.05),
        width: w * 0.52,
        height: h * 0.05,
      ),
      Paint()..color = const Color(0xFFE2E8F3),
    );

    // ---- Car ----
    final carBody = Paint()..color = const Color(0xFF2F7DE1);
    final carDark = Paint()..color = const Color(0xFF1B4FB8);
    const carLightColor = Color(0xFF5EA0F2);

    // main body path
    final bodyPath = Path()
      ..moveTo(w * 0.16, groundY - h * 0.02)
      ..lineTo(w * 0.16, groundY - h * 0.10)
      ..quadraticBezierTo(w * 0.16, groundY - h * 0.125, w * 0.20, groundY - h * 0.13)
      ..lineTo(w * 0.32, groundY - h * 0.15)
      ..quadraticBezierTo(w * 0.40, groundY - h * 0.24, w * 0.50, groundY - h * 0.24)
      ..lineTo(w * 0.62, groundY - h * 0.24)
      ..quadraticBezierTo(w * 0.70, groundY - h * 0.23, w * 0.73, groundY - h * 0.15)
      ..lineTo(w * 0.74, groundY - h * 0.08)
      ..quadraticBezierTo(w * 0.74, groundY - h * 0.02, w * 0.68, groundY - h * 0.02)
      ..close();
    canvas.drawPath(bodyPath, carBody);

    // lower bumper darker
    final bumperPath = Path()
      ..moveTo(w * 0.16, groundY - h * 0.055)
      ..lineTo(w * 0.74, groundY - h * 0.055)
      ..lineTo(w * 0.74, groundY - h * 0.02)
      ..lineTo(w * 0.16, groundY - h * 0.02)
      ..close();
    canvas.drawPath(bumperPath, carDark);

    // windows
    final winPath = Path()
      ..moveTo(w * 0.35, groundY - h * 0.155)
      ..quadraticBezierTo(w * 0.41, groundY - h * 0.215, w * 0.49, groundY - h * 0.215)
      ..lineTo(w * 0.49, groundY - h * 0.155)
      ..close();
    canvas.drawPath(winPath, Paint()..color = const Color(0xFF0D2A5C));
    final winPath2 = Path()
      ..moveTo(w * 0.51, groundY - h * 0.215)
      ..lineTo(w * 0.61, groundY - h * 0.215)
      ..quadraticBezierTo(w * 0.66, groundY - h * 0.21, w * 0.68, groundY - h * 0.155)
      ..lineTo(w * 0.51, groundY - h * 0.155)
      ..close();
    canvas.drawPath(winPath2, Paint()..color = const Color(0xFF123A7A));
    // window shine
    canvas.drawLine(
      Offset(w * 0.38, groundY - h * 0.16),
      Offset(w * 0.42, groundY - h * 0.205),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 2,
    );

    // headlight
    canvas.drawRRect(
      RRect.fromLTRBR(
        w * 0.165, groundY - h * 0.115, w * 0.205, groundY - h * 0.095,
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFFF3C4),
    );
    // front spark
    final sparkPaint = Paint()
      ..color = const Color(0xFFFFC93C)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.135, groundY - h * 0.11),
        Offset(w * 0.115, groundY - h * 0.13), sparkPaint);
    canvas.drawLine(Offset(w * 0.135, groundY - h * 0.10),
        Offset(w * 0.112, groundY - h * 0.10), sparkPaint);
    canvas.drawLine(Offset(w * 0.135, groundY - h * 0.09),
        Offset(w * 0.115, groundY - h * 0.07), sparkPaint);

    // door line
    canvas.drawLine(
      Offset(w * 0.50, groundY - h * 0.155),
      Offset(w * 0.50, groundY - h * 0.03),
      Paint()
        ..color = const Color(0xFF1B4FB8)
        ..strokeWidth = 1.5,
    );
    // handle
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.53, groundY - h * 0.13, w * 0.58, groundY - h * 0.12,
          const Radius.circular(2)),
      Paint()..color = const Color(0xFF0D2A5C),
    );

    // wheels
    void wheel(double cx) {
      canvas.drawCircle(
        Offset(w * cx, groundY - h * 0.02),
        w * 0.055,
        Paint()..color = const Color(0xFF1A2340),
      );
      canvas.drawCircle(
        Offset(w * cx, groundY - h * 0.02),
        w * 0.028,
        Paint()..color = const Color(0xFFB9C4D6),
      );
      canvas.drawCircle(
        Offset(w * cx, groundY - h * 0.02),
        w * 0.012,
        Paint()..color = const Color(0xFF4A5878),
      );
    }

    wheel(0.26);
    wheel(0.62);
    // wheel arch highlight
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.26, groundY - h * 0.02),
          width: w * 0.13,
          height: w * 0.13),
      3.14, 3.14, false,
      Paint()
        ..color = carLightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.62, groundY - h * 0.02),
          width: w * 0.13,
          height: w * 0.13),
      3.14, 3.14, false,
      Paint()
        ..color = carLightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ---- Mechanic kneeling ----
    final skin = Paint()..color = const Color(0xFF2B5BA6);
    final shirtBlue = Paint()..color = const Color(0xFF1B4FB8);
    final pantsBlue = Paint()..color = const Color(0xFF274E9D);
    final vest = Paint()..color = const Color(0xFFFF8A1E);
    final shoe = Paint()..color = const Color(0xFF0D2A5C);

    // back leg kneeling (ground)
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.68, groundY - h * 0.015, w * 0.82, groundY + h * 0.015,
          const Radius.circular(6)),
      pantsBlue,
    );
    // shoe back
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.81, groundY - h * 0.03, w * 0.86, groundY + h * 0.01,
          const Radius.circular(4)),
      shoe,
    );
    // front leg bent
    final legPath = Path()
      ..moveTo(w * 0.66, groundY - h * 0.12)
      ..lineTo(w * 0.62, groundY - h * 0.015)
      ..lineTo(w * 0.70, groundY - h * 0.015)
      ..lineTo(w * 0.72, groundY - h * 0.10)
      ..close();
    canvas.drawPath(legPath, pantsBlue);
    // shoe front
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.60, groundY - h * 0.025, w * 0.67, groundY + h * 0.005,
          const Radius.circular(4)),
      shoe,
    );

    // torso
    final torsoPath = Path()
      ..moveTo(w * 0.665, groundY - h * 0.24)
      ..lineTo(w * 0.72, groundY - h * 0.22)
      ..lineTo(w * 0.70, groundY - h * 0.09)
      ..lineTo(w * 0.64, groundY - h * 0.10)
      ..close();
    canvas.drawPath(torsoPath, shirtBlue);

    // vest
    final vestPath = Path()
      ..moveTo(w * 0.668, groundY - h * 0.235)
      ..lineTo(w * 0.695, groundY - h * 0.24)
      ..lineTo(w * 0.69, groundY - h * 0.10)
      ..lineTo(w * 0.655, groundY - h * 0.105)
      ..close();
    canvas.drawPath(vestPath, vest);
    final vestPath2 = Path()
      ..moveTo(w * 0.70, groundY - h * 0.238)
      ..lineTo(w * 0.718, groundY - h * 0.22)
      ..lineTo(w * 0.705, groundY - h * 0.095)
      ..lineTo(w * 0.695, groundY - h * 0.10)
      ..close();
    canvas.drawPath(vestPath2, vest);
    // vest reflective stripe
    canvas.drawLine(
      Offset(w * 0.66, groundY - h * 0.155),
      Offset(w * 0.705, groundY - h * 0.15),
      Paint()
        ..color = const Color(0xFFFFE066)
        ..strokeWidth = 3,
    );

    // arm reaching to triangle
    canvas.drawLine(
      Offset(w * 0.675, groundY - h * 0.19),
      Offset(w * 0.63, groundY - h * 0.10),
      Paint()
        ..color = const Color(0xFF2B5BA6)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // head
    canvas.drawCircle(
      Offset(w * 0.69, groundY - h * 0.265),
      w * 0.03,
      skin,
    );
    // cap
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.69, groundY - h * 0.265),
          width: w * 0.075,
          height: w * 0.075),
      3.14, 3.14, false,
      Paint()..color = const Color(0xFF0D2A5C),
    );
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.66, groundY - h * 0.275, w * 0.705,
          groundY - h * 0.26, const Radius.circular(2)),
      Paint()..color = const Color(0xFF0D2A5C),
    );

    // ---- Warning triangle ----
    final triCenter = Offset(w * 0.57, groundY - h * 0.02);
    final triPath = Path()
      ..moveTo(triCenter.dx, triCenter.dy - h * 0.075)
      ..lineTo(triCenter.dx - w * 0.055, triCenter.dy + h * 0.02)
      ..lineTo(triCenter.dx + w * 0.055, triCenter.dy + h * 0.02)
      ..close();
    canvas.drawPath(
      triPath,
      Paint()..color = const Color(0xFFE53935),
    );
    final triInner = Path()
      ..moveTo(triCenter.dx, triCenter.dy - h * 0.055)
      ..lineTo(triCenter.dx - w * 0.038, triCenter.dy + h * 0.012)
      ..lineTo(triCenter.dx + w * 0.038, triCenter.dy + h * 0.012)
      ..close();
    canvas.drawPath(
      triInner,
      Paint()..color = Colors.white,
    );
    // ! mark
    canvas.drawCircle(
      Offset(triCenter.dx, triCenter.dy - h * 0.005),
      2.5,
      Paint()..color = const Color(0xFFE53935),
    );
    canvas.drawRect(
      Rect.fromLTWH(triCenter.dx - 1.5, triCenter.dy - h * 0.035, 3, h * 0.022),
      Paint()..color = const Color(0xFFE53935),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

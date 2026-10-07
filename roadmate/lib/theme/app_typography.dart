import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Plus Jakarta Sans typography matching the Stitch design system.
class AppTypography {
  const AppTypography._();

  static TextStyle _jks({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height != null ? height / fontSize : null,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle headlineXl({Color? color}) =>
      _jks(fontSize: 32, fontWeight: FontWeight.w800, height: 40, color: color);

  static TextStyle headlineLg({Color? color}) =>
      _jks(fontSize: 26, fontWeight: FontWeight.w700, height: 32, color: color);

  static TextStyle headlineMd({Color? color}) =>
      _jks(fontSize: 20, fontWeight: FontWeight.w700, height: 26, color: color);

  static TextStyle headlineSm({Color? color}) =>
      _jks(fontSize: 18, fontWeight: FontWeight.w600, height: 24, color: color);

  static TextStyle titleMd({Color? color}) =>
      _jks(fontSize: 16, fontWeight: FontWeight.w600, height: 22, color: color);

  static TextStyle bodyLg({Color? color}) =>
      _jks(fontSize: 15, fontWeight: FontWeight.w400, height: 22, color: color);

  static TextStyle bodyMd({Color? color}) =>
      _jks(fontSize: 14, fontWeight: FontWeight.w400, height: 20, color: color);

  static TextStyle bodySm({Color? color}) =>
      _jks(fontSize: 12, fontWeight: FontWeight.w400, height: 16, color: color);

  static TextStyle labelLg({Color? color}) =>
      _jks(fontSize: 14, fontWeight: FontWeight.w600, height: 18, color: color);

  static TextStyle labelMd({Color? color}) =>
      _jks(fontSize: 12, fontWeight: FontWeight.w600, height: 16, color: color);

  static TextStyle labelSm({Color? color}) =>
      _jks(fontSize: 10, fontWeight: FontWeight.w600, height: 14, color: color);
}

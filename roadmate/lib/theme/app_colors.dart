import 'package:flutter/material.dart';

/// Shared RoadMate colors (matches onboarding + auth screenshots).
/// Extended with the Stitch "RoadMate Mobile Payment Suite" design tokens.
class AppColors {
  const AppColors._();

  // ── Original colors ──
  static const navy = Color(0xFF0A2A66);
  static const navyDark = Color(0xFF1A2340);
  static const orange = Color(0xFFFF8A1E);
  static const greyText = Color(0xFF7A8599);
  static const fieldFill = Color(0xFFF1F4FA);
  static const fieldHint = Color(0xFF9AA5B8);
  static const pageBg = Color(0xFFF7F9FC);
  static const peachBg = Color(0xFFFFE7CF);
  static const peachDark = Color(0xFFFFD9B3);

  // ── Stitch design system tokens ──
  static const primary = Color(0xFF002546);
  static const primaryContainer = Color(0xFF0D3B66);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF81A6D7);

  static const secondary = Color(0xFFA33E00);
  static const secondaryContainer = Color(0xFFFD7129);
  static const secondaryFixed = Color(0xFFFFDBCD);
  static const onSecondaryFixed = Color(0xFF360F00);

  static const tertiary = Color(0xFF002B1B);
  static const tertiaryContainer = Color(0xFF00432C);
  static const tertiaryFixed = Color(0xFF6FFBBE);
  static const onTertiaryContainer = Color(0xFF14BA82);
  static const onTertiaryFixed = Color(0xFF002113);

  static const surface = Color(0xFFF8F9FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEFF4FF);
  static const surfaceContainer = Color(0xFFE5EEFF);
  static const surfaceContainerHigh = Color(0xFFDCE9FF);
  static const surfaceContainerHighest = Color(0xFFD3E4FE);
  static const onSurface = Color(0xFF0B1C30);
  static const onSurfaceVariant = Color(0xFF42474F);

  static const outline = Color(0xFF737780);
  static const outlineVariant = Color(0xFFC3C6D0);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const inverseSurface = Color(0xFF213145);
  static const primaryFixed = Color(0xFFD3E4FF);

  // ── Semantic aliases ──
  static const cardBg = surfaceContainerLowest;
  static const cardBorder = Color(0xFFEBF3FC);
  static const divider = Color(0xFFE2E8F0);
  static const slateText = Color(0xFF64748B);
  static const mutedText = Color(0xFF94A3B8);
  static const darkCharcoal = Color(0xFF0F172A);
  static const slateNavy = Color(0xFF1E293B);

  // ── Status colors ──
  static const successBg = Color(0xFFECFDF5);
  static const successText = Color(0xFF059669);
  static const pendingBg = Color(0xFFFEF3C7);
  static const pendingText = Color(0xFFD97706);
}

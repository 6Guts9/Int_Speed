import 'package:flutter/material.dart';

class AppTheme {
  // ── Colors ────────────────────────────────────────────────────
  static const Color background     = Color(0xFF0A0A12);
  static const Color surface        = Color(0xFF12121E);
  static const Color surfacelight   = Color(0xFF1A1A2E);
  static const Color border         = Color(0xFF22223A);
  static const Color accentBlue     = Color(0xFF4A4AEE);
  static const Color accentPurple   = Color(0xFF7A4AEE);
  static const Color accentPink     = Color(0xFFEE4AAA);
  static const Color accentGreen    = Color(0xFF4AEE8A);
  static const Color accentRed      = Color(0xFFEE4A4A);
  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFF8888BB);
  static const Color textMuted      = Color(0xFF444466);

  // ── Speed quality colors ──────────────────────────────────────
  // We color-code the result based on how fast the connection is
  static Color speedQualityColor(double mbps) {
    if (mbps >= 50)  return accentGreen;
    if (mbps >= 25)  return accentBlue;
    if (mbps >= 10)  return const Color(0xFFEEAA4A);
    return accentRed;
  }

  // ── Speed quality label ───────────────────────────────────────
  static String speedQualityLabel(double mbps) {
    if (mbps >= 50)  return 'Excellent';
    if (mbps >= 25)  return 'Good';
    if (mbps >= 10)  return 'Fair';
    return 'Poor';
  }

  // ── Theme data ────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        surface: surface,
      ),
    );
  }
}
import 'package:flutter/material.dart';
class AppTheme {

  static const Color background = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF12121E);
  static const Color surfacelight = Color(0xFF1A1A2E);
  static const Color border= Color(0xFF22223A);
  static const Color accentBlue = Color(0xFF4A4AEE);
  static const Color accentPurple = Color(0xFF7A4AEE);
  static const Color accentPink = Color(0xFFEE4AAA);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8888BB);
  static const Color textMuted = Color(0xFF444466);

  static ThemeData get dark{
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      fontFamily: 'SF Pro Display',
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        surface: surface,
      ),
    );
  }
}

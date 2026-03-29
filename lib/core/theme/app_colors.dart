import 'package:flutter/material.dart';

/// Legacy static palette (matches dark [KkPalette]). Prefer [BuildContext.palette]
/// in new code so light theme applies correctly.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF111111);
  static const Color surface2 = Color(0xFF1A1A1A);
  static const Color accent = Color(0xFFFFFFFF);
  static const Color accentGlow = Color(0x18FFFFFF);
  static const Color accentBlue = Color(0xFFE0E0E0);
  static const Color green = Color(0xFF22C55E);
  static const Color red = Color(0xFFEF4444);
  static const Color yellow = Color(0xFFF59E0B);
  static const Color purple = Color(0xFFA78BFA);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color border = Color(0xFF2A2A2A);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient chartGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
  );
}

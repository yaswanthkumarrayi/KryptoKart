import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core backgrounds
  static const Color background = Color(0xFF00040F);
  static const Color surface = Color(0xFF0D1117);
  static const Color surface2 = Color(0xFF161B22);

  // Accent colors
  static const Color accent = Color(0xFF00F6FF);
  static const Color accentGlow = Color(0x3300F6FF);
  static const Color accentBlue = Color(0xFF0080FF);

  // Semantic colors
  static const Color green = Color(0xFF00D26A);
  static const Color red = Color(0xFFFF4B4B);
  static const Color yellow = Color(0xFFFFD700);
  static const Color purple = Color(0xFF7B61FF);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B98A5);

  // Border & divider
  static const Color border = Color(0xFF21262D);

  // Gradients
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient chartGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x5500F6FF), Color(0x0000F6FF)],
  );
}

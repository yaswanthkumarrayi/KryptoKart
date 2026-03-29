import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color primary = Color.fromARGB(255, 0, 0, 0);
  // ── Core backgrounds (true black, like Coinbase / Kraken) ──────────────
  static const Color background  = Color(0xFF000000); // pure black
  static const Color surface     = Color(0xFF111111); // card surface
  static const Color surface2    = Color(0xFF1A1A1A); // elevated surface

  // ── Accent — crisp white / silver (no colour tint) ─────────────────────
  static const Color accent      = Color(0xFFFFFFFF); // primary white
  static const Color accentGlow  = Color(0x18FFFFFF); // subtle white glow
  static const Color accentBlue  = Color(0xFFE0E0E0); // silver / off-white

  // ── Semantic colours (muted, professional) ──────────────────────────────
  static const Color green  = Color(0xFF22C55E); // profit green
  static const Color red    = Color(0xFFEF4444); // loss red
  static const Color yellow = Color(0xFFF59E0B); // warning amber
  static const Color purple = Color(0xFFA78BFA); // info purple

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF); // pure white
  static const Color textSecondary = Color(0xFF9CA3AF); // gray-400

  // ── Borders & dividers ──────────────────────────────────────────────────
  static const Color border = Color(0xFF2A2A2A); // very dark border

  // ── Gradients ───────────────────────────────────────────────────────────
  /// Button / hero gradient: white → light-silver
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Chart area fill gradient
  static const LinearGradient chartGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
  );
}

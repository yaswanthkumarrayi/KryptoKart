import 'package:flutter/material.dart';

/// Theme-aware palette (dark / light). Use [BuildContext.palette] from
/// [kk_theme_context.dart].
@immutable
class KkPalette extends ThemeExtension<KkPalette> {
  const KkPalette({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.accent,
    required this.accentGlow,
    required this.accentBlue,
    required this.green,
    required this.red,
    required this.yellow,
    required this.purple,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.textOnAccentButton,
    required this.accentGradient,
    required this.chartGradient,
  });

  final Color background;
  final Color surface;
  final Color surface2;
  final Color accent;
  final Color accentGlow;
  final Color accentBlue;
  final Color green;
  final Color red;
  final Color yellow;
  final Color purple;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  /// Text / icons on filled accent (gradient) buttons.
  final Color textOnAccentButton;

  final LinearGradient accentGradient;
  final LinearGradient chartGradient;

  static const KkPalette dark = KkPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF111111),
    surface2: Color(0xFF1A1A1A),
    accent: Color(0xFFFFFFFF),
    accentGlow: Color(0x18FFFFFF),
    accentBlue: Color(0xFFE0E0E0),
    green: Color(0xFF22C55E),
    red: Color(0xFFEF4444),
    yellow: Color(0xFFF59E0B),
    purple: Color(0xFFA78BFA),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF9CA3AF),
    border: Color(0xFF2A2A2A),
    textOnAccentButton: Color(0xFF000000),
    accentGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    chartGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
    ),
  );

  static const KkPalette light = KkPalette(
    background: Color(0xFFF2F4F7),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFE8ECF0),
    accent: Color(0xFF111111),
    accentGlow: Color(0x18111111),
    accentBlue: Color(0xFF4B5563),
    green: Color(0xFF16A34A),
    red: Color(0xFFDC2626),
    yellow: Color(0xFFD97706),
    purple: Color(0xFF7C3AED),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF6B7280),
    border: Color(0xFFE5E7EB),
    textOnAccentButton: Color(0xFFFFFFFF),
    accentGradient: LinearGradient(
      colors: [Color(0xFF111111), Color(0xFF111111)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    chartGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x33111111), Color(0x00111111)],
    ),
  );

  @override
  KkPalette copyWith({
    Color? background,
    Color? surface,
    Color? surface2,
    Color? accent,
    Color? accentGlow,
    Color? accentBlue,
    Color? green,
    Color? red,
    Color? yellow,
    Color? purple,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? textOnAccentButton,
    LinearGradient? accentGradient,
    LinearGradient? chartGradient,
  }) {
    return KkPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      accent: accent ?? this.accent,
      accentGlow: accentGlow ?? this.accentGlow,
      accentBlue: accentBlue ?? this.accentBlue,
      green: green ?? this.green,
      red: red ?? this.red,
      yellow: yellow ?? this.yellow,
      purple: purple ?? this.purple,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      textOnAccentButton: textOnAccentButton ?? this.textOnAccentButton,
      accentGradient: accentGradient ?? this.accentGradient,
      chartGradient: chartGradient ?? this.chartGradient,
    );
  }

  @override
  KkPalette lerp(ThemeExtension<KkPalette>? other, double t) {
    if (other is! KkPalette) return this;
    return t < 0.5 ? this : other;
  }
}

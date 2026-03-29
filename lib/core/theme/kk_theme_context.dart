import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kk_palette.dart';

extension KkThemeContext on BuildContext {
  KkPalette get palette =>
      Theme.of(this).extension<KkPalette>() ?? KkPalette.dark;

  KkThemeText get txt => KkThemeText(this);
}

/// Theme-aware text styles (replaces static [AppTextStyles]).
class KkThemeText {
  KkThemeText(this.context);

  final BuildContext context;
  KkPalette get p => context.palette;

  TextStyle get display => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: p.textPrimary,
      );

  TextStyle get title => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
      );

  TextStyle get titleSmall => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
      );

  TextStyle get body => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: p.textPrimary,
      );

  TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: p.textPrimary,
      );

  TextStyle get caption => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: p.textSecondary,
      );

  TextStyle get captionMedium => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: p.textSecondary,
      );

  TextStyle get number => GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: p.textPrimary,
      );

  TextStyle get numberSmall => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: p.textPrimary,
      );

  TextStyle get button => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: p.textOnAccentButton,
      );

  TextStyle get label => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: p.textSecondary,
        letterSpacing: 1.0,
      );
}

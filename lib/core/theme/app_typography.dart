import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PocketDesk centralized typography system.
/// All text styles must reference this class.
abstract final class AppTypography {
  // ─── Font Families ────────────────────────────────────────────────────────────
  static const String primaryFont = 'Inter';

  // ─── Display ─────────────────────────────────────────────────────────────────
  static TextStyle displayLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: color,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle displaySmall({Color? color}) => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
      );

  // ─── Headline ─────────────────────────────────────────────────────────────────
  static TextStyle headlineLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle headlineMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle headlineSmall({Color? color}) => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
      );

  // ─── Title ────────────────────────────────────────────────────────────────────
  static TextStyle titleLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle titleMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: color,
      );

  static TextStyle titleSmall({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      );

  // ─── Body ────────────────────────────────────────────────────────────────────
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: color,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: color,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: color,
      );

  // ─── Label ────────────────────────────────────────────────────────────────────
  static TextStyle labelLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle labelMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: color,
      );

  static TextStyle labelSmall({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: color,
      );

  // ─── Convenience Text Theme ───────────────────────────────────────────────────
  static TextTheme buildTextTheme({Color? bodyColor, Color? displayColor}) =>
      GoogleFonts.interTextTheme(TextTheme(
        displayLarge: displayLarge(color: displayColor),
        displayMedium: displayMedium(color: displayColor),
        displaySmall: displaySmall(color: displayColor),
        headlineLarge: headlineLarge(color: displayColor),
        headlineMedium: headlineMedium(color: displayColor),
        headlineSmall: headlineSmall(color: displayColor),
        titleLarge: titleLarge(color: bodyColor),
        titleMedium: titleMedium(color: bodyColor),
        titleSmall: titleSmall(color: bodyColor),
        bodyLarge: bodyLarge(color: bodyColor),
        bodyMedium: bodyMedium(color: bodyColor),
        bodySmall: bodySmall(color: bodyColor),
        labelLarge: labelLarge(color: bodyColor),
        labelMedium: labelMedium(color: bodyColor),
        labelSmall: labelSmall(color: bodyColor),
      ));
}

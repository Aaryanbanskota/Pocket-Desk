import 'package:flutter/material.dart';

/// PocketDesk centralized typography system.
/// All text styles must reference this class.
abstract final class AppTypography {
  // ─── Font Families ────────────────────────────────────────────────────────────
  static const String primaryFont = 'Inter';

  // ─── Display ─────────────────────────────────────────────────────────────────
  static TextStyle displayLarge({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: color,
      );

  static TextStyle displayMedium({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle displaySmall({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
      );

  // ─── Headline ─────────────────────────────────────────────────────────────────
  static TextStyle headlineLarge({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle headlineMedium({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle headlineSmall({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
      );

  // ─── Title ────────────────────────────────────────────────────────────────────
  static TextStyle titleLarge({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle titleMedium({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: color,
      );

  static TextStyle titleSmall({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
      );

  // ─── Body ────────────────────────────────────────────────────────────────────
  static TextStyle bodyLarge({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: color,
      );

  static TextStyle bodyMedium({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: color,
      );

  static TextStyle bodySmall({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: color,
      );

  // ─── Label ────────────────────────────────────────────────────────────────────
  static TextStyle labelLarge({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle labelMedium({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: color,
      );

  static TextStyle labelSmall({Color? color}) => TextStyle(
        fontFamily: primaryFont,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: color,
      );

  // ─── Convenience Text Theme ───────────────────────────────────────────────────
  static TextTheme buildTextTheme({Color? bodyColor, Color? displayColor}) =>
      TextTheme(
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
      );
}

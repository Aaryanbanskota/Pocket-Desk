import 'package:flutter/material.dart';

/// Typography hierarchy exactly matching myday-v4.html
class AppTypography {
  AppTypography._();

  static const TextStyle bigDisplay = TextStyle(
    fontSize: 80,
    fontWeight: FontWeight.w700,
    letterSpacing: -4.8,
    height: 0.95,
  );

  static const TextStyle heroTime = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -3.6,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle clockBig = heroTime;

  static const TextStyle progressBig = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: -2.8,
    height: 1.0,
  );

  static const TextStyle balanceNum = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
  );

  static const TextStyle tileNum = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.7,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle captionMuted = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  static const TextStyle codeEditor = TextStyle(
    fontSize: 14,
    fontFamily: 'monospace',
    height: 1.6,
  );
}

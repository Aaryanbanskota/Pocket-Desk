import 'package:flutter/material.dart';

/// PocketDesk centralized animation duration and curve tokens.
abstract final class AppAnimations {
  // ─── Durations ────────────────────────────────────────────────────────────────
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration xslow = Duration(milliseconds: 600);
  static const Duration page = Duration(milliseconds: 300);
  static const Duration hero = Duration(milliseconds: 400);
  static const Duration splash = Duration(milliseconds: 2000);

  // ─── Curves ───────────────────────────────────────────────────────────────────
  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOut;
  static const Curve accelerate = Curves.easeIn;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve sharp = Curves.easeInOutExpo;

  // ─── Page Transitions ─────────────────────────────────────────────────────────
  static const Curve pageIn = Curves.easeOut;
  static const Curve pageOut = Curves.easeIn;
}

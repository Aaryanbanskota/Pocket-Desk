import 'package:flutter/material.dart';

/// PocketDesk centralized color palette.
/// Never use raw color values outside this class.
abstract final class AppColors {
  // ─── Primary Brand Colors ───────────────────────────────────────────────────
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryLight = Color(0xFFA5B4FC); // Indigo 300
  static const Color primaryDark = Color(0xFF3730A3); // Indigo 800

  // ─── Secondary / Accent ─────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF0369A1); // Sky 700
  static const Color secondaryLight = Color(0xFF38BDF8); // Sky 400
  static const Color secondaryDark = Color(0xFF082F49); // Sky 950

  // ─── Semantic Colors ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF15803D); // Green 700
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFB91C1C); // Red 700
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // ─── Light Surface Colors ────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE2E8F0);

  // ─── Dark Surface Colors ─────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color dividerDark = Color(0xFF334155);

  // ─── Text Colors — Light ─────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textHintLight = Color(0xFF475569);
  static const Color textDisabledLight = Color(0xFF64748B);

  // ─── Text Colors — Dark ──────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textHintDark = Color(0xFF94A3B8);
  static const Color textDisabledDark = Color(0xFF334155);

  // ─── Task Priority Colors ────────────────────────────────────────────────────
  static const Color priorityLow = Color(0xFF166534);
  static const Color priorityMedium = Color(0xFF92400E);
  static const Color priorityHigh = Color(0xFF9A3412);
  static const Color priorityUrgent = Color(0xFF991B1B);

  // ─── Calendar / Event Colors ─────────────────────────────────────────────────
  static const List<Color> calendarPalette = [
    Color(0xFF4F46E5),
    Color(0xFF0EA5E9),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

  // ─── Gradients ────────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

import 'package:flutter/material.dart';

/// MyDay exact design system color tokens matching myday-v4.html prototype.
class AppColors {
  AppColors._();

  // Dark Theme Tokens
  static const Color darkBg = Color(0xFF101112);
  static const Color darkSurface = Color(0xFF1A1B1D);
  static const Color darkSurface2 = Color(0xFF252729);
  static const Color darkLine = Color(0xFF2D2F32);
  static const Color darkText = Color(0xFFF3F3F2);
  static const Color darkMuted = Color(0xFF8E9096);
  static const Color darkCream = Color(0xFFE7E5E0);
  static const Color darkCreamText = Color(0xFF151515);
  static const Color darkCreamBorder = Color(0xFFC4C1B9);

  // Light Theme Tokens
  static const Color lightBg = Color(0xFFF2F1EE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFEBE9E4);
  static const Color lightLine = Color(0xFFE0DED8);
  static const Color lightText = Color(0xFF151515);
  static const Color lightMuted = Color(0xFF77756F);
  static const Color lightCream = Color(0xFF17181A);
  static const Color lightCreamText = Color(0xFFF2F1EE);
  static const Color lightCreamBorder = Color(0xFF4A4B4E);

  // Universal Accents
  static const Color accent = Color(0xFFFF6A2B); // Vibrant warm orange
  static const Color success = Color(0xFF2FA66E); // Green
  static const Color danger = Color(0xFFFF5A5A); // Red
  static const Color warning = Color(0xFFE6B422); // Amber
  static const Color info = Color(0xFF4AA3FF); // Light Blue

  // Category Colors
  static const Map<String, Color> categories = {
    'Food': Color(0xFFFF8A4C),
    'Groceries': Color(0xFF4AC29A),
    'Transport': Color(0xFF3FB6F5),
    'Fuel': Color(0xFFFF9900),
    'Shopping': Color(0xFFC65CF2),
    'Bills': Color(0xFFE6B422),
    'Rent': Color(0xFF5B8DEF),
    'Health': Color(0xFFF0506A),
    'Entertainment': Color(0xFFBD10E0),
    'Fun': Color(0xFF35C486),
    'Education': Color(0xFF7C7BEA),
    'Travel': Color(0xFF26C6DA),
    'Salary': Color(0xFF2FA66E),
    'Investment': Color(0xFF10B981),
    'Gift': Color(0xFFE91E63),
    'Other': Color(0xFF8A9099),
  };

  // Tag Colors
  static const Map<String, Color> tags = {
    'Work': Color(0xFF4AA3FF),
    'Personal': Color(0xFFC65CF2),
    'Health': Color(0xFF35C486),
    'Study': Color(0xFFE6B422),
    'Focus': Color(0xFFFF8A4C),
    'Home': Color(0xFF8F8EF0),
    'Finance': Color(0xFF2FA66E),
  };

  // Note Card Colors (k0 to k4)
  static const List<Color> noteColorsDark = [
    Color(0xFF1A1B1D), // k0 Default
    Color(0xFFE7E5E0), // k1 Cream
    Color(0xFF2B3A67), // k2 Deep Blue
    Color(0xFF3B2A52), // k3 Purple
    Color(0xFF1F4A3A), // k4 Forest Green
  ];

  static const List<Color> noteTextColorsDark = [
    Color(0xFFF3F3F2), // k0
    Color(0xFF151515), // k1
    Color(0xFFFFFFFF), // k2
    Color(0xFFFFFFFF), // k3
    Color(0xFFFFFFFF), // k4
  ];

  // Gradients
  static const LinearGradient netWorthGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6A2B),
      Color(0xFF7B3FE4),
      Color(0xFF1D6FFF),
    ],
    stops: [0.0, 0.62, 1.0],
  );

  static const SweepGradient storyRingGradient = SweepGradient(
    colors: [
      Color(0xFFFF6A2B),
      Color(0xFFE03A8C),
      Color(0xFF7B3FE4),
      Color(0xFFFF6A2B),
    ],
  );

  // Aliases for component convenience
  static const Color accentOrange = accent;
  static const Color errorRed = danger;
  static const Color successGreen = success;
  static const Color amber = warning;
  static const Color muted = darkMuted;
  static const Color darkBackground = darkBg;
  static const Color lightBackground = lightBg;
  static const Color darkCard = darkSurface;
  static const Color lightCard = lightSurface;
  static const Color darkBorder = darkLine;
  static const Color lightBorder = lightLine;
  static const Color darkTextPrimary = darkText;
  static const Color lightTextPrimary = lightText;
  static const Color darkTextMuted = darkMuted;
  static const Color lightTextMuted = lightMuted;
  static const Color darkSecondary = darkSurface2;
  static const Color lightSecondary = lightSurface2;
  static const Map<String, Color> categoryColors = categories;
  static const Map<String, Color> tagColors = tags;
  static const List<Color> avatarColors = [
    Color(0xFFFF6A2B),
    Color(0xFF7B3FE4),
    Color(0xFF1D6FFF),
    Color(0xFF2FA66E),
    Color(0xFFE03A8C),
    Color(0xFFE6B422),
  ];
}

/// Theme context accessor for dynamic palette resolution
extension AppColorsExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appBg => isDarkMode ? AppColors.darkBg : AppColors.lightBg;
  Color get appSurface => isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
  Color get appSurface2 => isDarkMode ? AppColors.darkSurface2 : AppColors.lightSurface2;
  Color get appLine => isDarkMode ? AppColors.darkLine : AppColors.lightLine;
  Color get appText => isDarkMode ? AppColors.darkText : AppColors.lightText;
  Color get appMuted => isDarkMode ? AppColors.darkMuted : AppColors.lightMuted;
  Color get appCream => isDarkMode ? AppColors.darkCream : AppColors.lightCream;
  Color get appCreamText => isDarkMode ? AppColors.darkCreamText : AppColors.lightCreamText;
  Color get appCreamBorder => isDarkMode ? AppColors.darkCreamBorder : AppColors.lightCreamBorder;
  Color get appAccent => AppColors.accent;
  Color get appSuccess => AppColors.success;
  Color get appDanger => AppColors.danger;
}

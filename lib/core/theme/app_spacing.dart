/// PocketDesk centralized spacing and sizing tokens.
/// Always use these instead of hardcoded values.
abstract final class AppSpacing {
  // ─── Base Scale (4pt grid) ────────────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double x2l = 32.0;
  static const double x3l = 40.0;
  static const double x4l = 48.0;
  static const double x5l = 64.0;
  static const double x6l = 80.0;
  static const double x7l = 96.0;

  // ─── Semantic Aliases ─────────────────────────────────────────────────────────
  static const double pagePadding = base;
  static const double cardPadding = base;
  static const double sectionGap = x2l;
  static const double widgetGap = xl;
  static const double itemGap = sm;
  static const double iconTextGap = sm;
  static const double buttonPaddingH = xl;
  static const double buttonPaddingV = md;
  static const double inputPadding = base;
  static const double dialogPadding = x2l;
  static const double bottomSheetPadding = x2l;
  static const double appBarHeight = 56.0;
  static const double navBarHeight = 64.0;
  static const double sidebarWidth = 280.0;
  static const double minTouchTarget = 48.0;
  // ─── Radius Aliases (convenience re-exports from AppRadius) ─────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
}

/// PocketDesk centralized border radius tokens.
abstract final class AppRadius {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double x2l = 24.0;
  static const double full = 999.0;

  // ─── Semantic ─────────────────────────────────────────────────────────────────
  static const double card = md;
  static const double button = sm;
  static const double input = sm;
  static const double badge = full;
  static const double avatar = full;
  static const double chip = full;
  static const double dialog = xl;
  static const double bottomSheet = x2l;
  static const double snackbar = sm;
}

/// PocketDesk centralized shadow/elevation tokens.
abstract final class AppElevation {
  static const double none = 0.0;
  static const double xs = 1.0;
  static const double sm = 2.0;
  static const double md = 4.0;
  static const double lg = 8.0;
  static const double xl = 16.0;

  // ─── Semantic ─────────────────────────────────────────────────────────────────
  static const double card = sm;
  static const double appBar = sm;
  static const double dialog = xl;
  static const double fab = lg;
  static const double navbar = md;
}

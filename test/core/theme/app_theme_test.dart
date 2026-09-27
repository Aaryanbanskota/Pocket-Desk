import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/theme/app_colors.dart';
import 'package:pocketdesk/core/theme/app_theme.dart';

double _contrast(Color foreground, Color background) {
  final values = [
    foreground.computeLuminance(),
    background.computeLuminance(),
  ]..sort((a, b) => b.compareTo(a));
  return (values.first + 0.05) / (values.last + 0.05);
}

void main() {
  test('light theme primary text and control colors meet AA contrast', () {
    final colors = AppTheme.light.colorScheme;

    expect(
        _contrast(colors.onPrimary, colors.primary), greaterThanOrEqualTo(4.5));
    expect(
      _contrast(colors.onSecondary, colors.secondary),
      greaterThanOrEqualTo(4.5),
    );
    expect(_contrast(colors.onTertiary, colors.tertiary),
        greaterThanOrEqualTo(4.5));
    expect(_contrast(colors.onError, colors.error), greaterThanOrEqualTo(4.5));
    expect(
      _contrast(AppColors.textHintLight, AppColors.surfaceVariantLight),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('dark theme secondary and primary controls remain readable', () {
    final colors = AppTheme.dark.colorScheme;

    expect(
        _contrast(colors.onPrimary, colors.primary), greaterThanOrEqualTo(4.5));
    expect(
      _contrast(colors.onSecondary, colors.secondary),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(colors.onSecondaryContainer, colors.secondaryContainer),
      greaterThanOrEqualTo(4.5),
    );
  });
}

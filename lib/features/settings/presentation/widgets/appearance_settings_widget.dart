import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_mode_notifier.dart';

class AppearanceSettingsWidget extends ConsumerWidget {
  const AppearanceSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentThemeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Customize how PocketDesk looks and feels.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Theme Selection
            Text(
              'Theme',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildThemeOption(
              context,
              ref,
              currentThemeMode,
              ThemeMode.light,
              'Light',
              Icons.light_mode_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildThemeOption(
              context,
              ref,
              currentThemeMode,
              ThemeMode.dark,
              'Dark',
              Icons.dark_mode_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildThemeOption(
              context,
              ref,
              currentThemeMode,
              ThemeMode.system,
              'System',
              Icons.settings_brightness_rounded,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Font Size
            Text(
              'Text Size',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Adjust text size',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(50),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          'Normal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Slider(
                    value: ref.watch(textScaleProvider).valueOrNull ?? 1.0,
                    min: 0.8,
                    max: 1.3,
                    divisions: 5,
                    label: _getScaleLabel(ref.watch(textScaleProvider).valueOrNull ?? 1.0),
                    onChanged: (value) {
                      ref.read(textScaleProvider.notifier).setTextScale(value);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Small',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Large',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Display Preferences
            Text(
              'Display',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const SizedBox(height: AppSpacing.sm),
            _buildSwitchTile(
              theme,
              colorScheme,
              'Rearrange Widgets & Menu',
              'Enable reordering controls on Dashboard and Hamburger menu',
              ref.watch(enableRearrangeProvider).valueOrNull ?? false,
              (value) {
                ref
                    .read(enableRearrangeProvider.notifier)
                    .setEnableRearrange(value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSwitchTile(
              theme,
              colorScheme,
              'Show animations',
              'Enable smooth transitions and animations',
              true,
              (value) {},
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSwitchTile(
              theme,
              colorScheme,
              'Compact view',
              'Reduce spacing for more content per screen',
              false,
              (value) {},
            ),
            const SizedBox(height: AppSpacing.sm),
            const SizedBox(height: AppSpacing.xl),

            // About App Section
            Text(
              'About PocketDesk',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _AboutAppTile(),
          ],
        ),
      ),
    );
  }

  String _getScaleLabel(double value) {
    if (value <= 0.8) return 'Smallest';
    if (value <= 0.9) return 'Small';
    if (value <= 1.0) return 'Normal';
    if (value <= 1.1) return 'Medium';
    if (value <= 1.2) return 'Large';
    return 'Largest';
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
    ThemeMode optionMode,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = currentMode == optionMode;

    return Material(
      child: InkWell(
        onTap: () {
          ref.read(themeModeProvider.notifier).setThemeMode(optionMode);
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withAlpha(25)
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    String subtitle,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _AboutAppTile extends ConsumerStatefulWidget {
  const _AboutAppTile();

  @override
  ConsumerState<_AboutAppTile> createState() => _AboutAppTileState();
}

class _AboutAppTileState extends ConsumerState<_AboutAppTile> {
  int _clickCount = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnlocked = ref.watch(shareTabUnlockedProvider).valueOrNull ?? false;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PocketDesk App',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (isUnlocked) return;
                    setState(() => _clickCount++);
                    if (_clickCount >= 10) {
                      ref.read(shareTabUnlockedProvider.notifier).unlockShareTab();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 Share & Transfer Settings Unlocked!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (_clickCount >= 5) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tap ${10 - _clickCount} more times to unlock Share features.'),
                          duration: const Duration(milliseconds: 1000),
                        ),
                      );
                    }
                  },
                  child: Text(
                    isUnlocked ? 'Version v1.2.0 (Share Unlocked)' : 'Version v1.2.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isUnlocked ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            Icon(Icons.lock_open_rounded, color: colorScheme.primary, size: 20),
        ],
      ),
    );
  }
}

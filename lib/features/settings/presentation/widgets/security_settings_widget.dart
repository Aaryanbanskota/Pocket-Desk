import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/data/services/biometric_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

/// Provider that exposes whether biometric hardware is available on this device.
final _biometricAvailableProvider = FutureProvider<bool>((ref) async {
  return BiometricService().isBiometricAvailable();
});

class SecuritySettingsWidget extends ConsumerStatefulWidget {
  const SecuritySettingsWidget({super.key});

  @override
  ConsumerState<SecuritySettingsWidget> createState() =>
      _SecuritySettingsWidgetState();
}

class _SecuritySettingsWidgetState
    extends ConsumerState<SecuritySettingsWidget> {
  bool? _biometricEnabled; // null = loading

  @override
  void initState() {
    super.initState();
    _loadBiometricEnabled();
  }

  Future<void> _loadBiometricEnabled() async {
    final enabled =
        await ref.read(authNotifierProvider.notifier).getBiometricEnabled();
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<void> _toggleBiometric(bool value) async {
    // Optimistic update
    setState(() => _biometricEnabled = value);
    await ref.read(authNotifierProvider.notifier).setBiometricEnabled(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Biometric login enabled. You\'ll be prompted on next launch.'
                : 'Biometric login disabled.',
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final biometricAvailable = ref.watch(_biometricAvailableProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Manage login and authentication security.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Biometric section ────────────────────────────────────────────
            Text(
              'Biometric Authentication',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            biometricAvailable.when(
              loading: () => const _BiometricLoadingTile(),
              error: (_, __) => _BiometricUnavailableTile(
                theme: theme,
                colorScheme: colorScheme,
                reason: 'Could not check biometric availability.',
              ),
              data: (available) {
                if (!available) {
                  return _BiometricUnavailableTile(
                    theme: theme,
                    colorScheme: colorScheme,
                    reason:
                        'This device does not have biometric hardware or no '
                        'credentials are enrolled.',
                  );
                }
                return _BiometricToggleTile(
                  theme: theme,
                  colorScheme: colorScheme,
                  enabled: _biometricEnabled ?? false,
                  loading: _biometricEnabled == null,
                  onToggle: _toggleBiometric,
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── How it works card ────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: colorScheme.primary.withAlpha(40),
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How biometric login works',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'When enabled, PocketDesk will automatically prompt '
                          'for your fingerprint or face ID each time you open '
                          'the app. Your password credentials are stored '
                          'securely on-device — biometrics just unlock them.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Login username hint ──────────────────────────────────────────
            Text(
              'Login Preferences',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_pin_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remember last username',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Your username is suggested on the login screen for '
                          'quick access. Always enabled.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper tiles
// ---------------------------------------------------------------------------

class _BiometricToggleTile extends StatelessWidget {
  const _BiometricToggleTile({
    required this.theme,
    required this.colorScheme,
    required this.enabled,
    required this.loading,
    required this.onToggle,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool enabled;
  final bool loading;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: enabled
            ? colorScheme.primary.withAlpha(12)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: enabled
              ? colorScheme.primary.withAlpha(80)
              : colorScheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Icon(
              enabled
                  ? Icons.fingerprint_rounded
                  : Icons.fingerprint_rounded,
              key: ValueKey(enabled),
              color: enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biometric Login',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                Text(
                  enabled
                      ? 'Tap fingerprint or face ID to sign in'
                      : 'Enable to skip password on launch',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: enabled,
                  onChanged: onToggle,
                  thumbIcon: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Icon(Icons.check_rounded, size: 16);
                    }
                    return null;
                  }),
                ),
        ],
      ),
    );
  }
}

class _BiometricUnavailableTile extends StatelessWidget {
  const _BiometricUnavailableTile({
    required this.theme,
    required this.colorScheme,
    required this.reason,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: colorScheme.error, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BiometricLoadingTile extends StatelessWidget {
  const _BiometricLoadingTile();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 56,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

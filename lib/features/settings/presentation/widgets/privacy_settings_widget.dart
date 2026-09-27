import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class PrivacySettingsWidget extends ConsumerStatefulWidget {
  const PrivacySettingsWidget({super.key});

  @override
  ConsumerState<PrivacySettingsWidget> createState() =>
      _PrivacySettingsWidgetState();
}

class _PrivacySettingsWidgetState extends ConsumerState<PrivacySettingsWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy & Security',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Control your data and security settings.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Data Privacy Section
            Text(
              'Data & Privacy',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _buildSwitchTile(
              theme,
              colorScheme,
              'Enable encryption',
              'Encrypt all data stored locally',
              true,
              (value) {},
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSwitchTile(
              theme,
              colorScheme,
              'Analytics',
              'Help improve the app with anonymous usage data',
              false,
              (value) {},
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSwitchTile(
              theme,
              colorScheme,
              'Backup to cloud',
              'Automatically backup your data (optional)',
              false,
              (value) {},
            ),

            const SizedBox(height: AppSpacing.xl),

            // Sync & Sharing
            Text(
              'Sync & Sharing',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _buildSwitchTile(
              theme,
              colorScheme,
              'P2P sync',
              'Allow peer-to-peer data synchronization',
              true,
              (value) {},
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSwitchTile(
              theme,
              colorScheme,
              'WiFi only sync',
              'Only sync when connected to WiFi',
              true,
              (value) {},
            ),

            const SizedBox(height: AppSpacing.xl),

            // Account Actions
            Text(
              'Account',
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
              child: Column(
                children: [
                  Material(
                    child: InkWell(
                      onTap: _showChangePasswordDialog,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Change password',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  Material(
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Two-factor authentication'),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Two-factor authentication',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  Material(
                    child: InkWell(
                      onTap: () {
                        _showConfirmDialog(
                          context,
                          'Export Data',
                          'Export all your data in JSON format?',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Exporting data...'),
                              ),
                            );
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.download_rounded,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Export data',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Danger Zone
            Text(
              'Danger Zone',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            FilledButton.tonal(
              onPressed: () {
                _showConfirmDialog(
                  context,
                  'Delete Account',
                  'Are you sure? This action cannot be undone.',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deletion initiated'),
                      ),
                    );
                  },
                  isDangerous: true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Row(
                children: [
                  Icon(Icons.delete_forever_rounded),
                  SizedBox(width: AppSpacing.md),
                  Text('Delete Account'),
                ],
              ),
            ),
          ],
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

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm, {
    bool isDangerous = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: isDangerous
                ? FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                  )
                : null,
            child: Text(isDangerous ? 'Delete' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final currentPwd = currentCtrl.text.trim();
              final newPwd = newCtrl.text.trim();
              final confirmPwd = confirmCtrl.text.trim();

              if (currentPwd.isEmpty || newPwd.isEmpty) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(content: Text('Please fill all password fields.')),
                );
                return;
              }

              if (newPwd != confirmPwd) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match!')),
                );
                return;
              }

              final messenger = ScaffoldMessenger.of(context);
              final failure = await ref.read(authNotifierProvider.notifier).changePassword(
                currentPassword: currentPwd,
                newPassword: newPwd,
              );

              if (!dialogCtx.mounted) return;

              if (failure != null) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  SnackBar(content: Text(failure.message)),
                );
              } else {
                Navigator.pop(dialogCtx);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Password changed successfully!')),
                );
              }
            },
            child: const Text('Save Password'),
          ),
        ],
      ),
    );
  }
}

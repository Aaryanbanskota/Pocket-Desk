import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/data/models/user_model.dart';
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
                      onTap: () => _showUpdateSecurityQuestionsDialog(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.security_rounded,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Security Recovery Questions',
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
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  Material(
                    child: InkWell(
                      onTap: _checkStoredAccounts,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.storage_rounded,
                                color: colorScheme.primary),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Check Data',
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
              onPressed: () => _showDeleteAccountTwoStepDialog(context),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_forever_rounded),
                  SizedBox(width: AppSpacing.md),
                  Text('Delete Account',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _checkStoredAccounts() async {
    try {
      final accounts =
          await ref.read(authNotifierProvider.notifier).getStoredAccounts();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Stored Accounts'),
          content: SizedBox(
            width: 420,
            child: accounts.length <= 1
                ? Text(
                    '${accounts.length} account${accounts.length == 1 ? '' : 's'} stored on this device.',
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Text(
                          '${accounts.length} accounts are stored on this device. '
                          'Secondary accounts can be permanently removed without their password.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final account in accounts)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              account.displayName?.isNotEmpty == true
                                  ? account.displayName!
                                  : account.username,
                            ),
                            subtitle: Text(account.username),
                            trailing: _isCurrentAccount(account.id)
                                ? const Chip(label: Text('Current'))
                                : IconButton(
                                    tooltip: 'Permanently delete account',
                                    onPressed: () =>
                                        _confirmStoredAccountDeletion(
                                      account,
                                      dialogContext,
                                    ),
                                    icon: const Icon(Icons.delete_forever),
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                          ),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not check stored accounts: $e')),
        );
      }
    }
  }

  Future<void> _confirmStoredAccountDeletion(
    UserModel account,
    BuildContext dialogContext,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (confirmContext) => AlertDialog(
        title: const Text('Delete stored account?'),
        content: Text(
          'Permanently delete ${account.username} and its local data? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(confirmContext, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .deleteStoredAccount(account.id);
      if (!dialogContext.mounted) return;
      Navigator.pop(dialogContext);
      await _checkStoredAccounts();
    } catch (e) {
      if (dialogContext.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not delete account: $e')),
        );
      }
    }
  }

  bool _isCurrentAccount(int userId) {
    final authState = ref.read(authNotifierProvider).valueOrNull;
    return authState is AuthAuthenticated && authState.user.id == userId;
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
                  const SnackBar(
                      content: Text('Please fill all password fields.')),
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
              final failure =
                  await ref.read(authNotifierProvider.notifier).changePassword(
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
                  const SnackBar(
                      content: Text('Password changed successfully!')),
                );
              }
            },
            child: const Text('Save Password'),
          ),
        ],
      ),
    );
  }

  void _showUpdateSecurityQuestionsDialog(BuildContext context) {
    final pwdCtrl = TextEditingController();
    final customQ1Ctrl = TextEditingController();
    final ans1Ctrl = TextEditingController();
    final customQ2Ctrl = TextEditingController();
    final ans2Ctrl = TextEditingController();

    final presetQuestions1 = [
      'What was the name of your first pet?',
      'What city were you born in?',
      'What is your mother\'s maiden name?',
      'What was the model of your first car?',
      'Write my own custom question...',
    ];

    final presetQuestions2 = [
      'What is your favorite book or movie?',
      'What was the name of your primary school?',
      'What is your favorite food?',
      'What was your childhood nickname?',
      'Write my own custom question...',
    ];

    String selectedQ1 = presetQuestions1.first;
    String selectedQ2 = presetQuestions2.first;
    bool isSubmitting = false;
    String? dialogError;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isCustom1 = selectedQ1 == 'Write my own custom question...';
          final isCustom2 = selectedQ2 == 'Write my own custom question...';

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.security_rounded, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Update Security Questions',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dialogError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withAlpha(128)),
                        ),
                        child: Text(
                          dialogError!,
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    const Text(
                        'Confirm your password to update your security questions:',
                        style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: pwdCtrl,
                      obscureText: true,
                      maxLength: 64,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        isDense: true,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                      ),
                    ),
                    const Divider(height: 20),
                    const Text('Question 1',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedQ1,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          isDense: true, border: OutlineInputBorder()),
                      items: presetQuestions1
                          .map((q) => DropdownMenuItem(
                              value: q,
                              child: Text(q,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedQ1 = val);
                      },
                    ),
                    if (isCustom1) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customQ1Ctrl,
                        maxLength: 100,
                        decoration: const InputDecoration(
                            labelText: 'Custom Question 1',
                            isDense: true,
                            border: OutlineInputBorder()),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      controller: ans1Ctrl,
                      maxLength: 64,
                      decoration: const InputDecoration(
                          labelText: 'Answer 1',
                          isDense: true,
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    const Text('Question 2',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedQ2,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          isDense: true, border: OutlineInputBorder()),
                      items: presetQuestions2
                          .map((q) => DropdownMenuItem(
                              value: q,
                              child: Text(q,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedQ2 = val);
                      },
                    ),
                    if (isCustom2) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customQ2Ctrl,
                        maxLength: 100,
                        decoration: const InputDecoration(
                            labelText: 'Custom Question 2',
                            isDense: true,
                            border: OutlineInputBorder()),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      controller: ans2Ctrl,
                      maxLength: 64,
                      decoration: const InputDecoration(
                          labelText: 'Answer 2',
                          isDense: true,
                          border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final pwd = pwdCtrl.text.trim();
                        final q1 =
                            isCustom1 ? customQ1Ctrl.text.trim() : selectedQ1;
                        final a1 = ans1Ctrl.text.trim();
                        final q2 =
                            isCustom2 ? customQ2Ctrl.text.trim() : selectedQ2;
                        final a2 = ans2Ctrl.text.trim();

                        if (pwd.isEmpty) {
                          setDialogState(() => dialogError =
                              'Password is required to confirm changes.');
                          return;
                        }
                        if (q1.isEmpty ||
                            a1.isEmpty ||
                            q2.isEmpty ||
                            a2.isEmpty) {
                          setDialogState(() => dialogError =
                              'Please complete both questions and answers.');
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });

                        final combinedQ = '$q1 | $q2';
                        final combinedA = '$a1 | $a2';

                        final err = await ref
                            .read(authNotifierProvider.notifier)
                            .updateSecurityQuestions(
                              password: pwd,
                              securityQuestion: combinedQ,
                              securityAnswer: combinedA,
                            );

                        if (dialogCtx.mounted) {
                          if (err != null) {
                            setDialogState(() {
                              isSubmitting = false;
                              dialogError = err.message;
                            });
                          } else {
                            Navigator.pop(dialogCtx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Security recovery questions updated successfully!')),
                              );
                            }
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Update Questions'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteAccountTwoStepDialog(BuildContext context) {
    final confirmCtrl = TextEditingController();
    bool isStepTwo = false;
    bool isDeleting = false;
    String? errorMsg;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Row(
              children: [
                const Icon(Icons.delete_forever_rounded,
                    color: Colors.red, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isStepTwo ? 'Confirm Account Deletion' : 'Delete Account?',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withAlpha(128)),
                        ),
                        child: Text(
                          errorMsg!,
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    if (!isStepTwo) ...[
                      const Text(
                        'Are you sure you want to delete your account?',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This will permanently delete all your data, including notes, tasks, calendar events, expenses, settings, and API keys. This action CANNOT be undone.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ] else ...[
                      const Text(
                        'To confirm permanent deletion of ALL app data, type DELETE in the box below:',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Type DELETE',
                          isDense: true,
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warning_amber_rounded,
                              color: Colors.red, size: 20),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              if (!isStepTwo)
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    setDialogState(() {
                      isStepTwo = true;
                    });
                  },
                  child: const Text('Yes, Continue'),
                )
              else
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: (confirmCtrl.text.trim() != 'DELETE' || isDeleting)
                      ? null
                      : () async {
                          setDialogState(() {
                            isDeleting = true;
                            errorMsg = null;
                          });

                          final err = await ref
                              .read(authNotifierProvider.notifier)
                              .deleteAccount();

                          if (ctx.mounted) {
                            if (err != null) {
                              setDialogState(() {
                                isDeleting = false;
                                errorMsg = err.message;
                              });
                            } else {
                              Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Account and all app data erased completely. Starting fresh!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Delete Everything'),
                ),
            ],
          );
        },
      ),
    );
  }
}

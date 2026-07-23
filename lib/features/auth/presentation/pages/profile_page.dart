import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_notifier.dart';
import '../widgets/pd_text_field.dart';
import '../../data/models/user_model.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _currPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _profileFormKey = GlobalKey<FormState>();
  final _passFormKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _changingPass = false;
  bool _obscureCurr = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authNotifierProvider).valueOrNull;
    if (authState is AuthAuthenticated) {
      _nameCtrl.text = authState.user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_profileFormKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final error = await ref.read(authNotifierProvider.notifier).updateProfile(
          displayName: _nameCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      _showSnack(error.message, isError: true);
    } else {
      _showSnack('Profile updated successfully');
    }
  }

  Future<void> _changePassword() async {
    if (!(_passFormKey.currentState?.validate() ?? false)) return;
    setState(() => _changingPass = true);

    final error =
        await ref.read(authNotifierProvider.notifier).changePassword(
              currentPassword: _currPassCtrl.text,
              newPassword: _newPassCtrl.text,
            );

    if (!mounted) return;
    setState(() => _changingPass = false);

    if (error != null) {
      _showSnack(error.message, isError: true);
    } else {
      _currPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      _showSnack('Password changed successfully');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final user =
        authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: _logout,
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _AvatarSection(user: user),
                const SizedBox(height: AppSpacing.xl),
                _SectionCard(
                  title: 'Display Name',
                  icon: Icons.person_outline_rounded,
                  colorScheme: colorScheme,
                  child: Form(
                    key: _profileFormKey,
                    child: Column(
                      children: [
                        PDTextField(
                          controller: _nameCtrl,
                          label: 'Display Name',
                          prefixIcon: Icons.badge_outlined,
                          validator: (v) =>
                              Validators.maxLength(v, 50, fieldName: 'Display name'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: _saving ? null : _saveProfile,
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  title: 'Change Password',
                  icon: Icons.lock_outline_rounded,
                  colorScheme: colorScheme,
                  child: Form(
                    key: _passFormKey,
                    child: Column(
                      children: [
                        PDTextField(
                          controller: _currPassCtrl,
                          label: 'Current Password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscureCurr,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurr
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscureCurr = !_obscureCurr),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Current password is required'
                              : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        PDTextField(
                          controller: _newPassCtrl,
                          label: 'New Password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscureNew,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscureNew = !_obscureNew),
                          ),
                          validator: Validators.password,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        PDTextField(
                          controller: _confirmPassCtrl,
                          label: 'Confirm New Password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscureConfirm,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          validator: (v) =>
                              Validators.confirmPassword(v, _newPassCtrl.text),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _changePassword(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed:
                                _changingPass ? null : _changePassword,
                            child: _changingPass
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Change Password'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  title: 'Account Info',
                  icon: Icons.info_outline_rounded,
                  colorScheme: colorScheme,
                  child: Column(
                    children: [
                      _InfoRow(
                          label: 'Username', value: user.username),
                      _InfoRow(
                          label: 'Member since',
                          value: _formatDate(user.createdAt)),
                      if (user.lastLoginAt != null)
                        _InfoRow(
                            label: 'Last login',
                            value: _formatDate(user.lastLoginAt!)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------



class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor:
                theme.colorScheme.primaryContainer,
            child: Text(
              _initials(user.displayName ?? user.username),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            user.displayName ?? user.username,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '@${user.username}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.colorScheme,
    required this.child,
  });

  final String title;
  final IconData icon;
  final ColorScheme colorScheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

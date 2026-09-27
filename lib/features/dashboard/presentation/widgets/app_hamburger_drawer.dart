import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class AppHamburgerDrawer extends ConsumerWidget {
  const AppHamburgerDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final username = user?.displayName ?? user?.username ?? 'User';
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Drawer(
      backgroundColor: cs.surface,
      width: 310,
      child: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: cs.primary,
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                          style: TextStyle(color: cs.onPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  RichText(
                    text: TextSpan(
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      children: [
                        const TextSpan(text: 'yo '),
                        TextSpan(
                          text: username,
                          style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PocketDesk Workspace',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                children: [
                  _NavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.dashboard);
                    },
                  ),
                  _NavItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Calendar',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.calendar);
                    },
                  ),
                  _NavItem(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Tasks',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.tasks);
                    },
                  ),
                  _NavItem(
                    icon: Icons.notes_rounded,
                    label: 'Notes',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.notes);
                    },
                  ),
                  _NavItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Money Health',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.moneyTracker);
                    },
                  ),
                  _NavItem(
                    icon: Icons.dynamic_feed_rounded,
                    label: 'Personal Feed',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.posts);
                    },
                  ),
                  _NavItem(
                    icon: Icons.folder_shared_rounded,
                    label: 'File Share & Network',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.fileShare);
                    },
                  ),
                  _NavItem(
                    icon: Icons.access_time_filled_rounded,
                    label: 'Clock',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.clock);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.settingsProfile);
                    },
                  ),
                  _NavItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.settings);
                    },
                  ),
                  _NavItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About App',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.aboutApp);
                    },
                  ),
                ],
              ),
            ),

            // Logout Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref.read(authNotifierProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: cs.primary, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        horizontalTitleGap: 12,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}

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

    return Drawer(
      backgroundColor: cs.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: cs.onSurface, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Greeting title matching app theme
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                    color: cs.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: 'yo ',
                      style: TextStyle(color: cs.onSurface),
                    ),
                    TextSpan(
                      text: username,
                      style: TextStyle(
                        color: cs.primary, // App primary accent color
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Navigation List Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _NavItem(
                      label: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.settingsProfile);
                      },
                    ),
                    _NavItem(
                      label: 'Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        context.go(AppRoutes.dashboard);
                      },
                    ),
                    _NavItem(
                      label: 'Calendar',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.calendar);
                      },
                    ),
                    _NavItem(
                      label: 'Tasks',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.tasks);
                      },
                    ),
                    _NavItem(
                      label: 'Notes',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.notes);
                      },
                    ),
                    _NavItem(
                      label: 'Money Tracker',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.moneyTracker);
                      },
                    ),
                    _NavItem(
                      label: 'Personal Feed',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.posts);
                      },
                    ),
                    _NavItem(
                      label: 'Clock',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.clock);
                      },
                    ),
                    _NavItem(
                      label: 'File Share',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.fileShare);
                      },
                    ),
                    _NavItem(
                      label: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.settings);
                      },
                    ),
                  ],
                ),
              ),

              // Logout Button at Bottom
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref.read(authNotifierProvider.notifier).logout();
                  },
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Text(
          label,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

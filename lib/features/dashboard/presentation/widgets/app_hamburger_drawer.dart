import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/connectivity_provider.dart';
import '../../../../core/theme/theme_mode_notifier.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/drawer_customization_provider.dart';

class DrawerItemConfig {
  const DrawerItemConfig({
    required this.key,
    required this.label,
    required this.icon,
    required this.route,
  });

  final String key;
  final String label;
  final IconData icon;
  final String route;
}

final Map<String, DrawerItemConfig> kDrawerItemsMap = {
  'dashboard': const DrawerItemConfig(
      key: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_rounded, route: AppRoutes.dashboard),
  'calendar': const DrawerItemConfig(
      key: 'calendar', label: 'Calendar', icon: Icons.calendar_month_rounded, route: AppRoutes.calendar),
  'tasks': const DrawerItemConfig(
      key: 'tasks', label: 'Tasks', icon: Icons.check_circle_outline_rounded, route: AppRoutes.tasks),
  'notes': const DrawerItemConfig(
      key: 'notes', label: 'Notes', icon: Icons.notes_rounded, route: AppRoutes.notes),
  'moneyTracker': const DrawerItemConfig(
      key: 'moneyTracker', label: 'Money Health', icon: Icons.account_balance_wallet_rounded, route: AppRoutes.moneyTracker),
  'posts': const DrawerItemConfig(
      key: 'posts', label: 'Personal Feed', icon: Icons.dynamic_feed_rounded, route: AppRoutes.posts),
  'fileShare': const DrawerItemConfig(
      key: 'fileShare', label: 'File Share & Network', icon: Icons.folder_shared_rounded, route: AppRoutes.fileShare),
  'clock': const DrawerItemConfig(
      key: 'clock', label: 'Clock', icon: Icons.access_time_filled_rounded, route: AppRoutes.clock),
  'profile': const DrawerItemConfig(
      key: 'profile', label: 'Profile', icon: Icons.person_outline_rounded, route: AppRoutes.settingsProfile),
  'settings': const DrawerItemConfig(
      key: 'settings', label: 'Settings', icon: Icons.settings_rounded, route: AppRoutes.settings),
  'aboutApp': const DrawerItemConfig(
      key: 'aboutApp', label: 'About App', icon: Icons.info_outline_rounded, route: AppRoutes.aboutApp),
  'trash': const DrawerItemConfig(
      key: 'trash', label: 'Trash', icon: Icons.delete_outline_rounded, route: AppRoutes.trash),
};

class AppHamburgerDrawer extends ConsumerWidget {
  const AppHamburgerDrawer({super.key});

  void _openDrawerCustomizerModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _DrawerCustomizerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final username = user?.displayName ?? user?.username ?? 'User';
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isOnline = ref.watch(networkConnectivityProvider).valueOrNull ?? true;
    final drawerState = ref.watch(drawerCustomizationProvider);

    return Drawer(
      backgroundColor: cs.surface,
      width: 320,
      child: SafeArea(
        child: Column(
          children: [
            // Header Section with Online/Offline Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
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
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: cs.primary,
                            backgroundImage: user?.avatarBase64 != null
                                ? MemoryImage(base64Decode(user!.avatarBase64!))
                                : null,
                            child: user?.avatarBase64 == null
                                ? Text(
                                    username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                    style: TextStyle(color: cs.onPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(color: cs.surface, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (ref.watch(enableRearrangeProvider).valueOrNull ?? false)
                            IconButton(
                              icon: const Icon(Icons.tune_rounded, size: 22),
                              tooltip: 'Customize Menu Items',
                              onPressed: () => _openDrawerCustomizerModal(context),
                            ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant, size: 24),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: tt.titleLarge?.copyWith(
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isOnline ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (isOnline ? Colors.green : Colors.grey).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                              size: 12,
                              color: isOnline ? Colors.green : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOnline ? 'Online Mode' : 'Offline Mode',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOnline ? Colors.green.shade800 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Customized Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                children: drawerState.itemOrder
                    .where((key) => !drawerState.disabledItems.contains(key))
                    .map((key) {
                  final config = kDrawerItemsMap[key];
                  if (config == null) return const SizedBox();
                  return _NavItem(
                    icon: config.icon,
                    label: config.label,
                    onTap: () {
                      Navigator.pop(context);
                      if (config.route == AppRoutes.dashboard) {
                        context.go(config.route);
                      } else {
                        context.push(config.route);
                      }
                    },
                  );
                }).toList(),
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

class _DrawerCustomizerSheet extends ConsumerWidget {
  const _DrawerCustomizerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(drawerCustomizationProvider);
    final notifier = ref.read(drawerCustomizationProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customize Hamburger Menu',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => notifier.resetToDefaults(),
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag handle to reorder links. Toggle switch to show or hide items in the drawer.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Divider(height: 24),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: state.itemOrder.length,
              onReorder: (oldIndex, newIndex) => notifier.reorderItems(oldIndex, newIndex),
              itemBuilder: (context, index) {
                final key = state.itemOrder[index];
                final config = kDrawerItemsMap[key];
                if (config == null) return SizedBox(key: ValueKey(key));

                final isHidden = state.disabledItems.contains(key);
                final isEssential = key == 'dashboard' || key == 'settings';

                return Card(
                  key: ValueKey(key),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 0,
                  color: isHidden ? cs.surfaceContainerHighest.withValues(alpha: 0.5) : cs.surfaceContainerLow,
                  child: ListTile(
                    leading: Icon(config.icon, color: isHidden ? Colors.grey : cs.primary),
                    title: Text(
                      config.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isHidden ? Colors.grey : cs.onSurface,
                        decoration: isHidden ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: !isHidden,
                          onChanged: isEssential
                              ? null
                              : (_) => notifier.toggleItemVisibility(key),
                        ),
                        const SizedBox(width: 8),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

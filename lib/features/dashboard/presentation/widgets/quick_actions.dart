import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/app_routes.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final actions = [
      _ActionItem(
        icon: Icons.add_task_rounded,
        label: 'Add Task',
        color: colorScheme.primary,
        onTap: () => context.push(AppRoutes.tasks),
      ),
      _ActionItem(
        icon: Icons.event_rounded,
        label: 'Calendar',
        color: colorScheme.secondary,
        onTap: () => context.push(AppRoutes.calendar),
      ),
      _ActionItem(
        icon: Icons.note_add_rounded,
        label: 'Notes',
        color: colorScheme.tertiary,
        onTap: () => context.push(AppRoutes.notes),
      ),
      _ActionItem(
        icon: Icons.wifi_tethering_rounded,
        label: 'File Share',
        color: Colors.teal,
        onTap: () => context.push(AppRoutes.fileShare),
      ),
      _ActionItem(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Chat',
        color: Colors.blueAccent,
        onTap: () => context.push(AppRoutes.chat),
      ),
      _ActionItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Money',
        color: Colors.green,
        onTap: () => context.push(AppRoutes.moneyTracker),
      ),
      _ActionItem(
        icon: Icons.access_time_rounded,
        label: 'Clock',
        color: Colors.orange,
        onTap: () => context.push(AppRoutes.clock),
      ),
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final act = actions[index];
          return SizedBox(
            width: 90,
            child: Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha(50),
                ),
              ),
              child: InkWell(
                onTap: act.onTap,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                    horizontal: AppSpacing.xs,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: act.color.withAlpha(25),
                        child: Icon(
                          act.icon,
                          color: act.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        act.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

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
        onTap: () {},
      ),
      _ActionItem(
        icon: Icons.event_rounded,
        label: 'New Event',
        color: colorScheme.secondary,
        onTap: () {},
      ),
      _ActionItem(
        icon: Icons.note_add_rounded,
        label: 'New Note',
        color: colorScheme.tertiary,
        onTap: () {},
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = AppSpacing.md;
        final double itemWidth = (constraints.maxWidth - (spacing * (actions.length - 1))) / actions.length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: actions.map((act) {
            return SizedBox(
              width: itemWidth,
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
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor: act.color.withAlpha(25),
                          child: Icon(act.icon, color: act.color),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          act.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
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
          }).toList(),
        );
      },
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

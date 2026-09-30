import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/account_plan_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/tasks_notifier.dart';

class ProgressStorageWidget extends ConsumerWidget {
  const ProgressStorageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final planState = ref.watch(accountPlanProvider);
    final tasksState = ref.watch(tasksProvider).valueOrNull;

    final tasks = tasksState?.tasks ?? [];
    final totalTasks = tasks.length;
    final completedTasks =
        tasks.where((t) => t.status == TaskStatus.done).length;
    final taskProgress =
        totalTasks > 0 ? (completedTasks / totalTasks).clamp(0.0, 1.0) : 0.0;

    final storageUsedMB =
        (planState.storageUsedBytes / (1024 * 1024)).toStringAsFixed(1);
    final storageLimitMB =
        (planState.storageLimitBytes / (1024 * 1024)).toStringAsFixed(0);
    final isCloud = planState.accountType == AccountType.cloud;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                isCloud
                    ? Icons.cloud_queue_rounded
                    : Icons.sd_card_alert_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCloud
                      ? 'Cloud Storage (${planState.cloudPlan == CloudPlan.free ? "Free 500MB" : "Pro 10GB"})'
                      : 'Local Device Storage',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (planState.isBlacklisted
                          ? Colors.red
                          : planState.isProApprovalPending
                              ? Colors.amber
                              : Colors.green)
                      .withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  planState.isBlacklisted
                      ? 'Blacklisted'
                      : planState.isProApprovalPending
                          ? 'Pro Pending Approval'
                          : 'Active',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: planState.isBlacklisted
                        ? Colors.red
                        : planState.isProApprovalPending
                            ? Colors.amber.shade900
                            : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 1. Task Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Tasks Progress',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$completedTasks / $totalTasks done (${(taskProgress * 100).toInt()}%)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: taskProgress,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),

          const SizedBox(height: 10),

          // 2. Storage Remaining Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remaining Storage Space',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$storageUsedMB MB / $storageLimitMB MB',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: planState.storageProgress,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                planState.storageProgress > 0.9 ? Colors.red : Colors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

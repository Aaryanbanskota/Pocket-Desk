import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../data/models/trash_item_model.dart';
import '../providers/trash_notifier.dart';

/// Apple-style Trash / Bin Page displaying deleted items across Notes, Tasks, Calendar, and Personal Feed.
class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  IconData _getTypeIcon(TrashItemType type) {
    return switch (type) {
      TrashItemType.note => Icons.description_outlined,
      TrashItemType.task => Icons.check_circle_outline_rounded,
      TrashItemType.event => Icons.calendar_month_outlined,
      TrashItemType.post => Icons.dynamic_feed_rounded,
      TrashItemType.expense => Icons.account_balance_wallet_outlined,
    };
  }

  String _getTypeLabel(TrashItemType type) {
    return switch (type) {
      TrashItemType.note => 'Note',
      TrashItemType.task => 'Task',
      TrashItemType.event => 'Event',
      TrashItemType.post => 'Post',
      TrashItemType.expense => 'Expense',
    };
  }

  Color _getTypeColor(BuildContext context, TrashItemType type) {
    final cs = Theme.of(context).colorScheme;
    return switch (type) {
      TrashItemType.note => Colors.amber,
      TrashItemType.task => cs.primary,
      TrashItemType.event => Colors.teal,
      TrashItemType.post => Colors.purple,
      TrashItemType.expense => Colors.green,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final trashAsync = ref.watch(trashNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, size: 22),
            SizedBox(width: 8),
            Text('Trash'),
          ],
        ),
        actions: [
          trashAsync.maybeWhen(
            data: (items) => items.isNotEmpty
                ? TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Empty Trash?'),
                          content: const Text('All items will be permanently deleted. This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(backgroundColor: cs.error),
                              child: const Text('Empty Trash'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(trashNotifierProvider.notifier).emptyTrash();
                      }
                    },
                    child: Text('Empty', style: TextStyle(color: cs.error, fontWeight: FontWeight.bold)),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            color: cs.surfaceContainerLow,
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Items in Trash are automatically deleted permanently after 20 days.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: trashAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading Trash: $err')),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_sweep_outlined, size: 64, color: cs.onSurfaceVariant.withAlpha(100)),
                        const SizedBox(height: 16),
                        Text('Trash is Empty', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Deleted items will appear here for 20 days.', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final daysLeft = item.expiresAt.difference(DateTime.now()).inDays.clamp(0, 20);
                    final typeColor = _getTypeColor(context, item.itemType);

                    return Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: cs.outlineVariant.withAlpha(40)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Type Icon Container
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: typeColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_getTypeIcon(item.itemType), color: typeColor, size: 20),
                            ),
                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: typeColor.withAlpha(20),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getTypeLabel(item.itemType),
                                          style: tt.labelSmall?.copyWith(color: typeColor, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Deleted ${DateTimeUtils.timeAgo(item.deletedAt)}',
                                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.title,
                                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.snippet != null && item.snippet!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.snippet!,
                                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    '$daysLeft days remaining',
                                    style: tt.bodySmall?.copyWith(color: cs.error, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),

                            // Actions: Restore & Delete Permanently
                            IconButton(
                              icon: const Icon(Icons.restore_from_trash_rounded),
                              color: cs.primary,
                              tooltip: 'Restore',
                              onPressed: () async {
                                await ref.read(trashNotifierProvider.notifier).restoreItem(item);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Restored "${item.title}"')),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever_rounded),
                              color: cs.error,
                              tooltip: 'Delete Permanently',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Permanently?'),
                                    content: Text('Are you sure you want to permanently delete "${item.title}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: FilledButton.styleFrom(backgroundColor: cs.error),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(trashNotifierProvider.notifier).deletePermanently(item.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/widgets/circular_icon_button.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../data/trash_repository.dart';

class TrashScreen extends StatefulWidget {
  final TrashRepository trashRepository;
  final String accountId;

  const TrashScreen({
    super.key,
    required this.trashRepository,
    required this.accountId,
  });

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<MyDayTrashItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    setState(() => _isLoading = true);
    final items = await widget.trashRepository.getTrashItems(widget.accountId);
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreItem(MyDayTrashItem item) async {
    await widget.trashRepository.restoreItem(item);
    _loadTrash();
    if (mounted) {
      UndoToast.show(
        context,
        message: 'Restored',
        actionLabel: 'Undo',
        onUndo: () async {
          await widget.trashRepository.reTrashItem(item);
          _loadTrash();
        },
      );
    }
  }

  Future<void> _purgeItem(MyDayTrashItem item) async {
    await widget.trashRepository.permanentlyDeleteItem(item);
    _loadTrash();
    if (mounted) {
      UndoToast.show(context, message: 'Permanently deleted');
    }
  }

  Future<void> _confirmEmptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          title: Text(
            'Empty Trash?',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete all items in the trash? This action cannot be undone.',
            style: TextStyle(
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Empty All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await widget.trashRepository.emptyAllTrash(widget.accountId);
      _loadTrash();
      if (mounted) {
        UndoToast.show(context, message: 'Trash emptied');
      }
    }
  }

  IconData _iconForType(TrashItemType type) {
    switch (type) {
      case TrashItemType.task:
        return AppIcons.checkSquare;
      case TrashItemType.note:
        return AppIcons.fileText;
      case TrashItemType.transaction:
        return AppIcons.wallet;
      case TrashItemType.feed:
        return AppIcons.image;
      case TrashItemType.file:
        return AppIcons.file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Empty Trash action
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Items are purged after 30 days',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _confirmEmptyTrash,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(AppIcons.trash2, size: 15, color: AppColors.errorRed),
                    label: const Text(
                      'Empty Trash',
                      style: TextStyle(color: AppColors.errorRed, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Trash items card container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.accentOrange),
                    ),
                  )
                : _items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Text(
                            'Trash is empty',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (context, index) => Divider(
                          color: borderColor,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final formattedDate = DateTime.fromMillisecondsSinceEpoch(
                            item.deletedAt,
                          ).toLocal().toString().split(' ')[0];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _iconForType(item.type),
                                    color: textPrimary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '${item.subtitle} · $formattedDate',
                                              style: TextStyle(
                                                color: textMuted,
                                                fontSize: 11.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentOrange.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${item.daysRemaining}d left',
                                              style: const TextStyle(
                                                color: AppColors.accentOrange,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                CircularIconButton(
                                  icon: AppIcons.refreshCw,
                                  size: 32,
                                  iconSize: 15,
                                  onPressed: () => _restoreItem(item),
                                ),
                                const SizedBox(width: 4),
                                CircularIconButton(
                                  icon: AppIcons.x,
                                  size: 32,
                                  iconSize: 15,
                                  onPressed: () => _purgeItem(item),
                                ),
                              ],
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

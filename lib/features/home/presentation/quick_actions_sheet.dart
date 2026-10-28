import 'package:flutter/material.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/widgets/app_bottom_sheet.dart';

class QuickActionsSheet extends StatelessWidget {
  final VoidCallback onAddTask;
  final VoidCallback onAddNote;
  final VoidCallback onAddTransaction;
  final VoidCallback onComposePost;

  const QuickActionsSheet({
    super.key,
    required this.onAddTask,
    required this.onAddNote,
    required this.onAddTransaction,
    required this.onComposePost,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onAddTask,
    required VoidCallback onAddNote,
    required VoidCallback onAddTransaction,
    required VoidCallback onComposePost,
  }) {
    return AppBottomSheet.show(
      context: context,
      title: 'Create new',
      child: QuickActionsSheet(
        onAddTask: onAddTask,
        onAddNote: onAddNote,
        onAddTransaction: onAddTransaction,
        onComposePost: onComposePost,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          _buildActionCard(
            context,
            icon: AppIcons.checkSquare,
            title: 'Task',
            subtitle: 'To-do or timed',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textMuted: textMuted,
            onTap: () {
              Navigator.of(context).pop();
              onAddTask();
            },
          ),
          _buildActionCard(
            context,
            icon: AppIcons.fileText,
            title: 'Note',
            subtitle: 'Notepad editor',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textMuted: textMuted,
            onTap: () {
              Navigator.of(context).pop();
              onAddNote();
            },
          ),
          _buildActionCard(
            context,
            icon: AppIcons.wallet,
            title: 'Transaction',
            subtitle: 'Income or expense',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textMuted: textMuted,
            onTap: () {
              Navigator.of(context).pop();
              onAddTransaction();
            },
          ),
          _buildActionCard(
            context,
            icon: AppIcons.image,
            title: 'Post',
            subtitle: 'Share a moment',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textMuted: textMuted,
            onTap: () {
              Navigator.of(context).pop();
              onComposePost();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.accentOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

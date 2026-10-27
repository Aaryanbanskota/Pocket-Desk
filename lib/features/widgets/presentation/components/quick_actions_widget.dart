import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_icons.dart';
import 'calendar_month_widget.dart';

/// Quick Action Capture Widget for Home Screen
/// Provides 1-tap shortcuts: + Task, + Note, + Moment/Camera, + Expense
class QuickActionsWidget extends StatelessWidget {
  final WidgetSize size;
  final bool isDarkMode;
  final VoidCallback? onTaskAction;
  final VoidCallback? onNoteAction;
  final VoidCallback? onMomentAction;
  final VoidCallback? onExpenseAction;

  const QuickActionsWidget({
    super.key,
    this.size = WidgetSize.medium,
    this.isDarkMode = false,
    this.onTaskAction,
    this.onNoteAction,
    this.onMomentAction,
    this.onExpenseAction,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFFFFFDF9);
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF1C1917);
    final textMuted = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF78716C);
    final borderColor = isDarkMode ? const Color(0xFF2E2E34) : const Color(0xFFE7E5E4);
    final surface2 = isDarkMode ? const Color(0xFF282830) : const Color(0xFFF5F3EF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: size == WidgetSize.small
          ? _buildSmall(textPrimary, textMuted, surface2)
          : _buildMediumOrLarge(textPrimary, textMuted, surface2),
    );
  }

  Widget _buildSmall(Color textPrimary, Color textMuted, Color surface2) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(AppIcons.widget, size: 14, color: AppColors.accentOrange),
                const SizedBox(width: 5),
                Text(
                  'Capture',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                ),
              ],
            ),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981)),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              label: 'Task',
              icon: AppIcons.tasks,
              color: AppColors.accentOrange,
              surface2: surface2,
              textPrimary: textPrimary,
              onTap: onTaskAction,
              compact: true,
            ),
            _buildActionButton(
              label: 'Note',
              icon: AppIcons.notes,
              color: const Color(0xFF06B6D4),
              surface2: surface2,
              textPrimary: textPrimary,
              onTap: onNoteAction,
              compact: true,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              label: 'Moment',
              icon: AppIcons.feed,
              color: const Color(0xFF8B5CF6),
              surface2: surface2,
              textPrimary: textPrimary,
              onTap: onMomentAction,
              compact: true,
            ),
            _buildActionButton(
              label: 'Expense',
              icon: AppIcons.wallet,
              color: const Color(0xFF10B981),
              surface2: surface2,
              textPrimary: textPrimary,
              onTap: onExpenseAction,
              compact: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediumOrLarge(Color textPrimary, Color textMuted, Color surface2) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(AppIcons.widget, size: 15, color: AppColors.accentOrange),
                const SizedBox(width: 6),
                Text(
                  'Quick Capture',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ready',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(
              label: 'Task',
              icon: AppIcons.tasks,
              color: AppColors.accentOrange,
              surface2: surface2,
              textPrimary: textPrimary,
              onTap: onTaskAction,
            ),
            _buildActionButton(
              label: 'Note',
              icon: AppIcons.notes,
              color: const Color(0xFF06B6D4),
              surface2: surface2,
              textPrimary: textPrimary,
              onTap: onNoteAction,
            ),
            _buildActionButton(
              label: 'Moment',
              icon: AppIcons.feed,
              color: const Color(0xFF8B5CF6),
              surface2: surface2,
              textPrimary: textPrimary,
              onTap: onMomentAction,
            ),
            _buildActionButton(
              label: 'Expense',
              icon: AppIcons.wallet,
              color: const Color(0xFF10B981),
              surface2: surface2,
              textPrimary: textPrimary,
              onTap: onExpenseAction,
            ),
          ],
        ),

        // Bottom Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: surface2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Tap to capture instantly',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: textMuted, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Offline Sync',
                style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color surface2,
    required Color textPrimary,
    VoidCallback? onTap,
    bool compact = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 38 : 44,
            height: compact ? 38 : 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: compact ? 16 : 20, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

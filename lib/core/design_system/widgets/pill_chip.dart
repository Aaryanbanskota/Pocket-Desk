import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_typography.dart';

/// Pill Chip (.ch in prototype) with active and inactive states
class PillChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? leading;
  final EdgeInsetsGeometry padding;

  const PillChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leading,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final bgColor = isSelected
        ? (isDark ? AppColors.darkText : AppColors.lightText)
        : Colors.transparent;

    final textColor = isSelected
        ? (isDark ? AppColors.darkBg : AppColors.lightBg)
        : context.appMuted;

    final borderColor = isSelected
        ? (isDark ? AppColors.darkText : AppColors.lightText)
        : context.appLine;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.bodyBold.copyWith(
                color: textColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

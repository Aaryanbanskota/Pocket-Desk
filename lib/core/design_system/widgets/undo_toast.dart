import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_typography.dart';

class UndoToast {
  static void show(
    BuildContext context, {
    required String message,
    VoidCallback? onUndo,
    String actionLabel = 'Undo',
    Duration duration = const Duration(seconds: 4),
  }) {
    final isDark = context.isDarkMode;
    final toastBg = isDark ? AppColors.darkText : AppColors.lightText;
    final toastText = isDark ? AppColors.darkBg : AppColors.lightBg;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(22, 0, 22, 90),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: toastBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyBold.copyWith(
                    color: toastText,
                    fontSize: 14,
                  ),
                ),
              ),
              if (onUndo != null)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onUndo();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'Undo',
                      style: AppTypography.bodyBold.copyWith(
                        color: AppColors.accent,
                        fontSize: 14,
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

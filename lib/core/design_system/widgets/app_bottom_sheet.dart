import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_icons.dart';
import '../app_typography.dart';
import 'circular_icon_button.dart';

/// Reusable modal sheet matching prototype .sb
class AppBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    Widget? child,
    Widget Function(BuildContext sheetContext)? builder,
    bool showClose = true,
  }) {
    assert(child != null || builder != null, 'Either child or builder must be provided');

    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final screenHeight = MediaQuery.of(sheetContext).size.height;
        final sheetSurface = sheetContext.appSurface;
        final sheetLine = sheetContext.appLine;

        return Material(
          color: sheetSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.88,
            ),
            padding: EdgeInsets.fromLTRB(
              22,
              14,
              22,
              MediaQuery.of(sheetContext).viewInsets.bottom +
                  MediaQuery.of(sheetContext).padding.bottom +
                  22,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Grab handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: sheetLine,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.h3.copyWith(color: sheetContext.appText),
                    ),
                    if (showClose)
                      CircularIconButton(
                        icon: AppIcons.close,
                        customColor: sheetContext.appSurface2,
                        size: 34,
                        iconSize: 18,
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: builder != null ? builder(sheetContext) : child!,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

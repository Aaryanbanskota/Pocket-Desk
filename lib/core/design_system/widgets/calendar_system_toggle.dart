import 'package:flutter/material.dart';
import '../app_colors.dart';

class CalendarSystemToggle extends StatelessWidget {
  final bool isBS;
  final ValueChanged<bool> onChanged;
  final bool isCreamContext;

  const CalendarSystemToggle({
    super.key,
    required this.isBS,
    required this.onChanged,
    this.isCreamContext = true,
  });

  @override
  Widget build(BuildContext context) {
    final creamText = context.appCreamText;
    final activeBg = isCreamContext
        ? AppColors.accent
        : AppColors.accent;
    const activeText = Colors.white;
    final inactiveText = isCreamContext
        ? creamText.withValues(alpha: 0.6)
        : (Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.5));
    final containerBg = isCreamContext
        ? creamText.withValues(alpha: 0.08)
        : (Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06));

    return Container(
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPill(
            label: 'AD',
            isActive: !isBS,
            activeBg: activeBg,
            activeText: activeText,
            inactiveText: inactiveText,
            onTap: () => onChanged(false),
          ),
          _buildPill(
            label: 'BS',
            isActive: isBS,
            activeBg: activeBg,
            activeText: activeText,
            inactiveText: inactiveText,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required bool isActive,
    required Color activeBg,
    required Color activeText,
    required Color inactiveText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeBg.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? activeText : inactiveText,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

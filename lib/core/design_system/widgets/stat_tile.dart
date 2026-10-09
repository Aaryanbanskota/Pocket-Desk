import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_typography.dart';

/// Stat Tile (.tile in prototype)
class StatTile extends StatefulWidget {
  final String caption;
  final String value;
  final Widget? subtitle;
  final Widget? trailingContent;
  final bool isGradient;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.caption,
    required this.value,
    this.subtitle,
    this.trailingContent,
    this.isGradient = false,
    this.onTap,
  });

  @override
  State<StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<StatTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isGradient
        ? null
        : context.appSurface;

    final textColor = widget.isGradient
        ? Colors.white
        : context.appText;

    final captionColor = widget.isGradient
        ? Colors.white.withValues(alpha: 0.7)
        : context.appMuted;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bgColor,
            gradient: widget.isGradient ? AppColors.netWorthGradient : null,
            borderRadius: BorderRadius.circular(24),
            border: widget.isGradient
                ? null
                : Border.all(color: context.appLine, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.caption.toUpperCase(),
                style: AppTypography.caption.copyWith(color: captionColor),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.value,
                  style: AppTypography.tileNum.copyWith(
                    color: textColor,
                    fontSize: widget.isGradient ? 22 : 32,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (widget.trailingContent != null)
                widget.trailingContent!
              else if (widget.subtitle != null)
                widget.subtitle!,
            ],
          ),
        ),
      ),
    );
  }
}

/// 10-Dot Progress Indicator (.dotrow in prototype)
class TenDotProgressRow extends StatelessWidget {
  final int completedPercent; // 0 to 100
  final double dotSize;
  final double spacing;

  const TenDotProgressRow({
    super.key,
    required this.completedPercent,
    this.dotSize = 13,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = (completedPercent / 10).round().clamp(0, 10);
    final inactiveColor = context.appSurface2;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (int i = 0; i < 10; i++)
          AnimatedContainer(
            duration: Duration(milliseconds: 180 + (i * 25)),
            curve: Curves.easeOutCubic,
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < activeCount ? AppColors.success : inactiveColor,
            ),
          ),
      ],
    );
  }
}

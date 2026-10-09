import 'package:flutter/material.dart';
import '../app_colors.dart';

/// Reusable circular button (.rb in prototype) 40x40px
class CircularIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isSolidWhite;
  final bool isFilled;
  final Color? customColor;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const CircularIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isSolidWhite = false,
    this.isFilled = false,
    this.customColor,
    this.iconColor,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  State<CircularIconButton> createState() => _CircularIconButtonState();
}

class _CircularIconButtonState extends State<CircularIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isWhite = widget.isSolidWhite || widget.isFilled;
    final bgColor = isWhite
        ? (isDark ? AppColors.darkText : AppColors.lightText)
        : widget.customColor ?? context.appSurface;

    final defaultIconColor = isWhite
        ? (isDark ? AppColors.darkBg : AppColors.lightBg)
        : context.appText;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: widget.isSolidWhite
                ? null
                : Border.all(
                    color: context.appLine,
                    width: 1.0,
                  ),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: widget.iconColor ?? defaultIconColor,
            ),
          ),
        ),
      ),
    );
  }
}

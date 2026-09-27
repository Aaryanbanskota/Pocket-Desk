import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom widget rendering the Cardano/AI radial dots pattern (Cardano emblem / AI matrix dots).
/// Can be animated (pulsing / rotating) while AI is thinking/typing or static as a badge.
class AiCardanoDotsWidget extends StatefulWidget {
  const AiCardanoDotsWidget({
    super.key,
    this.size = 64.0,
    this.color,
    this.animate = true,
  });

  final double size;
  final Color? color;
  final bool animate;

  @override
  State<AiCardanoDotsWidget> createState() => _AiCardanoDotsWidgetState();
}

class _AiCardanoDotsWidgetState extends State<AiCardanoDotsWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AiCardanoDotsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AiCardanoDotsPainter(
            color: effectiveColor,
            progress: widget.animate ? _controller.value : 0.0,
          ),
        );
      },
    );
  }
}

class _AiCardanoDotsPainter extends CustomPainter {
  _AiCardanoDotsPainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Center main dot
    final centerDotRadius = baseRadius * 0.22 * (1.0 + 0.05 * math.sin(progress * 2 * math.pi));
    canvas.drawCircle(center, centerDotRadius, paint);

    // Inner ring (4 large dots arranged diagonally/orthogonally)
    const innerCount = 4;
    final innerDistance = baseRadius * 0.38;
    final innerDotRadius = baseRadius * 0.16;
    final rotationOffset = progress * 2 * math.pi;

    for (int i = 0; i < innerCount; i++) {
      final angle = (i * math.pi / 2) + (math.pi / 4) + (progress * math.pi * 0.5);
      final offset = Offset(
        center.dx + innerDistance * math.cos(angle),
        center.dy + innerDistance * math.sin(angle),
      );
      final pulse = 1.0 + 0.1 * math.sin(rotationOffset + i);
      canvas.drawCircle(offset, innerDotRadius * pulse, paint);
    }

    // Middle ring (8 medium dots)
    const midCount = 8;
    final midDistance = baseRadius * 0.62;
    final midDotRadius = baseRadius * 0.10;

    for (int i = 0; i < midCount; i++) {
      final angle = (i * math.pi / 4) - (progress * math.pi * 0.5);
      final offset = Offset(
        center.dx + midDistance * math.cos(angle),
        center.dy + midDistance * math.sin(angle),
      );
      final pulse = 1.0 + 0.12 * math.sin(rotationOffset + i * 0.5);
      canvas.drawCircle(offset, midDotRadius * pulse, paint);
    }

    // Outer ring (12 small dots)
    const outerCount = 12;
    final outerDistance = baseRadius * 0.86;
    final outerDotRadius = baseRadius * 0.045;

    for (int i = 0; i < outerCount; i++) {
      final angle = (i * math.pi / 6) + (progress * math.pi * 0.25);
      final offset = Offset(
        center.dx + outerDistance * math.cos(angle),
        center.dy + outerDistance * math.sin(angle),
      );
      final pulse = 1.0 + 0.2 * math.cos(rotationOffset + i);
      canvas.drawCircle(offset, outerDotRadius * pulse, paint);
    }
  }

  @override
  bool shouldRepaint(_AiCardanoDotsPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom mascot widget representing the Pocket AI Chef/Cloud mascot.
/// Inspired by the vibrant scalloped mascot silhouette with twin vertical capsule eyes.
class AiChefMascotWidget extends StatefulWidget {
  final double size;
  final Color? color;
  final Color? eyeColor;
  final bool animate;

  const AiChefMascotWidget({
    super.key,
    this.size = 32,
    this.color,
    this.eyeColor,
    this.animate = true,
  });

  @override
  State<AiChefMascotWidget> createState() => _AiChefMascotWidgetState();
}

class _AiChefMascotWidgetState extends State<AiChefMascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AiChefMascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
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
    final theme = Theme.of(context);
    final mascotColor = widget.color ?? const Color(0xFF00E676);
    final eyeColor = widget.eyeColor ?? theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatOffset = widget.animate
            ? math.sin(_controller.value * math.pi) * (widget.size * 0.04)
            : 0.0;
        final scalePulse = widget.animate
            ? 1.0 + math.sin(_controller.value * math.pi) * 0.02
            : 1.0;

        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: Transform.scale(
            scale: scalePulse,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _AiChefMascotPainter(
                mascotColor: mascotColor,
                eyeColor: eyeColor,
                animValue: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AiChefMascotPainter extends CustomPainter {
  final Color mascotColor;
  final Color eyeColor;
  final double animValue;

  _AiChefMascotPainter({
    required this.mascotColor,
    required this.eyeColor,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Paints
    final bodyPaint = Paint()
      ..color = mascotColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Draw Bottom Stand / Base Bar
    final baseBarHeight = h * 0.10;
    final baseBarWidth = w * 0.55;
    final baseBarRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.92),
        width: baseBarWidth,
        height: baseBarHeight,
      ),
      Radius.circular(baseBarHeight / 2),
    );
    canvas.drawRRect(baseBarRRect, bodyPaint);

    // 2. Draw Chef / Cloud Scalloped Head
    final headPath = Path();
    final center = Offset(w * 0.5, h * 0.44);

    // Head base boundary
    final headRect = Rect.fromCenter(
      center: center,
      width: w * 0.88,
      height: h * 0.72,
    );

    // Main rounded head base
    headPath.addRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.28)),
    );

    // Top cloud puffy lobes (Scalloped chef hat shape)
    // Center Top Lobe
    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.50, h * 0.22),
      radius: w * 0.26,
    ));

    // Top Left Lobe
    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.28, h * 0.28),
      radius: w * 0.22,
    ));

    // Top Right Lobe
    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.72, h * 0.28),
      radius: w * 0.22,
    ));

    // Side Left Lobe
    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.18, h * 0.48),
      radius: w * 0.18,
    ));

    // Side Right Lobe
    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.82, h * 0.48),
      radius: w * 0.18,
    ));

    canvas.drawPath(headPath, bodyPaint);

    // 3. Draw Vertical Capsule Eyes
    final eyeWidth = w * 0.12;
    final eyeHeight = h * 0.26;
    final eyeY = h * 0.42;

    final leftEyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.38, eyeY),
        width: eyeWidth,
        height: eyeHeight,
      ),
      Radius.circular(eyeWidth / 2),
    );

    final rightEyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.62, eyeY),
        width: eyeWidth,
        height: eyeHeight,
      ),
      Radius.circular(eyeWidth / 2),
    );

    canvas.drawRRect(leftEyeRect, eyePaint);
    canvas.drawRRect(rightEyeRect, eyePaint);
  }

  @override
  bool shouldRepaint(_AiChefMascotPainter oldDelegate) {
    return oldDelegate.mascotColor != mascotColor ||
        oldDelegate.eyeColor != eyeColor ||
        oldDelegate.animValue != animValue;
  }
}

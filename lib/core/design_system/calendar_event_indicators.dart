import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../features/tasks/data/tasks_repository.dart';

/// Curated distinct vibrant palette for events
const List<Color> kEventPalette = [
  Color(0xFF3B82F6), // Blue
  Color(0xFF10B981), // Emerald
  Color(0xFF8B5CF6), // Violet
  Color(0xFFEC4899), // Pink
  Color(0xFF06B6D4), // Cyan
  Color(0xFFF59E0B), // Amber
  Color(0xFF6366F1), // Indigo
  Color(0xFF14B8A6), // Teal
  Color(0xFFEF4444), // Crimson
  Color(0xFF84CC16), // Lime
];

/// Returns a distinct vibrant color for an event/task.
/// Tags take precedence, followed by importance, followed by a deterministic
/// hash of title/id to ensure multiple untagged tasks receive distinct colors.
Color getEventColor(MyDayTask task) {
  if (task.tags.isNotEmpty) {
    for (final tag in task.tags) {
      final lower = tag.toLowerCase().trim();
      if (lower.contains('work') || lower.contains('job') || lower.contains('office')) {
        return const Color(0xFF3B82F6);
      }
      if (lower.contains('personal') || lower.contains('life') || lower.contains('routine')) {
        return const Color(0xFF10B981);
      }
      if (lower.contains('study') || lower.contains('school') || lower.contains('learn') || lower.contains('read')) {
        return const Color(0xFF8B5CF6);
      }
      if (lower.contains('health') || lower.contains('gym') || lower.contains('fit') || lower.contains('med')) {
        return const Color(0xFF06B6D4);
      }
      if (lower.contains('urgent') || lower.contains('asap') || lower.contains('important') || lower.contains('critical')) {
        return const Color(0xFFEF4444);
      }
      if (lower.contains('finance') || lower.contains('money') || lower.contains('budget') || lower.contains('pay')) {
        return const Color(0xFF14B8A6);
      }
      if (lower.contains('home') || lower.contains('family') || lower.contains('house')) {
        return const Color(0xFFEC4899);
      }
      if (lower.contains('focus')) {
        return const Color(0xFFFF8A4C);
      }
      if (lower.contains('event') || lower.contains('meeting') || lower.contains('call') || lower.contains('sync')) {
        return const Color(0xFFF59E0B);
      }
      if (lower.contains('design') || lower.contains('creative') || lower.contains('art')) {
        return const Color(0xFFD946EF);
      }
      if (lower.contains('travel') || lower.contains('trip') || lower.contains('flight')) {
        return const Color(0xFF6366F1);
      }
    }
  }

  if (task.isImportant) {
    return const Color(0xFFEF4444);
  }

  // Fallback to deterministic vibrant color derived from title / id hash
  final seedStr = task.title.trim().isNotEmpty ? task.title.trim() : task.id;
  final index = seedStr.hashCode.abs() % kEventPalette.length;
  return kEventPalette[index];
}

/// Custom painter for rendering multi-event segmented rings around date numbers
class SegmentedRingPainter extends CustomPainter {
  final List<Color> colors;
  final double strokeWidth;
  final double gap;

  const SegmentedRingPainter({
    required this.colors,
    this.strokeWidth = 2.0,
    this.gap = 0.20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    if (radius <= 0) return;

    if (colors.length == 1) {
      final paint = Paint()
        ..color = colors.first
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    // Limit to max 6 segments for clear visibility
    final displayColors = colors.length > 6 ? colors.sublist(0, 6) : colors;
    final count = displayColors.length;
    const totalAngle = 2 * math.pi;
    final effectiveGap = math.min(gap, totalAngle / (count * 3.5));
    final sweepAngle = (totalAngle / count) - effectiveGap;

    for (int i = 0; i < count; i++) {
      final startAngle = -math.pi / 2 + (i * totalAngle / count) + (effectiveGap / 2);
      final paint = Paint()
        ..color = displayColors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SegmentedRingPainter oldDelegate) {
    if (oldDelegate.strokeWidth != strokeWidth || oldDelegate.gap != gap) return true;
    if (oldDelegate.colors.length != colors.length) return true;
    for (int i = 0; i < colors.length; i++) {
      if (oldDelegate.colors[i] != colors[i]) return true;
    }
    return false;
  }
}

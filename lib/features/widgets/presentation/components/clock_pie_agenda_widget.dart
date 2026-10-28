import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_icons.dart';
import 'calendar_month_widget.dart';

/// Single item representing a scheduled task or event in the Clock Pie Agenda
class ClockPieTaskItem {
  final String id;
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Color color;
  final bool isCompleted;
  final String category;

  const ClockPieTaskItem({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.isCompleted = false,
    this.category = 'Task',
  });

  int get startMinutes => (startTime.hour % 12) * 60 + startTime.minute;
  int get endMinutes => (endTime.hour % 12) * 60 + endTime.minute;

  int get durationMinutes {
    final d = endMinutes - startMinutes;
    return d > 0 ? d : d + 12 * 60;
  }

  String get timeFormatted {
    final sH = startTime.hour % 12 == 0 ? 12 : startTime.hour % 12;
    final sM = startTime.minute.toString().padLeft(2, '0');
    final sPeriod = startTime.hour >= 12 ? 'PM' : 'AM';

    final eH = endTime.hour % 12 == 0 ? 12 : endTime.hour % 12;
    final eM = endTime.minute.toString().padLeft(2, '0');
    final ePeriod = endTime.hour >= 12 ? 'PM' : 'AM';

    return '$sH:$sM $sPeriod – $eH:$eM $ePeriod';
  }

  bool isCurrent(DateTime now) {
    final nowMinutes = (now.hour % 12) * 60 + now.minute;
    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }
}

/// Circular Clock Pie Agenda Widget ("Day Dial")
/// A circular clock face with accurate live hands (small hour, medium minute, large second),
/// numerals 1..12, and a background pie chart showing today's tasks and events.
/// Supports Small (2x2), Medium (4x2), and Large (4x4) sizes in Light & Dark modes.
class ClockPieAgendaWidget extends StatefulWidget {
  final WidgetSize size;
  final bool isDarkMode;
  final List<ClockPieTaskItem>? tasks;
  final VoidCallback? onTap;
  final VoidCallback? onAddTask;

  const ClockPieAgendaWidget({
    super.key,
    this.size = WidgetSize.medium,
    this.isDarkMode = false,
    this.tasks,
    this.onTap,
    this.onAddTask,
  });

  @override
  State<ClockPieAgendaWidget> createState() => _ClockPieAgendaWidgetState();
}

class _ClockPieAgendaWidgetState extends State<ClockPieAgendaWidget> {
  Timer? _ticker;
  DateTime _now = DateTime.now();
  late List<ClockPieTaskItem> _items;

  @override
  void initState() {
    super.initState();
    _initTasks();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void didUpdateWidget(covariant ClockPieAgendaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks) {
      _items = widget.tasks != null ? List.from(widget.tasks!) : [];
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _initTasks() {
    _items = widget.tasks != null ? List.from(widget.tasks!) : [];
  }

  ClockPieTaskItem? get _currentActiveTask {
    for (final t in _items) {
      if (t.isCurrent(_now)) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFFFFFDF9);
    final textPrimary = widget.isDarkMode ? Colors.white : const Color(0xFF1C1917);
    final textMuted = widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF78716C);
    final borderColor = widget.isDarkMode ? const Color(0xFF2E2E34) : const Color(0xFFE7E5E4);
    final surface2 = widget.isDarkMode ? const Color(0xFF282830) : const Color(0xFFF5F3EF);
    const accent = AppColors.accentOrange;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.35 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _buildLayout(context, textPrimary, textMuted, borderColor, surface2, accent),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
    Color accent,
  ) {
    switch (widget.size) {
      case WidgetSize.small:
        return _buildSmall(textPrimary, textMuted, surface2, accent);
      case WidgetSize.medium:
        return _buildMedium(textPrimary, textMuted, borderColor, surface2, accent);
      case WidgetSize.large:
        return _buildLarge(textPrimary, textMuted, borderColor, surface2, accent);
    }
  }

  // --- Small (2x2) View ---
  Widget _buildSmall(Color textPrimary, Color textMuted, Color surface2, Color accent) {
    final active = _currentActiveTask;

    return Column(
      children: [
        // Top compact header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(AppIcons.clock, size: 12, color: AppColors.accentOrange),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'DAY DIAL',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Center Dial
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: CustomPaint(
                painter: ClockPiePainter(
                  time: _now,
                  tasks: _items,
                  isDarkMode: widget.isDarkMode,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  accentColor: accent,
                  showAllNumbers: false,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Bottom active task pill
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active != null ? active.color.withValues(alpha: 0.4) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active?.color ?? textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  active?.title ?? 'No active task now',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: active != null ? textPrimary : textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Medium (4x2) View ---
  Widget _buildMedium(
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
    Color accent,
  ) {
    return Row(
      children: [
        // Left Column: Clock Dial
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(AppIcons.clock, size: 12, color: AppColors.accentOrange),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'DAY DIAL',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_items.length} Tasks',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: CustomPaint(
                      painter: ClockPiePainter(
                        time: _now,
                        tasks: _items,
                        isDarkMode: widget.isDarkMode,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        accentColor: accent,
                        showAllNumbers: true,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),
        Container(width: 1, color: borderColor),
        const SizedBox(width: 12),

        // Right Column: Today's Tasks Feed
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Today\'s Schedule',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Task List
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Text(
                          'No tasks on dial',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      )
                    : ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 5),
                  itemBuilder: (context, idx) {
                    final item = _items[idx];
                    final isNow = item.isCurrent(_now);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: isNow ? item.color.withValues(alpha: 0.15) : surface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isNow ? item.color : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.color,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isNow ? FontWeight.w800 : FontWeight.w600,
                                    color: textPrimary,
                                    decoration: item.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                Text(
                                  item.timeFormatted,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isNow ? item.color : textMuted,
                                    fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item.isCompleted)
                            const Icon(Icons.check_circle, size: 14, color: AppColors.success)
                          else if (isNow)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: item.color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NOW',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Large (4x4) View ---
  Widget _buildLarge(
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
    Color accent,
  ) {
    final active = _currentActiveTask;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(AppIcons.clock, size: 16, color: AppColors.accentOrange),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day Dial Agenda',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Live 12-Hour Pie Chart Schedule',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.5, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTimeOfDay(_now),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                if (widget.onAddTask != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: widget.onAddTask,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(AppIcons.plus, size: 12, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Prominent Dial Showcase
        SizedBox(
          height: 175,
          child: Row(
            children: [
              // Large Dial
              Expanded(
                flex: 5,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: CustomPaint(
                      painter: ClockPiePainter(
                        time: _now,
                        tasks: _items,
                        isDarkMode: widget.isDarkMode,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        accentColor: accent,
                        showAllNumbers: true,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Active / Next Status Card
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: active != null ? active.color.withValues(alpha: 0.5) : borderColor,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (active?.color ?? accent).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                active != null ? 'CURRENT TASK' : 'UPCOMING NEXT',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: active?.color ?? accent,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        active?.title ?? 'All sessions complete',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        active?.timeFormatted ?? 'Take a breather & plan ahead',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: active?.color ?? textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress ring / bar indicator
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: active != null ? 0.65 : 1.0,
                          backgroundColor: borderColor,
                          valueColor: AlwaysStoppedAnimation<Color>(active?.color ?? accent),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Container(height: 1, color: borderColor),
        const SizedBox(height: 8),

        // Bottom Schedule List
        Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available_rounded, size: 26, color: textMuted),
                      const SizedBox(height: 6),
                      Text(
                        'No scheduled tasks on dial',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap Add to schedule a task or event',
                        style: TextStyle(fontSize: 10.5, color: textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, idx) {
              final item = _items[idx];
              final isNow = item.isCurrent(_now);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isNow ? item.color.withValues(alpha: 0.15) : surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isNow ? item.color : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isNow ? FontWeight.w800 : FontWeight.w600,
                                color: textPrimary,
                                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.timeFormatted,
                            style: TextStyle(
                              fontSize: 10,
                              color: isNow ? item.color : textMuted,
                              fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (item.isCompleted)
                      const Icon(Icons.check_circle, size: 15, color: AppColors.success)
                    else if (isNow)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NOW',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTimeOfDay(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m:$s $period';
  }
}

/// CustomPainter that renders:
/// 1. Dial bezel, outer ring, tick marks, and hour numerals (1..12).
/// 2. Background task pie/donut sectors matching task start/end times.
/// 3. Accurate live hands:
///    - Small hour hand
///    - Medium minute hand
///    - Large second hand needle with counterweight and center pivot.
class ClockPiePainter extends CustomPainter {
  final DateTime time;
  final List<ClockPieTaskItem> tasks;
  final bool isDarkMode;
  final Color textPrimary;
  final Color textMuted;
  final Color accentColor;
  final bool showAllNumbers;

  ClockPiePainter({
    required this.time,
    required this.tasks,
    required this.isDarkMode,
    required this.textPrimary,
    required this.textMuted,
    required this.accentColor,
    required this.showAllNumbers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;

    if (radius <= 0) return;

    final innerRadius = radius * 0.40;
    final outerRadius = radius * 0.86;

    // 1. Dial Background
    final dialBgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF16161A) : const Color(0xFFF9F8F6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dialBgPaint);

    // 2. Background Sector Ring Track (Muted placeholder for unscheduled hours)
    final trackPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerRadius - innerRadius;
    canvas.drawCircle(center, (innerRadius + outerRadius) / 2, trackPaint);

    // 3. Draw Task Pie / Donut Sectors
    for (final task in tasks) {
      final sMin = task.startMinutes;
      final dMin = task.durationMinutes;

      // Map 12-hour clock: 720 minutes = 2*PI radians. Top 12:00 = -PI/2.
      final startAngle = (sMin / 720.0) * 2 * math.pi - math.pi / 2;
      final sweepAngle = (dMin / 720.0) * 2 * math.pi;

      if (sweepAngle <= 0.01) continue;

      // Small gap between adjacent sectors for ultra-crisp modern look
      final gap = sweepAngle > 0.1 ? 0.025 : 0.005;
      final drawStart = startAngle + gap / 2;
      final drawSweep = sweepAngle - gap;

      final isCurrent = task.isCurrent(time);

      final sectorPath = Path();
      sectorPath.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        drawStart,
        drawSweep,
        false,
      );
      sectorPath.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        drawStart + drawSweep,
        -drawSweep,
        false,
      );
      sectorPath.close();

      final sectorPaint = Paint()
        ..color = task.color.withValues(
          alpha: task.isCompleted ? 0.55 : (isCurrent ? 0.95 : 0.80),
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(sectorPath, sectorPaint);

      // Active task highlight glow outline
      if (isCurrent) {
        final glowPaint = Paint()
          ..color = task.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawPath(sectorPath, glowPaint);
      }
    }

    // 4. Outer Bezel & Minute/Hour Ticks
    final bezelPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, bezelPaint);

    // Hour and Minute Ticks
    final hourTickPaint = Paint()
      ..color = textPrimary.withValues(alpha: 0.6)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final minTickPaint = Paint()
      ..color = textMuted.withValues(alpha: 0.3)
      ..strokeWidth = 0.8;

    for (int i = 0; i < 60; i++) {
      final angle = (i / 60.0) * 2 * math.pi - math.pi / 2;
      final isHourTick = i % 5 == 0;

      final r1 = isHourTick ? radius * 0.90 : radius * 0.93;
      final r2 = radius * 0.97;

      final p1 = Offset(center.dx + r1 * math.cos(angle), center.dy + r1 * math.sin(angle));
      final p2 = Offset(center.dx + r2 * math.cos(angle), center.dy + r2 * math.sin(angle));

      canvas.drawLine(p1, p2, isHourTick ? hourTickPaint : minTickPaint);
    }

    // 5. Hour Numerals (1..12)
    final numRadius = outerRadius * 0.82;
    final fontSize = (radius * 0.15).clamp(9.5, 14.5);

    for (int h = 1; h <= 12; h++) {
      if (!showAllNumbers && (h != 12 && h != 3 && h != 6 && h != 9)) {
        continue;
      }

      final angle = (h / 12.0) * 2 * math.pi - math.pi / 2;
      final numPos = Offset(
        center.dx + numRadius * math.cos(angle),
        center.dy + numRadius * math.sin(angle),
      );

      final isCardinal = (h == 12 || h == 3 || h == 6 || h == 9);

      final textSpan = TextSpan(
        text: '$h',
        style: TextStyle(
          color: isCardinal ? textPrimary : textMuted,
          fontSize: isCardinal ? fontSize * 1.05 : fontSize,
          fontWeight: isCardinal ? FontWeight.w800 : FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(numPos.dx - textPainter.width / 2, numPos.dy - textPainter.height / 2),
      );
    }

    // 6. Center Hub Cutout
    final hubRadius = innerRadius * 0.92;
    final hubBgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF1E1E24) : const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, hubRadius, hubBgPaint);

    final hubBorderPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, hubRadius, hubBorderPaint);

    // 7. Accurate Live Clock Hands
    final hourAngle =
        (((time.hour % 12) + time.minute / 60.0 + time.second / 3600.0) / 12.0) * 2 * math.pi -
            math.pi / 2;
    final minAngle =
        ((time.minute + time.second / 60.0) / 60.0) * 2 * math.pi - math.pi / 2;
    final secAngle = (time.second / 60.0) * 2 * math.pi - math.pi / 2;

    // Hand Dimensions
    final hourHandLength = radius * 0.44;
    final minHandLength = radius * 0.66;
    final secHandLength = radius * 0.82;
    final secTailLength = radius * 0.18;

    // Small Hand: Hour Hand
    final hourHandPaint = Paint()
      ..color = textPrimary
      ..strokeWidth = radius > 60 ? 3.4 : 2.4
      ..strokeCap = StrokeCap.round;

    final hourTip = Offset(
      center.dx + hourHandLength * math.cos(hourAngle),
      center.dy + hourHandLength * math.sin(hourAngle),
    );
    canvas.drawLine(center, hourTip, hourHandPaint);

    // Medium Hand: Minute Hand
    final minHandPaint = Paint()
      ..color = textPrimary.withValues(alpha: 0.9)
      ..strokeWidth = radius > 60 ? 2.2 : 1.6
      ..strokeCap = StrokeCap.round;

    final minTip = Offset(
      center.dx + minHandLength * math.cos(minAngle),
      center.dy + minHandLength * math.sin(minAngle),
    );
    canvas.drawLine(center, minTip, minHandPaint);

    // Large Hand: Second Hand Needle (Accent Color with Counterweight Tail)
    final secHandPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final secTip = Offset(
      center.dx + secHandLength * math.cos(secAngle),
      center.dy + secHandLength * math.sin(secAngle),
    );
    final secTail = Offset(
      center.dx - secTailLength * math.cos(secAngle),
      center.dy - secTailLength * math.sin(secAngle),
    );
    canvas.drawLine(secTail, secTip, secHandPaint);

    // Center Pivot Hub Cap
    final pivotCapPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius > 60 ? 4.0 : 3.0, pivotCapPaint);

    final innerPinPaint = Paint()
      ..color = isDarkMode ? Colors.black : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius > 60 ? 1.5 : 1.0, innerPinPaint);
  }

  @override
  bool shouldRepaint(covariant ClockPiePainter oldDelegate) {
    return oldDelegate.time.second != time.second ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.tasks != tasks;
  }
}

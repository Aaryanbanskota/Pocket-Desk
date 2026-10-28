import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_icons.dart';
import '../../../tasks/data/tasks_repository.dart';

enum WidgetSize { small, medium, large }

/// Calendar Widget (.calendarWidget) matching MyDay design system
/// Supports Small (2x2), Medium (4x2), Large (4x4) in Light & Dark modes
class CalendarMonthWidget extends StatelessWidget {
  final WidgetSize size;
  final bool isDarkMode;
  final DateTime? currentDate;
  final List<MyDayTask> events;
  final VoidCallback? onTap;

  const CalendarMonthWidget({
    super.key,
    this.size = WidgetSize.medium,
    this.isDarkMode = false,
    this.currentDate,
    this.events = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = currentDate ?? DateTime(2026, 10, 19);
    final cardBg = isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFFFFFDF9);
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF1C1917);
    final textMuted = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF78716C);
    final borderColor = isDarkMode ? const Color(0xFF2E2E34) : const Color(0xFFE7E5E4);
    final surface2 = isDarkMode ? const Color(0xFF282830) : const Color(0xFFF5F3EF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _buildLayout(context, now, textPrimary, textMuted, borderColor, surface2),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    DateTime now,
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
  ) {
    switch (size) {
      case WidgetSize.small:
        return _buildSmallLayout(now, textPrimary, textMuted, surface2);
      case WidgetSize.medium:
        return _buildMediumLayout(now, textPrimary, textMuted, borderColor, surface2);
      case WidgetSize.large:
        return _buildLargeLayout(now, textPrimary, textMuted, borderColor, surface2);
    }
  }

  // --- Small (2x2): Compact Monthly Calendar Snapshot ---
  Widget _buildSmallLayout(DateTime now, Color textPrimary, Color textMuted, Color surface2) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(AppIcons.calendar, size: 14, color: AppColors.accentOrange),
                const SizedBox(width: 5),
                Text(
                  'October',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${now.year}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 7-day mini grid
        Expanded(
          child: _buildCalendarGrid(now, textPrimary, textMuted, isSmall: true),
        ),
      ],
    );
  }

  // --- Medium (4x2): Month Grid on Left + Today Agenda on Right ---
  Widget _buildMediumLayout(
    DateTime now,
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
  ) {
    return Row(
      children: [
        // Left: Calendar Month Grid
        Expanded(
          flex: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(AppIcons.calendar, size: 14, color: AppColors.accentOrange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'October 2026',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      '.calendarWidget',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: _buildCalendarGrid(now, textPrimary, textMuted, isSmall: false),
              ),
            ],
          ),
        ),

        const SizedBox(width: 6),
        VerticalDivider(color: borderColor, width: 1),
        const SizedBox(width: 6),

        // Right: Today's Schedule & Highlights
        Expanded(
          flex: 9,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentOrange,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Today · Mon 19',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),

                  // Events preview
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildEventRow(
                            time: '10:00 AM',
                            title: 'Product Sync & Design',
                            color: const Color(0xFF3B82F6),
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            surface2: surface2,
                          ),
                          const SizedBox(height: 3),
                          _buildEventRow(
                            time: '2:30 PM',
                            title: 'Quarterly Budget Review',
                            color: const Color(0xFF10B981),
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            surface2: surface2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Text(
                    '2 upcoming events scheduled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.5, color: textMuted),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Large (4x4): Full Grid + Detailed Day Agenda & Monthly Milestones ---
  Widget _buildLargeLayout(
    DateTime now,
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
  ) {
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
                  const Icon(AppIcons.calendar, size: 18, color: AppColors.accentOrange),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'October 2026',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'MyDay .calendarWidget',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentOrange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grid
        Expanded(
          flex: 5,
          child: _buildCalendarGrid(now, textPrimary, textMuted, isSmall: false),
        ),

        const SizedBox(height: 12),
        Divider(color: borderColor, height: 1),
        const SizedBox(height: 10),

        // Bottom Today Schedule List
        Text(
          "Today's Agenda (Monday, Oct 19)",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 4,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _buildEventRow(
                time: '10:00 AM',
                title: 'Product Architecture Review',
                color: const Color(0xFF3B82F6),
                textPrimary: textPrimary,
                textMuted: textMuted,
                surface2: surface2,
              ),
              const SizedBox(height: 6),
              _buildEventRow(
                time: '02:30 PM',
                title: 'Spendee Financial Sync',
                color: const Color(0xFF10B981),
                textPrimary: textPrimary,
                textMuted: textMuted,
                surface2: surface2,
              ),
              const SizedBox(height: 6),
              _buildEventRow(
                time: '05:00 PM',
                title: 'Gym & Evening Run',
                color: const Color(0xFF8B5CF6),
                textPrimary: textPrimary,
                textMuted: textMuted,
                surface2: surface2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Calendar Grid Helper ---
  Widget _buildCalendarGrid(DateTime now, Color textPrimary, Color textMuted, {required bool isSmall}) {
    // October 2026 starts on Thursday (weekday 4 where Sunday=7 or 0)
    // 2026-10-01 was Thursday (offset = 4)
    const daysInMonth = 31;
    const startOffset = 4; // Thursday
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      children: [
        // Weekday header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays.map((d) {
            return SizedBox(
              width: isSmall ? 14 : 16,
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmall ? 8.5 : 9.5,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 3),

        // Grid of 31 days
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = (constraints.maxWidth - 6 * 1.5) / 7;
              final numRows = ((startOffset + daysInMonth) / 7).ceil();
              final availableHeight = constraints.maxHeight - (numRows - 1) * 1.5;
              final cellHeight = availableHeight > 0 ? (availableHeight / numRows) : cellWidth;
              final ratio = (cellHeight > 0 && cellWidth > 0) ? (cellWidth / cellHeight) : 1.0;

              return ClipRect(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 1.5,
                    crossAxisSpacing: 1.5,
                    childAspectRatio: ratio,
                  ),
                  itemCount: startOffset + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < startOffset) {
                      return const SizedBox.shrink();
                    }
                    final day = index - startOffset + 1;
                    final isToday = day == 19;

                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday ? AppColors.accentOrange : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: isSmall ? 7.5 : 8.5,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                            color: isToday ? Colors.white : textPrimary,
                            height: 1.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventRow({
    required String time,
    required String title,
    required Color color,
    required Color textPrimary,
    required Color textMuted,
    required Color surface2,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(fontSize: 9.5, color: textMuted, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

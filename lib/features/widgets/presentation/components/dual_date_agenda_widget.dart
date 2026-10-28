import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_icons.dart';
import '../../../../core/utils/nepali_calendar_converter.dart';
import 'calendar_month_widget.dart';

/// Single agenda event or task item for DualDateAgendaWidget
class WidgetAgendaItem {
  final String id;
  final String title;
  final String time;
  final bool isDone;
  final Color color;

  const WidgetAgendaItem({
    required this.id,
    required this.title,
    this.time = 'Today',
    this.isDone = false,
    this.color = AppColors.accentOrange,
  });
}

/// Dual Calendar Date Widget displaying dynamic AD & BS Dates and real user agenda items
/// Supports Small (2x2), Medium (4x2), and Large (4x4) in Light & Dark modes
class DualDateAgendaWidget extends StatelessWidget {
  final WidgetSize size;
  final bool isDarkMode;
  final DateTime? currentDate;
  final List<WidgetAgendaItem>? events;
  final VoidCallback? onTap;

  const DualDateAgendaWidget({
    super.key,
    this.size = WidgetSize.medium,
    this.isDarkMode = false,
    this.currentDate,
    this.events,
    this.onTap,
  });

  static final _nepaliDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
  static final _bsMonthNames = [
    'Baisakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin',
    'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra'
  ];
  static final _bsMonthNepali = [
    'बैशाख', 'जेठ', 'असार', 'श्रावण', 'भदौ', 'असोज',
    'कार्तिक', 'मंसिर', 'पुष', 'माघ', 'फाल्गुन', 'चैत'
  ];

  static String _toNepaliDigits(int num) {
    return num.toString().split('').map((c) {
      final digit = int.tryParse(c);
      return digit != null ? _nepaliDigits[digit] : c;
    }).join('');
  }

  static const List<WidgetAgendaItem> _defaultEvents = [
    WidgetAgendaItem(
      id: '1',
      title: 'Review System Design',
      time: '10:00 AM',
      isDone: true,
    ),
    WidgetAgendaItem(
      id: '2',
      title: 'Spendee Financial Sync',
      time: '02:30 PM',
      isDone: false,
    ),
    WidgetAgendaItem(
      id: '3',
      title: 'Gym & Cardio Session',
      time: '05:00 PM',
      isDone: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final now = currentDate ?? DateTime(2026, 10, 19);

    const dayNames = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    const nepaliDayNames = ['सोमबार', 'मंगलबार', 'बुधबार', 'बिहिबार', 'शुक्रबार', 'शनिबार', 'आइतबार'];
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final weekdayStr = dayNames[now.weekday - 1];
    final nepaliWeekdayStr = nepaliDayNames[now.weekday - 1];
    final dayNum = now.day.toString();
    final monthYearStr = '${monthNames[now.month - 1]} ${now.year}';

    final bs = NepaliCalendarConverter.toBS(now);
    final bsEnglish = '${_bsMonthNames[bs.month - 1]} ${bs.day} ${bs.year}';
    final bsNepali = '${_bsMonthNepali[bs.month - 1]} ${_toNepaliDigits(bs.day)}, ${_toNepaliDigits(bs.year)}';
    final bsShortNepali = '${_bsMonthNepali[bs.month - 1]} ${_toNepaliDigits(bs.day)}';
    final bsYearNepali = '${_toNepaliDigits(bs.year)} BS';
    final bsCombined = '$bsEnglish ($bsNepali)';

    final effectiveEvents = events ?? _defaultEvents;

    final cardBg = isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFFFFFDF9);
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF1C1917);
    final textMuted = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF78716C);
    final borderColor = isDarkMode ? const Color(0xFF2E2E34) : const Color(0xFFE7E5E4);
    final surface2 = isDarkMode ? const Color(0xFF282830) : const Color(0xFFF5F3EF);
    const accent = AppColors.accentOrange;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        child: _buildContent(
          context,
          textPrimary,
          textMuted,
          borderColor,
          surface2,
          accent,
          weekdayStr,
          nepaliWeekdayStr,
          dayNum,
          monthYearStr,
          bsCombined,
          bsShortNepali,
          bsYearNepali,
          effectiveEvents,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
    Color accent,
    String weekdayStr,
    String nepaliWeekdayStr,
    String dayNum,
    String monthYearStr,
    String bsCombined,
    String bsShortNepali,
    String bsYearNepali,
    List<WidgetAgendaItem> effectiveEvents,
  ) {
    switch (size) {
      case WidgetSize.small:
        return _buildSmall(
          textPrimary,
          textMuted,
          surface2,
          accent,
          weekdayStr,
          dayNum,
          monthYearStr,
          bsCombined,
          effectiveEvents,
        );
      case WidgetSize.medium:
        return _buildMedium(
          textPrimary,
          textMuted,
          borderColor,
          surface2,
          accent,
          weekdayStr,
          nepaliWeekdayStr,
          dayNum,
          monthYearStr,
          bsCombined,
          effectiveEvents,
        );
      case WidgetSize.large:
        return _buildLarge(
          textPrimary,
          textMuted,
          borderColor,
          surface2,
          accent,
          weekdayStr,
          nepaliWeekdayStr,
          dayNum,
          monthYearStr,
          bsShortNepali,
          bsYearNepali,
          effectiveEvents,
        );
    }
  }

  // --- Small (2x2) Dual Date Stamp ---
  Widget _buildSmall(
    Color textPrimary,
    Color textMuted,
    Color surface2,
    Color accent,
    String weekdayStr,
    String dayNum,
    String monthYearStr,
    String bsCombined,
    List<WidgetAgendaItem> effectiveEvents,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Weekday & Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              weekdayStr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: accent,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'AD · BS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentOrange,
                ),
              ),
            ),
          ],
        ),

        // Big Date Number & Months
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              dayNum,
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthYearStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    bsCombined.contains('(') ? bsCombined.split('(').last.replaceAll(')', '') : bsCombined,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Bottom Pill
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: surface2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(AppIcons.tasks, size: 12, color: AppColors.accentOrange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  effectiveEvents.isNotEmpty
                      ? '${effectiveEvents.length} Events Scheduled'
                      : 'No events today',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Medium (4x2) Dual Date Banner with Schedule ---
  Widget _buildMedium(
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
    Color accent,
    String weekdayStr,
    String nepaliWeekdayStr,
    String dayNum,
    String monthYearStr,
    String bsCombined,
    List<WidgetAgendaItem> effectiveEvents,
  ) {
    return Row(
      children: [
        // Left Column: Big Date Block
        Expanded(
          flex: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Day of week
              Row(
                children: [
                  Text(
                    weekdayStr,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '· $nepaliWeekdayStr',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),

              // Big Day Number & Month
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    dayNum,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthYearStr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'BS',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentOrange,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                bsCombined,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Text(
                'MyDay Dynamic Calendar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 6),
        VerticalDivider(color: borderColor, width: 1),
        const SizedBox(width: 6),

        // Right Column: Real Schedule
        Expanded(
          flex: 9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      "Today's Schedule",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: effectiveEvents.isNotEmpty ? const Color(0xFF10B981) : textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (effectiveEvents.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No events scheduled today.\nTap + to add.',
                    style: TextStyle(fontSize: 10.5, color: textMuted),
                  ),
                )
              else
                for (int i = 0; i < effectiveEvents.take(3).length; i++) ...[
                  if (i > 0) const SizedBox(height: 5),
                  _buildAgendaItem(
                    time: effectiveEvents[i].time,
                    title: effectiveEvents[i].title,
                    isDone: effectiveEvents[i].isDone,
                    color: effectiveEvents[i].color,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    surface2: surface2,
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }

  // --- Large (4x4) Comprehensive Dual Date Grid ---
  Widget _buildLarge(
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
    Color accent,
    String weekdayStr,
    String nepaliWeekdayStr,
    String dayNum,
    String monthYearStr,
    String bsShortNepali,
    String bsYearNepali,
    List<WidgetAgendaItem> effectiveEvents,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header: Date Blocks
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        weekdayStr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '· $nepaliWeekdayStr',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dayNum $monthYearStr',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Text(
                    bsShortNepali,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  Text(
                    bsYearNepali,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),
        Divider(color: borderColor, height: 1),
        const SizedBox(height: 12),

        // Quick Highlights Bar
        Row(
          children: [
            _buildStatBadge('${effectiveEvents.length} Events', AppIcons.calendar, const Color(0xFF3B82F6), surface2),
            const SizedBox(width: 8),
            _buildStatBadge(
              '${effectiveEvents.where((e) => !e.isDone).length} Pending',
              AppIcons.tasks,
              accent,
              surface2,
            ),
          ],
        ),

        const SizedBox(height: 14),
        Text(
          "Today's Timeline",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: effectiveEvents.isEmpty
              ? Center(
                  child: Text(
                    'No events scheduled today.\nTap + to schedule an event.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                )
              : ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: effectiveEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = effectiveEvents[idx];
                    return _buildAgendaItem(
                      time: item.time,
                      title: item.title,
                      isDone: item.isDone,
                      color: item.color,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      surface2: surface2,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAgendaItem({
    required String time,
    required String title,
    required bool isDone,
    Color color = AppColors.accentOrange,
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
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isDone)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.check_circle, size: 13, color: AppColors.success),
            ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

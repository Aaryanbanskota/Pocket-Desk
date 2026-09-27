import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/nepali_date.dart';

class YearViewWidget extends StatelessWidget {
  const YearViewWidget({
    super.key,
    required this.focusedDay,
    required this.onMonthDayTap,
    this.isBsCalendar = true,
  });

  final DateTime focusedDay;
  final ValueChanged<DateTime> onMonthDayTap;
  final bool isBsCalendar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final adMonthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final nepaliFocused = NepaliDate.fromDateTime(focusedDay);
    final int currentBsYear = nepaliFocused.year;
    final int currentAdYear = focusedDay.year;

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
        childAspectRatio: 0.85,
      ),
      itemCount: 12,
      itemBuilder: (context, monthIdx) {
        final monthNumber = monthIdx + 1;
        late final String monthHeader;
        late final int monthDaysCount;
        late final int startOffset;

        if (isBsCalendar) {
          final monthFirstBs = NepaliDate(year: currentBsYear, month: monthNumber, day: 1);
          monthDaysCount = NepaliDate.getDaysInBsMonth(currentBsYear, monthNumber);
          startOffset = monthFirstBs.weekday % 7;
          monthHeader = '${NepaliDate.monthNamesEn[monthIdx]} $currentBsYear';
        } else {
          final monthFirstAd = DateTime(currentAdYear, monthNumber, 1);
          monthDaysCount = DateTime(currentAdYear, monthNumber + 1, 0).day;
          startOffset = monthFirstAd.weekday % 7;
          monthHeader = '${adMonthNames[monthIdx]} $currentAdYear';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                monthHeader,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 4),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: 42,
                itemBuilder: (context, dayIdx) {
                  final int dayNumber = dayIdx - startOffset + 1;
                  final isValidDay = dayNumber > 0 && dayNumber <= monthDaysCount;

                  if (!isValidDay) return const SizedBox.shrink();

                  final cellDate = isBsCalendar
                      ? NepaliDate(year: currentBsYear, month: monthNumber, day: dayNumber).toDateTime()
                      : DateTime(currentAdYear, monthNumber, dayNumber);
                  final isToday = DateTimeUtils.isToday(cellDate);

                  return GestureDetector(
                    onTap: () => onMonthDayTap(cellDate),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isToday ? colorScheme.primary : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        dayNumber.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isToday ? colorScheme.onPrimary : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

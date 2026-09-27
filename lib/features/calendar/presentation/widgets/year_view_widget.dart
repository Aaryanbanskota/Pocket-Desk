import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/nepali_date.dart';

class YearViewWidget extends StatelessWidget {
  const YearViewWidget({
    super.key,
    required this.focusedDay,
    required this.onMonthDayTap,
  });

  final DateTime focusedDay;
  final ValueChanged<DateTime> onMonthDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nepaliFocused = NepaliDate.fromDateTime(focusedDay);
    final int currentBsYear = nepaliFocused.year;

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
        final bsMonth = monthIdx + 1;
        final monthFirstBs = NepaliDate(year: currentBsYear, month: bsMonth, day: 1);
        final monthDaysCount = NepaliDate.getDaysInBsMonth(currentBsYear, bsMonth);
        final startOffset = monthFirstBs.weekday % 7; // Sunday = 0

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                '${NepaliDate.monthNamesEn[monthIdx]} $currentBsYear',
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

                  final bsDate = NepaliDate(year: currentBsYear, month: bsMonth, day: dayNumber);
                  final cellDate = bsDate.toDateTime();
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

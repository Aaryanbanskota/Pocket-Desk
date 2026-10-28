import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_icons.dart';
import 'calendar_month_widget.dart';

/// Financial & Budget Snapshot Widget (Inspired by Spendee)
/// Displays Total Balance, Today's Spend vs Daily Budget, and Recent Transactions
class BudgetSpendeeWidget extends StatelessWidget {
  final WidgetSize size;
  final bool isDarkMode;
  final String currency;
  final double balance;
  final double spentToday;
  final double dailyLimit;
  final VoidCallback? onTap;

  const BudgetSpendeeWidget({
    super.key,
    this.size = WidgetSize.medium,
    this.isDarkMode = false,
    this.currency = 'Rs',
    this.balance = 24500.0,
    this.spentToday = 350.0,
    this.dailyLimit = 800.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFFFFFDF9);
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF1C1917);
    final textMuted = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF78716C);
    final borderColor = isDarkMode ? const Color(0xFF2E2E34) : const Color(0xFFE7E5E4);
    final surface2 = isDarkMode ? const Color(0xFF282830) : const Color(0xFFF5F3EF);
    final progress = (spentToday / dailyLimit).clamp(0.0, 1.0);

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
        child: size == WidgetSize.small
            ? _buildSmall(textPrimary, textMuted, surface2, progress)
            : (size == WidgetSize.large
                ? _buildLarge(textPrimary, textMuted, borderColor, surface2, progress)
                : _buildMedium(textPrimary, textMuted, borderColor, surface2, progress)),
      ),
    );
  }

  Widget _buildSmall(Color textPrimary, Color textMuted, Color surface2, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(AppIcons.wallet, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Spendee Glance',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              currency,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
            ),
          ],
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Balance',
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$currency ${balance.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),

        // Progress
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Today: $currency${spentToday.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Limit $currency${dailyLimit.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 10, color: textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: surface2,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedium(
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
    double progress,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVeryNarrow = constraints.maxWidth < 420;

        if (isVeryNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(AppIcons.wallet, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Budget & Net Worth',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      currency,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Available', style: TextStyle(fontSize: 10, color: textMuted)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$currency ${balance.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Spent / Daily Limit', style: TextStyle(fontSize: 10, color: textMuted)),
                        Text(
                          '$currency${spentToday.toStringAsFixed(0)} / $currency${dailyLimit.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: surface2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
              _buildTxItem(
                icon: AppIcons.food,
                title: 'Lunch & Cafe',
                amount: '- $currency 180',
                time: '12:40 PM',
                textPrimary: textPrimary,
                textMuted: textMuted,
                surface2: surface2,
              ),
            ],
          );
        }

        return Row(
          children: [
            // Left: Net Balance & Today's Limit
            Expanded(
              flex: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(AppIcons.wallet, size: 15, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Budget & Net Worth',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Total Available',
                    style: TextStyle(fontSize: 10.5, color: textMuted),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$currency ${balance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Spent: $currency${spentToday.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Daily Limit: $currency${dailyLimit.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(fontSize: 9.5, color: textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: surface2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),
            VerticalDivider(color: borderColor, width: 1),
            const SizedBox(width: 10),

            // Right: Recent 2 Transactions
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Recent Expenses',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  const SizedBox(height: 6),

                  _buildTxItem(
                    icon: AppIcons.food,
                    title: 'Lunch & Cafe',
                    amount: '- $currency 180',
                    time: '12:40 PM',
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    surface2: surface2,
                  ),
                  const SizedBox(height: 5),
                  _buildTxItem(
                    icon: AppIcons.transport,
                    title: 'City Transport',
                    amount: '- $currency 170',
                    time: '09:15 AM',
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    surface2: surface2,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLarge(
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
    double progress,
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
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(AppIcons.wallet, size: 15, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Spendee Financial Pulse',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$currency Active',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Net Balance Card Banner
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Net Balance', style: TextStyle(fontSize: 10.5, color: textMuted)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$currency ${balance.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Spent: $currency${spentToday.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Limit: $currency${dailyLimit.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: borderColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Recent Expenses List
        Text(
          'Recent Expenses',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        const SizedBox(height: 6),

        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            children: [
              _buildTxItem(
                icon: AppIcons.food,
                title: 'Lunch & Cafe',
                amount: '- $currency 180',
                time: '12:40 PM',
                textPrimary: textPrimary,
                textMuted: textMuted,
                surface2: surface2,
              ),
              const SizedBox(height: 5),
              _buildTxItem(
                icon: AppIcons.transport,
                title: 'City Transport',
                amount: '- $currency 170',
                time: '09:15 AM',
                textPrimary: textPrimary,
                textMuted: textMuted,
                surface2: surface2,
              ),
              const SizedBox(height: 5),
              _buildTxItem(
                icon: AppIcons.shopping,
                title: 'Groceries & Household',
                amount: '- $currency 420',
                time: 'Yesterday',
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

  Widget _buildTxItem({
    required IconData icon,
    required String title,
    required String amount,
    required String time,
    required Color textPrimary,
    required Color textMuted,
    required Color surface2,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.accentOrange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}

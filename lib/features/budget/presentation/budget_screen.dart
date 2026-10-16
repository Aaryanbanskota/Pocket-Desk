import 'dart:io';
import 'package:drift/drift.dart' show Variable;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/app_bottom_sheet.dart';
import '../../../core/design_system/widgets/circular_icon_button.dart';
import '../../../core/design_system/widgets/pill_chip.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../data/budget_repository.dart';
import 'transaction_sheet.dart';
import 'wallet_sheet.dart';

class BudgetScreen extends StatefulWidget {
  final List<MyDayWallet> wallets;
  final List<MyDayTransaction> transactions;
  final List<MyDayBudget> budgets;
  final Map<String, int> categoryExpenses;
  final String selectedWalletId;
  final ValueChanged<String> onWalletSelected;
  final String selectedPeriod; // 'week', 'month', 'year', 'all'
  final ValueChanged<String> onPeriodSelected;
  final int periodOffset;
  final ValueChanged<int> onPeriodOffsetChanged;
  final String transactionTypeFilter; // 'all', 'Expense', 'Income', 'Transfer'
  final ValueChanged<String> onTransactionTypeChanged;
  final String selectedCategoryFilter;
  final ValueChanged<String>? onCategoryFilterChanged;
  final VoidCallback? onClearAllFilters;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddWallet;
  final VoidCallback onAddBudget;
  final void Function(MyDayBudget) onEditBudget;
  final VoidCallback onAddTransaction;
  final void Function(MyDayTransaction) onEditTransaction;
  final void Function(MyDayTransaction) onDeleteTransaction;
  final VoidCallback onExportCsv;
  final void Function(String walletId, int newBalanceInPaisa)? onUpdateWalletBalance;

  const BudgetScreen({
    super.key,
    required this.wallets,
    required this.transactions,
    required this.budgets,
    required this.categoryExpenses,
    required this.selectedWalletId,
    required this.onWalletSelected,
    required this.selectedPeriod,
    required this.onPeriodSelected,
    required this.periodOffset,
    required this.onPeriodOffsetChanged,
    required this.transactionTypeFilter,
    required this.onTransactionTypeChanged,
    this.selectedCategoryFilter = 'all',
    this.onCategoryFilterChanged,
    this.onClearAllFilters,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onAddWallet,
    required this.onAddBudget,
    required this.onEditBudget,
    required this.onAddTransaction,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
    required this.onExportCsv,
    this.onUpdateWalletBalance,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late TextEditingController _searchController;
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getPeriodLabel() {
    final now = DateTime.now();
    if (widget.selectedPeriod == 'week') {
      final start = now.subtract(Duration(days: (now.weekday - 1) - (widget.periodOffset * 7)));
      final end = start.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}';
    } else if (widget.selectedPeriod == 'month') {
      final date = DateTime(now.year, now.month + widget.periodOffset, 1);
      return DateFormat('MMMM yyyy').format(date);
    } else if (widget.selectedPeriod == 'year') {
      final year = now.year + widget.periodOffset;
      return '$year';
    } else {
      return 'All time';
    }
  }

  void _showEditBalanceDialog(BuildContext context, MyDayWallet? wallet) {
    if (wallet == null && widget.wallets.isEmpty) {
      widget.onAddWallet();
      return;
    }
    final targetWallet = wallet ?? widget.wallets.first;
    final currentVal = (targetWallet.currentBalance / 100.0).toStringAsFixed(2);
    final controller = TextEditingController(text: currentVal == '0.00' ? '' : currentVal);

    AppBottomSheet.show<void>(
      context: context,
      title: 'Edit Balance — ${targetWallet.name}',
      child: StatefulBuilder(
        builder: (modalContext, setModalState) {
          final isDark = Theme.of(modalContext).brightness == Brightness.dark;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
          final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
          final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
          final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Set your current starting balance for this wallet. Your transaction history remains safe and calculated.',
                  style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Current balance (${targetWallet.currency})',
                  style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    prefixText: '${targetWallet.currency} ',
                    prefixStyle: TextStyle(color: textMuted, fontSize: 18, fontWeight: FontWeight.w600),
                    hintText: '0.00',
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final numVal = double.tryParse(controller.text.trim()) ?? 0.0;
                    final paisa = (numVal * 100).round();
                    widget.onUpdateWalletBalance?.call(targetWallet.id, paisa);
                    Navigator.of(modalContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Update Balance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCurrency = widget.wallets.isNotEmpty
        ? (widget.selectedWalletId == 'all'
            ? widget.wallets.first.currency
            : widget.wallets.firstWhere((w) => w.id == widget.selectedWalletId, orElse: () => widget.wallets.first).currency)
        : 'Rs';

    // Calculate In and Out totals for current filtered transactions
    int totalIn = 0;
    int totalOut = 0;
    for (final t in widget.transactions) {
      if (t.type == 'Income') {
        totalIn += t.amount;
      } else if (t.type == 'Expense') {
        totalOut += t.amount;
      }
    }

    final totalWalletBalance = widget.selectedWalletId == 'all'
        ? widget.wallets.fold<int>(0, (sum, w) => sum + w.currentBalance)
        : widget.wallets
            .firstWhere((w) => w.id == widget.selectedWalletId, orElse: () => widget.wallets.first)
            .currentBalance;

    final totalExpenses = widget.categoryExpenses.values.fold<int>(0, (a, b) => a + b);

    // Group transactions by date string
    final Map<String, List<MyDayTransaction>> groupedTx = {};
    for (final tx in widget.transactions) {
      final dateStr = DateFormat('yyyy-MM-dd').format(
        DateTime.fromMillisecondsSinceEpoch(tx.transactionTime),
      );
      groupedTx.putIfAbsent(dateStr, () => []).add(tx);
    }

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 26),
      children: [
        // 1. Wallets Chips Row (.wc in prototype)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: [
              // All wallets chip (only when multiple wallets exist)
              if (widget.wallets.length > 1) ...[
                _buildWalletChip(
                  id: 'all',
                  name: 'All wallets',
                  balanceStr: BudgetRepository.formatAmount(
                    widget.wallets.fold<int>(0, (s, w) => s + w.currentBalance),
                    currency: activeCurrency,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Individual wallet chips
              for (final w in widget.wallets) ...[
                _buildWalletChip(
                  id: w.id,
                  name: w.name,
                  balanceStr: BudgetRepository.formatAmount(
                    w.currentBalance,
                    currency: w.currency,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Add Wallet button
              InkWell(
                onTap: widget.onAddWallet,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.appLine, width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.plus, color: context.appText, size: 20),
                      if (widget.wallets.isEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Add wallet',
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Balance Credit Card
        Builder(
          builder: (context) {
            final activeWallet = widget.selectedWalletId == 'all'
                ? (widget.wallets.isNotEmpty ? widget.wallets.first : null)
                : widget.wallets.where((w) => w.id == widget.selectedWalletId).firstOrNull ??
                    (widget.wallets.isNotEmpty ? widget.wallets.first : null);
            final walletDisplayName = widget.wallets.isEmpty
                ? 'NO WALLET'
                : (widget.selectedWalletId == 'all'
                    ? 'ALL WALLETS'
                    : (activeWallet?.name.toUpperCase() ?? 'WALLET'));

            return Container(
              height: 206,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF23252B),
                    Color(0xFF17181C),
                    Color(0xFF0F1012),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: EMV Chip + Contactless + Edit Balance Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Gold EMV Chip
                          Container(
                            width: 42,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF3D279), Color(0xFFC99738), Color(0xFFE5C07B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA17A20), width: 0.8),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 22,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black26, width: 0.8),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Container(
                                  width: 40,
                                  height: 0.8,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Contactless waves icon
                          Icon(
                            Icons.contactless_rounded,
                            size: 24,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ],
                      ),

                      // Edit Balance Button
                      InkWell(
                        onTap: () => _showEditBalanceDialog(context, activeWallet),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(AppIcons.edit, size: 12, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'Edit balance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Middle Row: Balance display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT BALANCE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          BudgetRepository.formatAmount(totalWalletBalance, currency: activeCurrency),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom Row: Wallet Name & In/Out Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CARDHOLDER / WALLET',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              widget.wallets.isEmpty ? 'Tap + to add wallet' : '$walletDisplayName •••• 8824',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // In and Out Pills
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '+${BudgetRepository.formatAmount(totalIn, currency: activeCurrency)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF34D399),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '-${BudgetRepository.formatAmount(totalOut, currency: activeCurrency)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF87171),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 14),

        // 3. Period Chips: Week, Month, Year, All
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPeriodChip('week', 'Week'),
            const SizedBox(width: 8),
            _buildPeriodChip('month', 'Month'),
            const SizedBox(width: 8),
            _buildPeriodChip('year', 'Year'),
            const SizedBox(width: 8),
            _buildPeriodChip('all', 'All'),
          ],
        ),

        const SizedBox(height: 14),

        // 4. Period Navigation Row (< October 2026 >)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircularIconButton(
              icon: AppIcons.back,
              size: 34,
              iconSize: 18,
              onPressed: widget.selectedPeriod == 'all'
                  ? null
                  : () => widget.onPeriodOffsetChanged(widget.periodOffset - 1),
            ),
            Text(
              _getPeriodLabel(),
              style: AppTypography.h4.copyWith(color: context.appText),
            ),
            CircularIconButton(
              icon: AppIcons.forward,
              size: 34,
              iconSize: 18,
              onPressed: widget.selectedPeriod == 'all'
                  ? null
                  : () => widget.onPeriodOffsetChanged(widget.periodOffset + 1),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 5. Expenses by Category Donut Chart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appLine, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EXPENSES BY CATEGORY',
                style: AppTypography.caption.copyWith(color: context.appMuted),
              ),
              const SizedBox(height: 14),
              widget.categoryExpenses.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No expenses in this period',
                          style: AppTypography.body.copyWith(color: context.appMuted),
                        ),
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final categoryEntries = widget.categoryExpenses.entries.toList();

                        return Row(
                          children: [
                            // Animated FL Chart Donut
                            SizedBox(
                              width: 136,
                              height: 136,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 38,
                                      pieTouchData: PieTouchData(
                                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                          setState(() {
                                            if (!event.isInterestedForInteractions ||
                                                pieTouchResponse == null ||
                                                pieTouchResponse.touchedSection == null) {
                                              _touchedPieIndex = -1;
                                              return;
                                            }
                                            _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                          });
                                        },
                                      ),
                                      sections: categoryEntries.asMap().entries.map((mapEntry) {
                                        final idx = mapEntry.key;
                                        final e = mapEntry.value;
                                        final isTouched = idx == _touchedPieIndex;
                                        final radius = isTouched ? 28.0 : 20.0;
                                        final color = AppColors.categories[e.key] ?? AppColors.categories['Other']!;
                                        final pct = totalExpenses > 0 ? ((e.value / totalExpenses) * 100).round() : 0;
                                        return PieChartSectionData(
                                          color: color,
                                          value: e.value.toDouble(),
                                          title: isTouched ? '$pct%' : '',
                                          titleStyle: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          radius: radius,
                                        );
                                      }).toList(),
                                    ),
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                  ),
                                  // Center Label on Hover / Idle
                                  if (_touchedPieIndex >= 0 && _touchedPieIndex < categoryEntries.length)
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            categoryEntries[_touchedPieIndex].key,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: context.appText,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            BudgetRepository.formatAmount(categoryEntries[_touchedPieIndex].value, currency: activeCurrency),
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.categories[categoryEntries[_touchedPieIndex].key] ?? AppColors.accentOrange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Text(
                                      'Total\n${BudgetRepository.formatAmount(totalExpenses, currency: activeCurrency)}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: context.appMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Legend list
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: categoryEntries.take(5).map((e) {
                                  final color = AppColors.categories[e.key] ?? AppColors.categories['Other']!;
                                  final pct = totalExpenses > 0 ? ((e.value / totalExpenses) * 100).round() : 0;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            e.key,
                                            style: TextStyle(color: context.appText, fontSize: 13),
                                          ),
                                        ),
                                        Text(
                                          '$pct%',
                                          style: TextStyle(
                                            color: context.appMuted,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 6. Budgets Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Budgets', style: AppTypography.h3.copyWith(color: context.appText)),
            CircularIconButton(
              icon: AppIcons.plus,
              size: 34,
              iconSize: 18,
              onPressed: widget.onAddBudget,
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Budgets Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appLine, width: 1.0),
          ),
          child: widget.budgets.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Set monthly limits per category',
                      style: AppTypography.body.copyWith(color: context.appMuted),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < widget.budgets.length; i++) ...[
                      _buildBudgetItem(context, widget.budgets[i], activeCurrency),
                      if (i < widget.budgets.length - 1)
                        Divider(color: context.appLine, height: 1),
                    ],
                  ],
                ),
        ),

        const SizedBox(height: 20),

        // 7. Transactions Section Header with Export CSV and Add Transaction
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Transactions', style: AppTypography.h3.copyWith(color: context.appText)),
            Row(
              children: [
                PillChip(
                  label: 'Export CSV',
                  isSelected: false,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  onTap: widget.onExportCsv,
                ),
                const SizedBox(width: 8),
                CircularIconButton(
                  icon: AppIcons.plus,
                  size: 34,
                  iconSize: 18,
                  onPressed: widget.onAddTransaction,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Search Transactions Input
        Container(
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.appLine, width: 1.0),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: context.appText),
            decoration: InputDecoration(
              prefixIcon: Icon(AppIcons.search, size: 20, color: context.appMuted),
              hintText: 'Search transactions',
              hintStyle: TextStyle(color: context.appMuted.withValues(alpha: 0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: widget.onSearchChanged,
          ),
        ),

        const SizedBox(height: 12),

        // Type Filter Chips & More Filters Button
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildTypeFilterChip('all', 'All'),
              const SizedBox(width: 8),
              _buildTypeFilterChip('Expense', 'Expense'),
              const SizedBox(width: 8),
              _buildTypeFilterChip('Income', 'Income'),
              const SizedBox(width: 8),
              _buildTypeFilterChip('Transfer', 'Transfer'),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showMoreFiltersDialog(context),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: (widget.selectedCategoryFilter != 'all')
                        ? AppColors.accent.withValues(alpha: 0.18)
                        : context.appSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: (widget.selectedCategoryFilter != 'all')
                          ? AppColors.accent
                          : context.appLine,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 13,
                        color: (widget.selectedCategoryFilter != 'all')
                            ? AppColors.accent
                            : context.appMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.selectedCategoryFilter != 'all'
                            ? widget.selectedCategoryFilter
                            : 'More filters',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: (widget.selectedCategoryFilter != 'all')
                              ? AppColors.accent
                              : context.appText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildCategoryChip('all', 'All Categories'),
              const SizedBox(width: 6),
              ...AppColors.categories.keys.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildCategoryChip(cat, cat),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Transactions List Card (grouped by date)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appLine, width: 1.0),
          ),
          child: groupedTx.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      'No transactions in this period',
                      style: AppTypography.body.copyWith(color: context.appMuted),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final entry in groupedTx.entries) ...[
                      _buildDateHeader(context, entry.key, entry.value, activeCurrency),
                      for (final tx in entry.value) ...[
                        _buildTransactionRow(context, tx, activeCurrency),
                        Divider(color: context.appLine, height: 1),
                      ],
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildWalletChip({
    required String id,
    required String name,
    required String balanceStr,
  }) {
    final isSelected = widget.selectedWalletId == id;
    return InkWell(
      onTap: () => widget.onWalletSelected(id),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64, minWidth: 130),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.accent : context.appLine,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appMuted, fontSize: 11),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                balanceStr,
                style: AppTypography.bodyBold.copyWith(color: context.appText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String periodKey, String label) {
    final isSelected = widget.selectedPeriod == periodKey;
    return PillChip(
      label: label,
      isSelected: isSelected,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      onTap: () => widget.onPeriodSelected(periodKey),
    );
  }

  Widget _buildTypeFilterChip(String typeKey, String label) {
    final isSelected = widget.transactionTypeFilter == typeKey;
    return PillChip(
      label: label,
      isSelected: isSelected,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      onTap: () => widget.onTransactionTypeChanged(typeKey),
    );
  }

  Widget _buildCategoryChip(String catKey, String label) {
    final isSelected = widget.selectedCategoryFilter == catKey;
    final catColor = AppColors.categories[catKey] ?? AppColors.accent;
    return InkWell(
      onTap: () => widget.onCategoryFilterChanged?.call(catKey),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (catKey == 'all' ? AppColors.accent : catColor)
              : context.appSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? (catKey == 'all' ? AppColors.accent : catColor)
                : context.appLine,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (catKey != 'all') ...[
              Icon(AppIcons.getCategoryIcon(catKey), size: 13, color: isSelected ? Colors.white : catColor),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : context.appText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreFiltersDialog(BuildContext context) {
    AppBottomSheet.show<void>(
      context: context,
      title: 'Filter Transactions',
      child: StatefulBuilder(
        builder: (modalContext, setModalState) {
          final isDark = Theme.of(modalContext).brightness == Brightness.dark;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
          final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
          final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
          final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Transaction Type
                Text('Transaction Type', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in ['all', 'Expense', 'Income', 'Transfer'])
                      ChoiceChip(
                        label: Text(type == 'all' ? 'All Types' : type),
                        selected: widget.transactionTypeFilter == type,
                        selectedColor: AppColors.accent,
                        backgroundColor: cardBg,
                        labelStyle: TextStyle(
                          color: widget.transactionTypeFilter == type ? Colors.white : textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {});
                            widget.onTransactionTypeChanged(type);
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2. Category
                Text('Category', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: widget.selectedCategoryFilter,
                      isExpanded: true,
                      dropdownColor: cardBg,
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Categories', style: TextStyle(color: textPrimary, fontSize: 15)),
                        ),
                        ...AppColors.categories.keys.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(AppIcons.getCategoryIcon(cat), size: 16, color: AppColors.categories[cat]),
                                const SizedBox(width: 8),
                                Text(cat, style: TextStyle(color: textPrimary, fontSize: 15)),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {});
                          widget.onCategoryFilterChanged?.call(val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Wallet
                if (widget.wallets.isNotEmpty) ...[
                  Text('Wallet', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All Wallets'),
                        selected: widget.selectedWalletId == 'all',
                        selectedColor: AppColors.accent,
                        backgroundColor: cardBg,
                        labelStyle: TextStyle(
                          color: widget.selectedWalletId == 'all' ? Colors.white : textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {});
                            widget.onWalletSelected('all');
                          }
                        },
                      ),
                      for (final w in widget.wallets)
                        ChoiceChip(
                          label: Text(w.name),
                          selected: widget.selectedWalletId == w.id,
                          selectedColor: AppColors.accent,
                          backgroundColor: cardBg,
                          labelStyle: TextStyle(
                            color: widget.selectedWalletId == w.id ? Colors.white : textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {});
                              widget.onWalletSelected(w.id);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                ],

                // Action Buttons: Reset & Close
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          widget.onClearAllFilters?.call();
                          Navigator.of(modalContext).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Reset Filters', style: TextStyle(color: textMuted, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(modalContext).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBudgetItem(BuildContext context, MyDayBudget b, String currency) {
    final color = AppColors.categories[b.category] ?? AppColors.categories['Other']!;
    final spentStr = BudgetRepository.formatAmount(b.spentThisMonth, currency: currency);
    final limitStr = BudgetRepository.formatAmount(b.monthlyLimit, currency: currency);

    return InkWell(
      onTap: () => widget.onEditBudget(b),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
              child: Center(
                child: Icon(AppIcons.getCategoryIcon(b.category), color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(b.category, style: AppTypography.bodyBold.copyWith(color: context.appText)),
                      Text('$spentStr / $limitStr', style: TextStyle(color: context.appMuted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: b.percent.clamp(0.0, 1.0),
                      backgroundColor: context.appSurface2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        b.isOverspent ? AppColors.danger : color,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    b.isOverspent
                        ? 'Over by ${BudgetRepository.formatAmount(b.spentThisMonth - b.monthlyLimit, currency: currency)}'
                        : '${BudgetRepository.formatAmount(b.remaining, currency: currency)} left this month',
                    style: TextStyle(
                      fontSize: 11,
                      color: b.isOverspent ? AppColors.danger : context.appMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(
    BuildContext context,
    String dateIso,
    List<MyDayTransaction> list,
    String currency,
  ) {
    final date = DateTime.tryParse(dateIso) ?? DateTime.now();
    int daySum = 0;
    for (final t in list) {
      daySum += (t.type == 'Income' ? t.amount : -t.amount);
    }

    final sumFormatted = BudgetRepository.formatAmount(daySum.abs(), currency: currency);
    final sign = daySum >= 0 ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('EEE, MMM d').format(date).toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: context.appMuted,
            ),
          ),
          Text(
            '$sign$sumFormatted',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.appMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(
    BuildContext context,
    MyDayTransaction tx,
    String currency,
  ) {
    final color = AppColors.categories[tx.category] ?? AppColors.categories['Other']!;
    final isIncome = tx.type == 'Income';
    final isTransfer = tx.type == 'Transfer';
    final sign = isIncome ? '+' : (isTransfer ? '' : '-');
    final amountFormatted = BudgetRepository.formatAmount(tx.amount, currency: currency);

    final wallet = widget.wallets.firstWhere(
      (w) => w.id == tx.walletId,
      orElse: () => widget.wallets.first,
    );

    return InkWell(
      onTap: () => widget.onEditTransaction(tx),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
              child: Center(
                child: Icon(
                  isTransfer ? AppIcons.arrowRightLeft : AppIcons.getCategoryIcon(tx.category),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.note.isNotEmpty ? tx.note : tx.category,
                    style: AppTypography.bodyBold.copyWith(color: context.appText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tx.category} · ${wallet.name}',
                    style: TextStyle(color: context.appMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '$sign$amountFormatted',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isIncome
                    ? AppColors.success
                    : (isTransfer ? context.appMuted : context.appText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetPage extends StatefulWidget {
  final BudgetRepository budgetRepository;
  final String accountId;
  final Future<void> Function()? onRefresh;

  const BudgetPage({
    super.key,
    required this.budgetRepository,
    required this.accountId,
    this.onRefresh,
  });

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  List<MyDayWallet> _wallets = [];
  List<MyDayTransaction> _transactions = [];
  List<MyDayBudget> _budgets = [];
  Map<String, int> _categoryExpenses = {};

  String _selectedWalletId = 'all';
  String _selectedPeriod = 'month';
  int _periodOffset = 0;
  String _transactionTypeFilter = 'all';
  String _selectedCategoryFilter = 'all';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant BudgetPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadData();
  }

  (int?, int?) _calculatePeriodRange() {
    final now = DateTime.now();
    if (_selectedPeriod == 'week') {
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1))
          .add(Duration(days: _periodOffset * 7));
      final nextMonday = monday.add(const Duration(days: 7));
      return (monday.millisecondsSinceEpoch, nextMonday.millisecondsSinceEpoch);
    } else if (_selectedPeriod == 'month') {
      final start = DateTime(now.year, now.month + _periodOffset, 1);
      final end = DateTime(now.year, now.month + _periodOffset + 1, 1);
      return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
    } else if (_selectedPeriod == 'year') {
      final start = DateTime(now.year + _periodOffset, 1, 1);
      final end = DateTime(now.year + _periodOffset + 1, 1, 1);
      return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
    }
    return (null, null);
  }

  Future<void> _loadData() async {
    try {
      final wallets = await widget.budgetRepository
          .getWallets(widget.accountId)
          .timeout(const Duration(seconds: 2));
      final budgets = await widget.budgetRepository
          .getBudgets(widget.accountId)
          .timeout(const Duration(seconds: 2));

      final (startTimeMs, endTimeMs) = _calculatePeriodRange();

      final txs = await widget.budgetRepository
          .getTransactions(
            accountId: widget.accountId,
            walletId: _selectedWalletId == 'all' ? null : _selectedWalletId,
            typeFilter: _transactionTypeFilter,
            categoryFilter: _selectedCategoryFilter,
            startTimeMs: startTimeMs,
            endTimeMs: endTimeMs,
            searchQuery: _searchQuery,
          )
          .timeout(const Duration(seconds: 2));

      final catExp = await widget.budgetRepository
          .getExpensesByCategory(
            accountId: widget.accountId,
            walletId: _selectedWalletId == 'all' ? null : _selectedWalletId,
            startTimeMs: startTimeMs,
            endTimeMs: endTimeMs,
            allTime: _selectedPeriod == 'all',
          )
          .timeout(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _wallets = wallets;
          _budgets = budgets;
          _transactions = txs;
          _categoryExpenses = catExp;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onWalletSelected(String id) {
    setState(() => _selectedWalletId = id);
    _loadData();
  }

  void _onPeriodSelected(String period) {
    setState(() {
      _selectedPeriod = period;
      _periodOffset = 0;
    });
    _loadData();
  }

  void _onPeriodOffsetChanged(int offset) {
    setState(() => _periodOffset = offset);
    _loadData();
  }

  void _onTransactionTypeChanged(String filter) {
    setState(() => _transactionTypeFilter = filter);
    _loadData();
  }

  void _onCategoryFilterChanged(String cat) {
    setState(() => _selectedCategoryFilter = cat);
    _loadData();
  }

  void _onClearAllFilters() {
    setState(() {
      _selectedWalletId = 'all';
      _transactionTypeFilter = 'all';
      _selectedCategoryFilter = 'all';
      _searchQuery = '';
    });
    _loadData();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _loadData();
  }

  void _onAddWallet() {
    WalletSheet.showForAccount(
      context: context,
      budgetRepository: widget.budgetRepository,
      accountId: widget.accountId,
      onSaved: _loadData,
    );
  }

  void _onAddTransaction() {
    TransactionSheet.showForAccount(
      context: context,
      budgetRepository: widget.budgetRepository,
      accountId: widget.accountId,
      onSaved: _loadData,
    );
  }

  void _onEditTransaction(MyDayTransaction tx) {
    TransactionSheet.showForAccount(
      context: context,
      budgetRepository: widget.budgetRepository,
      accountId: widget.accountId,
      transaction: tx,
      onSaved: _loadData,
    );
  }

  Future<void> _onDeleteTransaction(MyDayTransaction tx) async {
    await widget.budgetRepository.deleteTransaction(tx.id);
    _loadData();
    if (mounted) {
      UndoToast.show(
        context,
        message: 'Transaction deleted',
        actionLabel: 'Undo',
        onUndo: () async {
          await widget.budgetRepository.db.customUpdate(
            'UPDATE transactions SET is_deleted = 0, deleted_at = NULL WHERE id = ?',
            variables: [Variable(tx.id)],
          );
          _loadData();
        },
      );
    }
  }

  void _onAddOrEditBudget([MyDayBudget? existing]) {
    String selectedCat = existing?.category ?? 'Food';
    final limitController = TextEditingController(
      text: existing != null ? (existing.monthlyLimit / 100).toStringAsFixed(0) : '20000',
    );

    AppBottomSheet.show<void>(
      context: context,
      title: existing == null ? 'New monthly budget' : 'Edit budget',
      child: StatefulBuilder(
        builder: (modalContext, setSheetState) {
          final isDark = Theme.of(modalContext).brightness == Brightness.dark;
          final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
          final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
          final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
          final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Category', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCat,
                      isExpanded: true,
                      dropdownColor: cardBg,
                      items: AppColors.categoryColors.keys.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat, style: TextStyle(color: textPrimary, fontSize: 15)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedCat = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Monthly Limit', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: limitController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    prefixText: 'Rs ',
                    prefixStyle: TextStyle(color: textMuted),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () async {
                    final limitNum = double.tryParse(limitController.text) ?? 0;
                    if (limitNum <= 0) return;
                    final limitMinor = (limitNum * 100).round();

                    await widget.budgetRepository.setBudget(
                      accountId: widget.accountId,
                      category: selectedCat,
                      limitMinor: limitMinor,
                      existingId: existing?.id,
                    );

                    if (modalContext.mounted) {
                      Navigator.of(modalContext).pop();
                    }
                    _loadData();
                    if (mounted) {
                      UndoToast.show(context, message: 'Budget saved');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Save Budget', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onExportCsv() async {
    try {
      final csvContent = await widget.budgetRepository.exportTransactionsCsv(widget.accountId);
      final docsDir = await getApplicationDocumentsDirectory();
      final file = File('${docsDir.path}/transactions.csv');
      await file.writeAsString(csvContent);

      if (mounted) {
        UndoToast.show(context, message: 'CSV exported: ${file.path}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV Export failed: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  Future<void> _onUpdateWalletBalance(String walletId, int newBalanceInPaisa) async {
    await widget.budgetRepository.updateWalletBalance(
      accountId: widget.accountId,
      walletId: walletId,
      targetBalanceInPaisa: newBalanceInPaisa,
    );
    _loadData();
    if (mounted) {
      UndoToast.show(context, message: 'Balance updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
    }

    return RefreshIndicator(
      color: AppColors.accentOrange,
      backgroundColor: context.appSurface,
      onRefresh: () async {
        if (widget.onRefresh != null) {
          await widget.onRefresh!();
        }
        await _loadData();
      },
      child: BudgetScreen(
        wallets: _wallets,
        transactions: _transactions,
        budgets: _budgets,
        categoryExpenses: _categoryExpenses,
        selectedWalletId: _selectedWalletId,
        onWalletSelected: _onWalletSelected,
        selectedPeriod: _selectedPeriod,
        onPeriodSelected: _onPeriodSelected,
        periodOffset: _periodOffset,
        onPeriodOffsetChanged: _onPeriodOffsetChanged,
        transactionTypeFilter: _transactionTypeFilter,
        onTransactionTypeChanged: _onTransactionTypeChanged,
        selectedCategoryFilter: _selectedCategoryFilter,
        onCategoryFilterChanged: _onCategoryFilterChanged,
        onClearAllFilters: _onClearAllFilters,
        searchQuery: _searchQuery,
        onSearchChanged: _onSearchChanged,
        onAddWallet: _onAddWallet,
        onAddBudget: () => _onAddOrEditBudget(),
        onEditBudget: (b) => _onAddOrEditBudget(b),
        onAddTransaction: _onAddTransaction,
        onEditTransaction: _onEditTransaction,
        onDeleteTransaction: _onDeleteTransaction,
        onExportCsv: _onExportCsv,
        onUpdateWalletBalance: _onUpdateWalletBalance,
      ),
    );
  }
}


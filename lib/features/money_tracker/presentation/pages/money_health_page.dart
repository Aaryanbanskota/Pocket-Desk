import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pocketdesk/features/money_tracker/data/models/expense_model.dart';
import 'package:pocketdesk/features/money_tracker/presentation/providers/money_notifier.dart';
import 'package:pocketdesk/features/settings/presentation/providers/ai_settings_notifier.dart';

class MoneyHealthPage extends ConsumerStatefulWidget {
  const MoneyHealthPage({super.key});

  @override
  ConsumerState<MoneyHealthPage> createState() => _MoneyHealthPageState();
}

class _MoneyHealthPageState extends ConsumerState<MoneyHealthPage> {
  bool _analyzing = false;
  String? _aiAnalysis;

  Future<void> _runAIAnalysis(
    MoneyState state,
    List<ExpenseModel> monthExpenses,
    Map<String, double> categories,
    double totalSpent,
  ) async {
    setState(() {
      _analyzing = true;
      _aiAnalysis = null;
    });
    try {
      final settings = await ref
          .read(aiSettingsRepositoryProvider.future)
          .then((repo) => repo.getOrCreateSettings(state.wallet?.userId ?? 0));

      String? error;
      if (!settings.isEnabled) {
        error =
            'Enable Pocketdesk AI in Settings → AI to generate this report.';
      } else if (settings.apiKey.trim().isEmpty) {
        error = 'Add your OpenRouter API key in Settings → AI to continue.';
      } else if (!settings.allowMoneyAccess || !settings.moneyAnalysisEnabled) {
        error =
            'Enable AI Money Health Analysis and Money Data access in Settings → AI.';
      }
      if (error != null) {
        if (mounted) setState(() => _aiAnalysis = error);
        return;
      }

      final now = DateTime.now();
      final largest = monthExpenses.isEmpty
          ? null
          : monthExpenses.reduce(
              (a, b) => a.amount >= b.amount ? a : b,
            );
      final categoriesText = categories.entries
          .map((entry) =>
              '${entry.key}: ${state.currency} ${entry.value.toStringAsFixed(2)}')
          .join('\n');
      final transactionsText = monthExpenses
          .take(20)
          .map((expense) =>
              '${DateFormat('yyyy-MM-dd').format(expense.date)} | ${expense.category} | ${expense.title} | ${state.currency} ${expense.amount.toStringAsFixed(2)}')
          .join('\n');
      final prompt = '''
Prepare a professional monthly financial audit and receipt summary using only these recorded expense transactions.
Reporting period: ${DateFormat('MMMM yyyy').format(now)}
Current wallet balance: ${state.currency} ${state.currentBalance.toStringAsFixed(2)}
Recorded expenses this month: ${state.currency} ${totalSpent.toStringAsFixed(2)}
Transaction count: ${monthExpenses.length}
Average daily spend: ${state.currency} ${(totalSpent / now.day).toStringAsFixed(2)}
Largest transaction: ${largest == null ? 'None' : '${largest.title} (${largest.category}), ${state.currency} ${largest.amount.toStringAsFixed(2)}'}
Category breakdown:
${categoriesText.isEmpty ? 'None' : categoriesText}

Recent items (up to 20):
${transactionsText.isEmpty ? 'None' : transactionsText}
''';
      const systemPrompt = '''
You are a smart financial analyst summarizing a monthly store-style receipt/statement.
Write a concise breakdown with thermal-bill style section headers:
1. SPENDING SUMMARY & HEALTH RATING
2. TOP SPENDING DRIVERS
3. AI FINANCIAL ADVICE & AUDIT

Keep formatting clean, engaging, and professional.
''';

      final report =
          await ref.read(aiSettingsProvider.notifier).generateCompletion(
                prompt: prompt,
                systemPrompt: systemPrompt,
                maxTokens: 450,
              );
      if (mounted) {
        setState(() {
          _aiAnalysis = report ??
              'Could not generate the report. Check your connection and AI settings, then try again.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _aiAnalysis = 'Report generation failed: $error');
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final receiptPaperColor = isDark ? const Color(0xFF1E1E24) : const Color(0xFFFAF8F5);
    final receiptTextColor = isDark ? const Color(0xFFE2E2E8) : const Color(0xFF1F1F1F);
    final receiptSubtextColor = isDark ? const Color(0xFF9E9EA8) : const Color(0xFF666666);
    final dashColor = isDark ? const Color(0xFF44444E) : const Color(0xFFCCCCCC);

    final authState = ref.watch(authNotifierProvider).valueOrNull;
    String userName = 'Valued Customer';
    if (authState is AuthAuthenticated) {
      userName = authState.user.displayName ?? authState.user.username;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Report & Insights'),
        centerTitle: true,
      ),
      body: ref.watch(moneyProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Could not load report: $error')),
            data: (state) {
              final now = DateTime.now();
              final monthExpenses = state.expenses
                  .where((expense) =>
                      expense.date.year == now.year &&
                      expense.date.month == now.month)
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));
              final totalSpent = monthExpenses.fold(
                  0.0, (sum, expense) => sum + expense.amount);
              final categories = <String, double>{};
              for (final expense in monthExpenses) {
                categories.update(
                  expense.category,
                  (amount) => amount + expense.amount,
                  ifAbsent: () => expense.amount,
                );
              }
              final orderedCategories = categories.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final averagePerDay = totalSpent / (now.day > 0 ? now.day : 1);
              final receiptNo = 'INV-${now.year}${now.month.toString().padLeft(2, '0')}-${(now.day * 137) % 9000 + 1000}';

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      decoration: BoxDecoration(
                        color: receiptPaperColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipPath(
                        clipper: ZigZagClipper(),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: receiptTextColor.withValues(alpha: 0.08),
                                      ),
                                      child: Icon(
                                        Icons.storefront_rounded,
                                        size: 36,
                                        color: receiptTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'POCKETDESK STORE',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.0,
                                        color: receiptTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'MONTHLY EXPENSE RECEIPT',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5,
                                        color: receiptSubtextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'PERIOD: ${DateFormat('MMMM yyyy').format(now).toUpperCase()}',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: receiptSubtextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _DottedDivider(color: dashColor),
                              const SizedBox(height: 12),

                              _ReceiptMetaRow(
                                leftLabel: 'CUSTOMER:',
                                leftValue: userName.toUpperCase(),
                                rightLabel: 'RECEIPT #:',
                                rightValue: receiptNo,
                                textColor: receiptTextColor,
                                subtextColor: receiptSubtextColor,
                              ),
                              const SizedBox(height: 6),
                              _ReceiptMetaRow(
                                leftLabel: 'DATE:',
                                leftValue: DateFormat('yyyy-MM-dd HH:mm').format(now),
                                rightLabel: 'STATUS:',
                                rightValue: state.spendingStatus,
                                textColor: receiptTextColor,
                                subtextColor: receiptSubtextColor,
                              ),

                              const SizedBox(height: 16),
                              _DottedDivider(color: dashColor),
                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: dashColor, width: 1.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'CURRENT WALLET BALANCE',
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: receiptSubtextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _money(state.currency, state.currentBalance),
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: receiptTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'SCORE: ${state.spendingScore}/100',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),
                              Text(
                                'SPENDING BY CATEGORY',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: receiptTextColor,
                                ),
                              ),
                              const SizedBox(height: 8),

                              if (orderedCategories.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'NO EXPENSES RECORDED THIS MONTH',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: receiptSubtextColor,
                                    ),
                                  ),
                                )
                              else
                                ...orderedCategories.map((entry) {
                                  final share = totalSpent == 0
                                      ? 0.0
                                      : entry.value / totalSpent;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.key.toUpperCase(),
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: receiptTextColor,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '(${(share * 100).toStringAsFixed(0)}%) ',
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            color: receiptSubtextColor,
                                          ),
                                        ),
                                        Text(
                                          _money(state.currency, entry.value),
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: receiptTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                              const SizedBox(height: 12),
                              _DottedDivider(color: dashColor),
                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ITEMIZED TRANSACTIONS',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: receiptTextColor,
                                    ),
                                  ),
                                  Text(
                                    '${monthExpenses.length} ITEMS',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      color: receiptSubtextColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              if (monthExpenses.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    'NO RECENT TRANSACTIONS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: receiptSubtextColor,
                                    ),
                                  ),
                                )
                              else
                                ...monthExpenses.take(8).map((expense) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('MM/dd').format(expense.date),
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            color: receiptSubtextColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                expense.title.toUpperCase(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: receiptTextColor,
                                                ),
                                              ),
                                              Text(
                                                expense.category,
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 10,
                                                  color: receiptSubtextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _money(state.currency, expense.amount),
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: receiptTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                              const SizedBox(height: 12),
                              _DottedDivider(color: dashColor),
                              const SizedBox(height: 16),

                              _ReceiptTotalRow(
                                label: 'SUBTOTAL (${monthExpenses.length} Txns):',
                                value: _money(state.currency, totalSpent),
                                textColor: receiptTextColor,
                                subtextColor: receiptSubtextColor,
                              ),
                              const SizedBox(height: 4),
                              _ReceiptTotalRow(
                                label: 'DAILY AVG SPEND:',
                                value: _money(state.currency, averagePerDay),
                                textColor: receiptTextColor,
                                subtextColor: receiptSubtextColor,
                              ),
                              const SizedBox(height: 4),
                              _ReceiptTotalRow(
                                label: 'TAX / FEES (EST. 0%):',
                                value: _money(state.currency, 0.0),
                                textColor: receiptTextColor,
                                subtextColor: receiptSubtextColor,
                              ),
                              const SizedBox(height: 10),
                              _DottedDivider(color: dashColor),
                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL SPENT:',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: receiptTextColor,
                                    ),
                                  ),
                                  Text(
                                    _money(state.currency, totalSpent),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              _DottedDivider(color: dashColor),
                              const SizedBox(height: 16),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'AI AUDIT & INSIGHTS',
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                            color: receiptTextColor,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _analyzing
                                            ? null
                                            : () => _runAIAnalysis(
                                                  state,
                                                  monthExpenses,
                                                  categories,
                                                  totalSpent,
                                                ),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: theme.colorScheme.primary),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_analyzing)
                                                const SizedBox.square(
                                                  dimension: 12,
                                                  child: CircularProgressIndicator(
                                                      strokeWidth: 2),
                                                )
                                              else
                                                Icon(Icons.refresh_rounded,
                                                    size: 14,
                                                    color:
                                                        theme.colorScheme.primary),
                                              const SizedBox(width: 4),
                                              Text(
                                                _analyzing
                                                    ? 'AUDITING...'
                                                    : 'GENERATE',
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (_aiAnalysis == null && !_analyzing)
                                    Text(
                                      'TAP GENERATE TO RUN AN AUTOMATED AI AUDIT ON YOUR MONTHLY EXPENSES.',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: receiptSubtextColor,
                                        height: 1.4,
                                      ),
                                    ),
                                  if (_aiAnalysis != null)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: receiptTextColor.withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: receiptTextColor.withValues(alpha: 0.1)),
                                      ),
                                      child: SelectableText(
                                        _aiAnalysis!,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          height: 1.5,
                                          color: receiptTextColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 24),
                              _DottedDivider(color: dashColor),
                              const SizedBox(height: 20),

                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'THANK YOU FOR USING POCKETDESK!',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                        color: receiptTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'KEEP TRACK • STAY FINANCIALLY FIT',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 9,
                                        color: receiptSubtextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _ReceiptBarcode(color: receiptTextColor),
                                    const SizedBox(height: 8),
                                    Text(
                                      '* $receiptNo *',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        letterSpacing: 3.0,
                                        color: receiptSubtextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  String _money(String currency, double amount) =>
      '$currency ${NumberFormat('#,##0.00').format(amount)}';
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        const dashWidth = 5.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1.5,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ReceiptMetaRow extends StatelessWidget {
  const _ReceiptMetaRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    required this.textColor,
    required this.subtextColor,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final Color textColor;
  final Color subtextColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                '$leftLabel ',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: subtextColor,
                ),
              ),
              Expanded(
                child: Text(
                  leftValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Text(
              '$rightLabel ',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: subtextColor,
              ),
            ),
            Text(
              rightValue,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReceiptTotalRow extends StatelessWidget {
  const _ReceiptTotalRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.subtextColor,
  });

  final String label;
  final String value;
  final Color textColor;
  final Color subtextColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: subtextColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _ReceiptBarcode extends StatelessWidget {
  const _ReceiptBarcode({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final pattern = [2, 1, 3, 1, 2, 4, 1, 2, 3, 1, 1, 2, 3, 2, 1, 4, 2, 1, 3, 1, 2, 1, 4, 1, 2];
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: pattern.map((width) {
          return Container(
            width: width.toDouble() * 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            color: color.withValues(alpha: 0.85),
          );
        }).toList(),
      ),
    );
  }
}

class ZigZagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const toothWidth = 10.0;
    const toothHeight = 6.0;

    path.moveTo(0, toothHeight);

    double x = 0;
    while (x < size.width) {
      path.lineTo(x + toothWidth / 2, 0);
      path.lineTo(x + toothWidth, toothHeight);
      x += toothWidth;
    }

    path.lineTo(size.width, size.height - toothHeight);

    x = size.width;
    while (x > 0) {
      path.lineTo(x - toothWidth / 2, size.height);
      path.lineTo(x - toothWidth, size.height - toothHeight);
      x -= toothWidth;
    }

    path.lineTo(0, toothHeight);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

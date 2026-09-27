import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
Prepare a professional monthly account activity report using only these recorded expense transactions.
Reporting period: ${DateFormat('MMMM yyyy').format(now)}
Current wallet balance: ${state.currency} ${state.currentBalance.toStringAsFixed(2)}
Recorded expenses this month: ${state.currency} ${totalSpent.toStringAsFixed(2)}
Transaction count: ${monthExpenses.length}
Average recorded spend per elapsed calendar day: ${state.currency} ${(totalSpent / now.day).toStringAsFixed(2)}
Largest transaction: ${largest == null ? 'None' : '${largest.title} (${largest.category}), ${state.currency} ${largest.amount.toStringAsFixed(2)}'}
Expense totals by category:
${categoriesText.isEmpty ? 'None' : categoriesText}

Recent transactions (up to 20):
${transactionsText.isEmpty ? 'None' : transactionsText}
''';
      const systemPrompt = '''
You are a careful personal-finance report writer, not a bank and not a financial adviser.
Write a concise, professional statement-style report with headings: Monthly overview, Spending mix, Notable activity, and Practical observations.
Use only the supplied expense records and balance. Do not invent income, budgets, prior-period comparisons, account details, causes, or forecasts. State when there is not enough data to draw a conclusion. Do not repeat raw transaction data unnecessarily. Clearly call these local wallet records, not bank-verified transactions.
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
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Money Report')),
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
              final averagePerDay = totalSpent / now.day;
              final largestCategory =
                  orderedCategories.isEmpty ? null : orderedCategories.first;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    color: colors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: colors.primaryContainer,
                                foregroundColor: colors.onPrimaryContainer,
                                child: const Icon(Icons.receipt_long_rounded),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ACCOUNT ACTIVITY',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                          letterSpacing: 1.1,
                                          fontWeight: FontWeight.w700,
                                        )),
                                    Text(
                                      DateFormat('MMMM yyyy').format(now),
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.info_outline_rounded,
                                  color: colors.onSurfaceVariant),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text('CURRENT WALLET BALANCE',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                                letterSpacing: 0.8,
                              )),
                          const SizedBox(height: 4),
                          Text(
                            _money(state.currency, state.currentBalance),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pocketdesk local wallet • Not a bank statement',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 20),
                          Divider(color: colors.outlineVariant),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = (constraints.maxWidth - 16) / 2;
                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  SizedBox(
                                    width: width,
                                    child: _ReportMetric(
                                      label: 'Spent this month',
                                      value: _money(state.currency, totalSpent),
                                      icon: Icons.south_west_rounded,
                                      color: colors.error,
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    child: _ReportMetric(
                                      label: 'Daily average',
                                      value:
                                          _money(state.currency, averagePerDay),
                                      icon: Icons.calendar_today_rounded,
                                      color: colors.primary,
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    child: _ReportMetric(
                                      label: 'Transactions',
                                      value: '${monthExpenses.length}',
                                      icon: Icons.swap_horiz_rounded,
                                      color: colors.secondary,
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    child: _ReportMetric(
                                      label: 'Top category',
                                      value: largestCategory?.key ?? '—',
                                      icon: Icons.pie_chart_outline_rounded,
                                      color: colors.tertiary,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Spending by category',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          if (orderedCategories.isEmpty)
                            Text('No expenses recorded this month.',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: colors.onSurfaceVariant))
                          else
                            ...orderedCategories.map((entry) {
                              final share = totalSpent == 0
                                  ? 0.0
                                  : entry.value / totalSpent;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                            child: Text(entry.key,
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ))),
                                        Text(
                                          '${_money(state.currency, entry.value)}  ·  ${(share * 100).toStringAsFixed(1)}%',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: share,
                                      minHeight: 7,
                                      borderRadius: BorderRadius.circular(8),
                                      backgroundColor:
                                          colors.surfaceContainerHighest,
                                      color: colors.primary,
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recent activity',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          if (monthExpenses.isEmpty)
                            Text(
                                'Transactions from this month will appear here.',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: colors.onSurfaceVariant))
                          else
                            ...monthExpenses
                                .take(8)
                                .map((expense) => _ActivityRow(
                                      expense: expense,
                                      currency: state.currency,
                                    )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  color: colors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('AI analyst report',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    )),
                              ),
                              TextButton.icon(
                                onPressed: _analyzing
                                    ? null
                                    : () => _runAIAnalysis(
                                          state,
                                          monthExpenses,
                                          categories,
                                          totalSpent,
                                        ),
                                icon: _analyzing
                                    ? const SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.refresh_rounded),
                                label:
                                    Text(_analyzing ? 'Preparing' : 'Generate'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_aiAnalysis == null && !_analyzing)
                            Text(
                              'Generate a transaction-based summary. The report uses your local expense records and does not assume income or a budget.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          if (_aiAnalysis != null)
                            SelectableText(
                              _aiAnalysis!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.55,
                                color: colors.onSurface,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
    );
  }

  String _money(String currency, double amount) =>
      '$currency ${NumberFormat('#,##0.00').format(amount)}';
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.expense, required this.currency});

  final ExpenseModel expense;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colors.surfaceContainerHighest,
        foregroundColor: colors.onSurfaceVariant,
        child: const Icon(Icons.payments_outlined),
      ),
      title: Text(expense.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${expense.category}  ·  ${DateFormat('MMM d').format(expense.date)}',
        style:
            theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
      ),
      trailing: Text(
        '$currency ${NumberFormat('#,##0.00').format(expense.amount)}',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
      ),
    );
  }
}

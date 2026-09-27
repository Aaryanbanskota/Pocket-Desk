import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> _runAIAnalysis(MoneyState moneyState) async {
    setState(() { _analyzing = true; _aiAnalysis = null; });
    final aiSettings = await ref.read(aiSettingsRepositoryProvider.future).then((r) => r.getOrCreateSettings(moneyState.wallet?.userId ?? 0));

    if (!aiSettings.isEnabled) {
      setState(() {
        _analyzing = false;
        _aiAnalysis = 'Pocketdesk AI is currently turned OFF in Settings → AI. Turn ON "Enable Pocketdesk AI" to activate AI insights.';
      });
      return;
    }

    if (aiSettings.apiKey.trim().isEmpty) {
      setState(() {
        _analyzing = false;
        _aiAnalysis = 'API Key is missing! Please enter and save your OpenRouter API key in Settings → AI.';
      });
      return;
    }

    if (!aiSettings.allowMoneyAccess || !aiSettings.moneyAnalysisEnabled) {
      setState(() {
        _analyzing = false;
        _aiAnalysis = 'AI Money Analysis permission is turned off. Check "AI Money Health Analysis" and "Money Data" in Settings → AI.';
      });
      return;
    }

    final catSummary = moneyState.categoryBreakdown.entries
        .map((e) => '${e.key}: ${moneyState.currency} ${e.value.toStringAsFixed(0)}')
        .join(', ');

    final prompt = 'User spent ${moneyState.currency} ${moneyState.thisMonthSpent.toStringAsFixed(0)} this month across categories: $catSummary. Current balance is ${moneyState.currency} ${moneyState.currentBalance.toStringAsFixed(0)}. Spending Score is ${moneyState.spendingScore}/100.';
    const systemPrompt = 'You are Pocketdesk AI analyzing financial spending data. Provide 2 concise bullet point suggestions on how to optimize monthly spending.';

    final res = await ref.read(aiSettingsProvider.notifier).generateCompletion(
      prompt: prompt,
      systemPrompt: systemPrompt,
    );

    setState(() {
      _analyzing = false;
      _aiAnalysis = res ?? 'Unable to connect to OpenRouter. Please verify your API key in Settings → AI.';
    });
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[(month - 1) % 12];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final moneyAsync = ref.watch(moneyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Health'),
      ),
      body: moneyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (moneyState) {
          final breakdown = moneyState.categoryBreakdown;
          final totalSpent = moneyState.thisMonthSpent;
          final now = DateTime.now();
          final currentMonthStr = _getMonthName(now.month);
          final startingBalance = moneyState.currentBalance + totalSpent;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Main AI Money Report Card (Matching user ASCII mockup)
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top header: ✨ AI Money Report + Month
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('✨ ', style: TextStyle(fontSize: 18)),
                            Text('AI Money Report', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(currentMonthStr, style: theme.textTheme.titleSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Your spending this month', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 8),

                    // Amount breakdown line: Rs. X spent | Rs. Y remaining
                    Row(
                      children: [
                        Text(
                          '${moneyState.currency} ${totalSpent.toStringAsFixed(0)} spent',
                          style: TextStyle(fontWeight: FontWeight.bold, color: cs.error, fontSize: 15),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${moneyState.currency} ${moneyState.currentBalance.toStringAsFixed(0)} remaining',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From your ${moneyState.currency} ${startingBalance.toStringAsFixed(0)} starting balance',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Spending Score & Status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${moneyState.spendingScore}/100',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: moneyState.spendingScore >= 70 ? Colors.green : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (moneyState.spendingScore >= 70 ? Colors.green : Colors.orange).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                moneyState.spendingStatus,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: moneyState.spendingScore >= 70 ? Colors.green : Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${moneyState.spendingScore >= 80 ? 'Healthy control over monthly expenses!' : moneyState.spendingScore >= 60 ? 'Spending is steady, but watch non-essential expenses.' : 'High spending detected. Focus on reducing variable costs.'}"',
                      style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),

                    // Top Categories Breakdown (%)
                    Text('Top Categories', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (breakdown.isEmpty)
                      Text('No category expenses recorded.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))
                    else
                      ...breakdown.entries.map((e) {
                        final percentage = totalSpent > 0 ? (e.value / totalSpent * 100).toStringAsFixed(1) : '0';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('${moneyState.currency} ${e.value.toStringAsFixed(0)} ($percentage%)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: totalSpent > 0 ? (e.value / totalSpent) : 0,
                                backgroundColor: cs.surfaceContainerHighest,
                                color: cs.primary,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 20),

                    // AI Insights & Suggestions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('AI Suggestions', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _analyzing ? null : () => _runAIAnalysis(moneyState),
                          icon: _analyzing
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh, size: 16),
                          label: Text(_analyzing ? 'Analyzing...' : 'Generate AI Advice'),
                        ),
                      ],
                    ),
                    if (_aiAnalysis != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          _aiAnalysis!,
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      const Text('• Track daily small purchases to increase remaining balance.', style: TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('• Aim to keep dining & entertainment under 30% of total budget.', style: TextStyle(fontSize: 13)),
                    ],

                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Next Month Targets
                    Text('Next Month Target', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Suggested Spending Cap:', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                        Text('${moneyState.currency} ${(startingBalance * 0.7).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target Savings:', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                        Text('${moneyState.currency} ${(startingBalance * 0.3).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


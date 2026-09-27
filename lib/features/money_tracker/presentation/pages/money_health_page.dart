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

    final prompt = 'User spent ${moneyState.currency} ${moneyState.thisMonthSpent.toStringAsFixed(0)} this month across these categories: $catSummary. Current balance is ${moneyState.currency} ${moneyState.currentBalance.toStringAsFixed(0)}. Spending Score is ${moneyState.spendingScore}/100.';
    const systemPrompt = 'You are Pocketdesk AI analyzing financial spending data. Explain the spending patterns based strictly on the user data provided. Keep explanations concise, objective, clear, and helpful. Do not pretend to be a certified financial advisor.';

    final res = await ref.read(aiSettingsProvider.notifier).generateCompletion(
      prompt: prompt,
      systemPrompt: systemPrompt,
    );

    setState(() {
      _analyzing = false;
      _aiAnalysis = res ?? 'Unable to connect to OpenRouter. Please verify your API key in Settings → AI.';
    });
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

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Current Balance Header
              Card(
                elevation: 0,
                color: cs.primaryContainer.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        '${moneyState.currency} ${moneyState.currentBalance.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Current Balance', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Spending Score Card
              Card(
                elevation: 0,
                color: cs.surfaceContainerHigh,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('Spending Score', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        '${moneyState.spendingScore}/100',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: moneyState.spendingScore >= 70 ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          moneyState.spendingStatus,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You spent ${moneyState.currency} ${moneyState.thisMonthSpent.toStringAsFixed(0)} this month.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Category Breakdown List
              Text('Category Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (breakdown.isEmpty)
                Text('No expenses recorded yet.', style: TextStyle(color: cs.onSurfaceVariant))
              else
                ...breakdown.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(
                            '${moneyState.currency} ${e.value.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.error),
                          ),
                        ],
                      ),
                    )),

              const Divider(height: 36),

              // AI Spending Analysis Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy_rounded, color: cs.primary),
                      const SizedBox(width: 8),
                      Text('AI Insights', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: _analyzing ? null : () => _runAIAnalysis(moneyState),
                    child: _analyzing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Analyze'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_aiAnalysis != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    _aiAnalysis!,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';

class ExpenseItem {
  ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
}

class MoneyTrackerPage extends ConsumerStatefulWidget {
  const MoneyTrackerPage({super.key});

  @override
  ConsumerState<MoneyTrackerPage> createState() => _MoneyTrackerPageState();
}

class _MoneyTrackerPageState extends ConsumerState<MoneyTrackerPage> {
  double _monthlyBudget = 1000.0;
  final List<ExpenseItem> _expenses = [
    ExpenseItem(
      id: '1',
      title: 'Shopping',
      amount: 100.0,
      category: 'Shopping',
      date: DateTime.now(),
    ),
  ];

  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedCategory = 'Shopping';

  double get _totalSpent => _expenses.fold(0.0, (sum, item) => sum + item.amount);
  double get _remainingBudget => _monthlyBudget - _totalSpent;

  void _addExpense() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Expense', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (NPR)')),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () {
                final amt = double.tryParse(_amountCtrl.text);
                if (_titleCtrl.text.isEmpty || amt == null) return;
                setState(() {
                  _expenses.insert(
                    0,
                    ExpenseItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _titleCtrl.text.trim(),
                      amount: amt,
                      category: _selectedCategory,
                      date: DateTime.now(),
                    ),
                  );
                });
                _titleCtrl.clear();
                _amountCtrl.clear();
                Navigator.pop(context);
              },
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentUsed = (_totalSpent / _monthlyBudget).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Tracker'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overview Budget Card
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Text('Monthly Budget Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.md),
                    LinearProgressIndicator(value: percentUsed, minHeight: 10, borderRadius: BorderRadius.circular(5)),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('Budget', style: theme.textTheme.bodySmall),
                            Text('NPR ${_monthlyBudget.toStringAsFixed(0)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('Spent', style: theme.textTheme.bodySmall),
                            Text('NPR ${_totalSpent.toStringAsFixed(0)}', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('Remaining', style: theme.textTheme.bodySmall),
                            Text('NPR ${_remainingBudget.toStringAsFixed(0)}', style: theme.textTheme.titleMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Header for Expense List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Expenses', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                FilledButton.icon(onPressed: _addExpense, icon: const Icon(Icons.add_rounded), label: const Text('Add')),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final exp = _expenses[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  color: colorScheme.surfaceContainerHighest.withAlpha(30),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary.withAlpha(20),
                      child: Icon(Icons.shopping_bag_outlined, color: colorScheme.primary),
                    ),
                    title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${exp.date.day}/${exp.date.month}/${exp.date.year} • ${exp.category}'),
                    trailing: Text(
                      '- NPR ${exp.amount.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.error),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

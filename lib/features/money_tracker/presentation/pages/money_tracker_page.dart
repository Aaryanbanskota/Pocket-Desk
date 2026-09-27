import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketdesk/core/theme/app_spacing.dart';
import 'package:pocketdesk/features/dashboard/presentation/widgets/app_hamburger_drawer.dart';
import 'package:pocketdesk/features/money_tracker/data/models/expense_model.dart';
import 'package:pocketdesk/features/money_tracker/presentation/providers/money_notifier.dart';
import 'money_health_page.dart';

class MoneyTrackerPage extends ConsumerStatefulWidget {
  const MoneyTrackerPage({super.key});

  @override
  ConsumerState<MoneyTrackerPage> createState() => _MoneyTrackerPageState();
}

class _MoneyTrackerPageState extends ConsumerState<MoneyTrackerPage> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();

  String _selectedCategory = 'Food';
  final List<String> _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Bills',
    'Health',
    'Education',
    'Other',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _tagsCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _showSetBalanceDialog(MoneyState state) {
    _balanceCtrl.text = state.currentBalance.toStringAsFixed(0);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Wallet Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _balanceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Starting Balance (${state.currency})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final bal = double.tryParse(_balanceCtrl.text.trim());
              if (bal != null) {
                ref.read(moneyProvider.notifier).updateBalance(bal);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseModal([ExpenseModel? editExpense]) {
    if (editExpense != null) {
      _titleCtrl.text = editExpense.title;
      _amountCtrl.text = editExpense.amount.toStringAsFixed(0);
      _selectedCategory = editExpense.category;
      _noteCtrl.text = editExpense.note ?? '';
      _tagsCtrl.text = editExpense.tags.join(', ');
    } else {
      _titleCtrl.clear();
      _amountCtrl.clear();
      _noteCtrl.clear();
      _tagsCtrl.clear();
      _selectedCategory = 'Food';
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editExpense == null ? 'Add Expense' : 'Edit Expense',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _categories.contains(_selectedCategory) ? _selectedCategory : _categories.first,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Optional Note', border: OutlineInputBorder()),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _tagsCtrl,
                decoration: const InputDecoration(labelText: 'Tags (comma separated)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () {
                  final title = _titleCtrl.text.trim();
                  final amt = double.tryParse(_amountCtrl.text.trim());
                  if (title.isEmpty || amt == null) return;

                  final tags = _tagsCtrl.text
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();

                  if (editExpense == null) {
                    ref.read(moneyProvider.notifier).addExpense(
                      title: title,
                      amount: amt,
                      category: _selectedCategory,
                      date: DateTime.now(),
                      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                      tags: tags,
                    );
                  } else {
                    final updated = ExpenseModel()
                      ..id = editExpense.id
                      ..userId = editExpense.userId
                      ..title = title
                      ..amount = amt
                      ..category = _selectedCategory
                      ..date = editExpense.date
                      ..note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()
                      ..tags = tags;

                    ref.read(moneyProvider.notifier).editExpense(editExpense, updated);
                  }

                  Navigator.pop(ctx);
                },
                child: Text(editExpense == null ? 'Save Expense' : 'Update Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final moneyAsync = ref.watch(moneyProvider);

    return Scaffold(
      drawer: const AppHamburgerDrawer(),
      appBar: AppBar(
        title: const Text('Money Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.monitor_heart_outlined),
            tooltip: 'Money Health',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const MoneyHealthPage()),
              );
            },
          ),
        ],
      ),
      body: moneyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          final expenses = state.filteredExpenses;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Wallet Balance Card
              Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Current Wallet Balance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showSetBalanceDialog(state),
                            tooltip: 'Edit Balance',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${state.currency} ${state.currentBalance.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatColumn(label: "Today's Spent", amount: state.todaySpent, currency: state.currency),
                          _StatColumn(label: 'This Week', amount: state.thisWeekSpent, currency: state.currency),
                          _StatColumn(label: 'This Month', amount: state.thisMonthSpent, currency: state.currency),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Search & Filter Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search expenses…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      onChanged: (q) => ref.read(moneyProvider.notifier).setSearchQuery(q),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String?>(
                    icon: Icon(
                      Icons.filter_list_rounded,
                      color: state.filterCategory != null ? cs.primary : null,
                    ),
                    onSelected: (cat) => ref.read(moneyProvider.notifier).setFilterCategory(cat),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem<String?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ..._categories.map((c) => PopupMenuItem<String?>(
                            value: c,
                            child: Text(c),
                          )),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Expenses List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    state.filterCategory == null ? 'Expense History (${expenses.length})' : '${state.filterCategory} Expenses',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddExpenseModal(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Expense'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (expenses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No expenses recorded', style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final exp = expenses[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.account_balance_wallet_outlined, color: cs.primary),
                        ),
                        title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${exp.date.day}/${exp.date.month}/${exp.date.year} • ${exp.category}${exp.note != null ? ' • ${exp.note}' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '- ${state.currency} ${exp.amount.toStringAsFixed(0)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: cs.error),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showAddExpenseModal(exp),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              onPressed: () {
                                ref.read(moneyProvider.notifier).deleteExpense(exp);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Deleted "${exp.title}"'),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      onPressed: () {
                                        ref.read(moneyProvider.notifier).undoDelete();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.amount, required this.currency});
  final String label;
  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          '$currency ${amount.toStringAsFixed(0)}',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.error),
        ),
      ],
    );
  }
}

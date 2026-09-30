import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pocketdesk/core/theme/app_spacing.dart';
import 'package:pocketdesk/features/dashboard/presentation/widgets/app_hamburger_drawer.dart';
import 'package:pocketdesk/features/money_tracker/data/models/expense_model.dart';
import 'package:pocketdesk/features/money_tracker/presentation/providers/money_notifier.dart';
import 'money_health_page.dart';

/// Modern, Material 3 redesigned Money Tracker Page.
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
  static const List<String> _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Bills',
    'Health',
    'Education',
    'Other',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_bus_rounded,
    'Entertainment': Icons.sports_esports_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Health': Icons.medical_services_rounded,
    'Education': Icons.school_rounded,
    'Other': Icons.category_rounded,
  };

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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Starting Balance (${state.currency})',
                prefixText: '${state.currency} ',
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
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      editExpense == null ? 'New Expense' : 'Edit Expense',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Expense Title',
                    hintText: 'e.g., Grocery Shopping',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: '0.00',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _categories.contains(_selectedCategory) ? _selectedCategory : _categories.first,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                Icon(_categoryIcons[c] ?? Icons.category_rounded, size: 20),
                                const SizedBox(width: 10),
                                Text(c),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => _selectedCategory = val);
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Optional Note',
                    hintText: 'Add description or location',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _tagsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
                    hintText: 'e.g., personal, essential',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () {
                    final title = _titleCtrl.text.trim();
                    final amt = double.tryParse(_amountCtrl.text.trim());
                    if (title.isEmpty || amt == null || amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid title and positive amount')),
                      );
                      return;
                    }

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
                  icon: Icon(editExpense == null ? Icons.check_rounded : Icons.save_rounded),
                  label: Text(editExpense == null ? 'Save Expense' : 'Update Expense'),
                ),
              ],
            ),
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
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Money Health Report',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const MoneyHealthPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseModal(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
      body: moneyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
                const SizedBox(height: 12),
                Text('Could not load financial data', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('$e', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        data: (state) {
          final expenses = state.filteredExpenses;
          final categoryBreakdown = state.categoryBreakdown;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(moneyProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Premium Balance Banner Card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primaryContainer, cs.surfaceContainerHigh],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.account_balance_wallet_rounded, color: cs.primary, size: 22),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Current Wallet Balance',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showSetBalanceDialog(state),
                              tooltip: 'Edit Starting Balance',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${state.currency} ${NumberFormat('#,##0.00').format(state.currentBalance)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatMetricTile(
                                icon: Icons.today_rounded,
                                label: 'Today',
                                amount: state.todaySpent,
                                currency: state.currency,
                              ),
                            ),
                            Container(width: 1, height: 36, color: cs.outlineVariant.withValues(alpha: 0.5)),
                            Expanded(
                              child: _StatMetricTile(
                                icon: Icons.date_range_rounded,
                                label: 'This Week',
                                amount: state.thisWeekSpent,
                                currency: state.currency,
                              ),
                            ),
                            Container(width: 1, height: 36, color: cs.outlineVariant.withValues(alpha: 0.5)),
                            Expanded(
                              child: _StatMetricTile(
                                icon: Icons.calendar_month_rounded,
                                label: 'This Month',
                                amount: state.thisMonthSpent,
                                currency: state.currency,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Category Quick Breakdown Chips (if expenses exist)
                if (categoryBreakdown.isNotEmpty) ...[
                  Text(
                    'Category Breakdown',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryBreakdown.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final entry = categoryBreakdown.entries.toList()[index];
                        final isFiltered = state.filterCategory == entry.key;
                        return FilterChip(
                          selected: isFiltered,
                          avatar: Icon(_categoryIcons[entry.key] ?? Icons.category_rounded, size: 16),
                          label: Text('${entry.key}: ${state.currency}${entry.value.toStringAsFixed(0)}'),
                          onSelected: (selected) {
                            ref.read(moneyProvider.notifier).setFilterCategory(selected ? entry.key : null);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Search & Category Filter Section
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search title, category, tags…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: cs.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          isDense: true,
                        ),
                        onChanged: (q) => ref.read(moneyProvider.notifier).setSearchQuery(q),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String?>(
                      tooltip: 'Filter Category',
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: state.filterCategory != null ? cs.primaryContainer : cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.filter_list_rounded,
                          color: state.filterCategory != null ? cs.onPrimaryContainer : cs.onSurface,
                        ),
                      ),
                      onSelected: (cat) => ref.read(moneyProvider.notifier).setFilterCategory(cat),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem<String?>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.all_inclusive_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('All Categories'),
                            ],
                          ),
                        ),
                        ..._categories.map((c) => PopupMenuItem<String?>(
                              value: c,
                              child: Row(
                                children: [
                                  Icon(_categoryIcons[c] ?? Icons.category_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(c),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.filterCategory == null
                          ? 'Recent Expenses (${expenses.length})'
                          : '${state.filterCategory} (${expenses.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (state.filterCategory != null || state.searchQuery.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          ref.read(moneyProvider.notifier).setFilterCategory(null);
                          ref.read(moneyProvider.notifier).setSearchQuery('');
                        },
                        icon: const Icon(Icons.clear_all_rounded, size: 16),
                        label: const Text('Reset Filters'),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                if (expenses.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 64, color: cs.outline.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No Expenses Found',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.searchQuery.isNotEmpty || state.filterCategory != null
                              ? 'Try searching with another keyword or resetting filters.'
                              : 'Tap "Add Expense" below to start tracking your daily spendings!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final exp = expenses[index];
                      final categoryIcon = _categoryIcons[exp.category] ?? Icons.category_rounded;

                      return Card(
                        elevation: 0,
                        color: cs.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: cs.primaryContainer,
                            foregroundColor: cs.onPrimaryContainer,
                            child: Icon(categoryIcon, size: 22),
                          ),
                          title: Text(
                            exp.title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                '${DateFormat('MMM d, yyyy').format(exp.date)} • ${exp.category}',
                                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              if (exp.note != null && exp.note!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  exp.note!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                                ),
                              ],
                              if (exp.tags.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  children: exp.tags
                                      .map((t) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: cs.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '#$t',
                                              style: TextStyle(fontSize: 10, color: cs.primary),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '- ${state.currency}${exp.amount.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.error,
                                ),
                              ),
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, size: 20),
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    _showAddExpenseModal(exp);
                                  } else if (action == 'delete') {
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
                                  }
                                },
                                itemBuilder: (ctx) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 80), // Bottom padding for FAB
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatMetricTile extends StatelessWidget {
  const _StatMetricTile({
    required this.icon,
    required this.label,
    required this.amount,
    required this.currency,
  });

  final IconData icon;
  final String label;
  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$currency ${amount.toStringAsFixed(0)}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.error,
          ),
        ),
      ],
    );
  }
}


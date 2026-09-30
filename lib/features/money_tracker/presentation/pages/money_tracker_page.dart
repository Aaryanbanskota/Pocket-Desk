import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pocketdesk/core/theme/app_spacing.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pocketdesk/features/dashboard/presentation/widgets/app_hamburger_drawer.dart';
import 'package:pocketdesk/features/money_tracker/data/models/expense_model.dart';
import 'package:pocketdesk/features/money_tracker/presentation/providers/money_notifier.dart';
import 'money_health_page.dart';

/// Professional, Material 3 Redesigned Money Tracker Page with Interactive MasterCard.
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
  final _customCategoryCtrl = TextEditingController();

  // Mastercard Details Controllers
  late final TextEditingController _cardHolderCtrl;
  final _cardNumberCtrl = TextEditingController(text: '5412 7512 3412 8990');
  final _expiryCtrl = TextEditingController(text: '12/28');
  final _cvvCtrl = TextEditingController(text: '888');
  final _balanceCtrl = TextEditingController();

  bool _showCardBack = false;
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
    'Other': Icons.more_horiz_rounded,
  };

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authNotifierProvider).valueOrNull;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final username = user?.displayName ?? user?.username ?? 'POCKETDESK USER';
    _cardHolderCtrl = TextEditingController(text: username.toUpperCase());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _tagsCtrl.dispose();
    _customCategoryCtrl.dispose();
    _cardHolderCtrl.dispose();
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _showEditCardDialog(MoneyState state) {
    _balanceCtrl.text = state.currentBalance.toStringAsFixed(0);
    showDialog<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.credit_card_rounded, color: Colors.amber, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Edit Card Details',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _cardHolderCtrl,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Cardholder Name',
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(ctx).colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cardNumberCtrl,
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(ctx).colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.credit_card_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryCtrl,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Expires',
                        hintText: 'MM/YY',
                        isDense: true,
                        filled: true,
                        fillColor: Theme.of(ctx).colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _cvvCtrl,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'CVV / CVC',
                        hintText: '888',
                        isDense: true,
                        filled: true,
                        fillColor: Theme.of(ctx).colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Wallet Balance (${state.currency})',
                  prefixText: '${state.currency} ',
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(ctx).colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              final bal = double.tryParse(_balanceCtrl.text.trim());
              if (bal != null) {
                ref.read(moneyProvider.notifier).updateBalance(bal);
              }
              setState(() {});
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Save Details'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseModal([ExpenseModel? editExpense]) {
    if (editExpense != null) {
      _titleCtrl.text = editExpense.title;
      _amountCtrl.text = editExpense.amount.toStringAsFixed(0);
      if (_categories.contains(editExpense.category)) {
        _selectedCategory = editExpense.category;
        _customCategoryCtrl.clear();
      } else {
        _selectedCategory = 'Other';
        _customCategoryCtrl.text = editExpense.category;
      }
      _noteCtrl.text = editExpense.note ?? '';
      _tagsCtrl.text = editExpense.tags.join(', ');
    } else {
      _titleCtrl.clear();
      _amountCtrl.clear();
      _noteCtrl.clear();
      _tagsCtrl.clear();
      _customCategoryCtrl.clear();
      _selectedCategory = 'Food';
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      editExpense == null ? 'Record New Expense' : 'Edit Expense Record',
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Expense Title',
                    hintText: 'e.g. Dinner, Rent, Flight',
                    filled: true,
                    fillColor: Theme.of(ctx).colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.shopping_cart_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(ctx).colorScheme.error),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: '0.00',
                    filled: true,
                    fillColor: Theme.of(ctx).colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _categories.contains(_selectedCategory) ? _selectedCategory : 'Other',
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: Theme.of(ctx).colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.category_outlined),
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
                if (_selectedCategory == 'Other') ...[
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _customCategoryCtrl,
                    decoration: InputDecoration(
                      labelText: 'Custom Category Name',
                      hintText: 'Enter your custom category',
                      filled: true,
                      fillColor: Theme.of(ctx).colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.label_outline_rounded),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(
                    labelText: 'Optional Note',
                    hintText: 'Merchant details or description',
                    filled: true,
                    fillColor: Theme.of(ctx).colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _tagsCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tags (comma separated)',
                    hintText: 'e.g. personal, urgent',
                    filled: true,
                    fillColor: Theme.of(ctx).colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.tag_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final title = _titleCtrl.text.trim();
                    final amt = double.tryParse(_amountCtrl.text.trim());
                    if (title.isEmpty || amt == null || amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid title and positive amount')),
                      );
                      return;
                    }

                    final finalCategory = _selectedCategory == 'Other' && _customCategoryCtrl.text.trim().isNotEmpty
                        ? _customCategoryCtrl.text.trim()
                        : _selectedCategory;

                    final tags = _tagsCtrl.text
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();

                    if (editExpense == null) {
                      ref.read(moneyProvider.notifier).addExpense(
                            title: title,
                            amount: amt,
                            category: finalCategory,
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
                        ..category = finalCategory
                        ..date = editExpense.date
                        ..note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()
                        ..tags = tags;

                      ref.read(moneyProvider.notifier).editExpense(editExpense, updated);
                    }

                    Navigator.pop(ctx);
                  },
                  icon: Icon(editExpense == null ? Icons.check_circle_rounded : Icons.save_rounded),
                  label: Text(
                    editExpense == null ? 'Add Expense' : 'Update Expense',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
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
            child: Text('Error: $e'),
          ),
        ),
        data: (state) {
          final expenses = state.filteredExpenses;
          final categoryBreakdown = state.categoryBreakdown;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(moneyProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // ─── Interactive MasterCard Widget ─────────────────────────────
                GestureDetector(
                  onTap: () => setState(() => _showCardBack = !_showCardBack),
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 400),
                    crossFadeState: _showCardBack ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: _buildMasterCardFront(context, state, cs),
                    secondChild: _buildMasterCardBack(context, state, cs),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ─── Stat Metric Row ───────────────────────────────────────────
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
                    Container(width: 1, height: 32, color: cs.outlineVariant.withValues(alpha: 0.4)),
                    Expanded(
                      child: _StatMetricTile(
                        icon: Icons.date_range_rounded,
                        label: 'This Week',
                        amount: state.thisWeekSpent,
                        currency: state.currency,
                      ),
                    ),
                    Container(width: 1, height: 32, color: cs.outlineVariant.withValues(alpha: 0.4)),
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

                const SizedBox(height: AppSpacing.lg),

                // ─── Category Breakdown Horizontal List ───────────────────────
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

                // ─── Search and Category Filter Bar ────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search expenses or tags…',
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
                          child: Text('All Categories'),
                        ),
                        ..._categories.map((c) => PopupMenuItem<String?>(
                              value: c,
                              child: Row(
                                children: [
                                  Icon(_categoryIcons[c] ?? Icons.category_rounded, size: 18),
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

                // ─── Expenses List Header ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.filterCategory == null
                          ? 'Recent Transactions (${expenses.length})'
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
                        label: const Text('Reset'),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                if (expenses.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.credit_card_off_rounded, size: 56, color: cs.outline.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('No Expenses Found', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Add Expense" below to start logging your finances!',
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
                          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
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
                                          onPressed: () => ref.read(moneyProvider.notifier).undoDelete(),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (ctx) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── MasterCard Front View Widget ──────────────────────────────────────────
  Widget _buildMasterCardFront(BuildContext context, MoneyState state, ColorScheme cs) {
    return Container(
      key: const ValueKey(false),
      height: 210,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2C), Color(0xFF2D2B42), Color(0xFF1A1921)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.nfc_rounded, color: Colors.white70, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'POCKETDESK BANK',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), letterSpacing: 1.5, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                onPressed: () => _showEditCardDialog(state),
                tooltip: 'Edit Card Details',
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BALANCE', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, letterSpacing: 1.2)),
                  Text(
                    '${state.currency} ${NumberFormat('#,##0.00').format(state.currentBalance)}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                ],
              ),
              // Mastercard Circles Logo
              SizedBox(
                width: 48,
                height: 30,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(color: const Color(0xFFF79E1B).withValues(alpha: 0.9), shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cardNumberCtrl.text.isEmpty ? '5412 7512 3412 8990' : _cardNumberCtrl.text,
                    style: const TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cardHolderCtrl.text.toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('EXPIRES', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9)),
                  Text(_expiryCtrl.text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── MasterCard Back View Widget ───────────────────────────────────────────
  Widget _buildMasterCardBack(BuildContext context, MoneyState state, ColorScheme cs) {
    return Container(
      key: const ValueKey(true),
      height: 210,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15141E), Color(0xFF232230)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Magnetic Stripe
          Container(height: 40, color: Colors.black),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    color: Colors.white70,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      _cvvCtrl.text,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('CVV/CVC', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tap card to view front', style: TextStyle(color: Colors.white54, fontSize: 10)),
                Text('MasterCard SecureCode', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
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



import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketdesk/core/database/isar_provider.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pocketdesk/features/money_tracker/data/models/wallet_model.dart';
import 'package:pocketdesk/features/money_tracker/data/models/expense_model.dart';
import 'package:pocketdesk/features/money_tracker/data/repositories/money_repository.dart';

final moneyRepositoryProvider = FutureProvider<MoneyRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return MoneyRepository(isar: isar);
});

class MoneyState {
  const MoneyState({
    this.wallet,
    this.expenses = const [],
    this.recentlyDeleted,
    this.filterCategory,
    this.searchQuery = '',
    this.isLoading = false,
  });

  final WalletModel? wallet;
  final List<ExpenseModel> expenses;
  final ExpenseModel? recentlyDeleted;
  final String? filterCategory;
  final String searchQuery;
  final bool isLoading;

  double get currentBalance => wallet?.balance ?? 10000.0;
  String get currency => wallet?.currency ?? 'Rs.';

  List<ExpenseModel> get filteredExpenses {
    return expenses.where((e) {
      if (filterCategory != null && filterCategory!.isNotEmpty && e.category != filterCategory) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchTitle = e.title.toLowerCase().contains(q);
        final matchCat = e.category.toLowerCase().contains(q);
        final matchTags = e.tags.any((t) => t.toLowerCase().contains(q));
        if (!matchTitle && !matchCat && !matchTags) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get todaySpent {
    final now = DateTime.now();
    return expenses.where((e) =>
      e.date.year == now.year && e.date.month == now.month && e.date.day == now.day
    ).fold(0.0, (sum, e) => sum + e.amount);
  }

  double get thisWeekSpent {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return expenses.where((e) => e.date.isAfter(startOfDay)).fold(0.0, (sum, e) => sum + e.amount);
  }

  double get thisMonthSpent {
    final now = DateTime.now();
    return expenses.where((e) =>
      e.date.year == now.year && e.date.month == now.month
    ).fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalSpent => expenses.fold(0.0, (sum, e) => sum + e.amount);

  Map<String, double> get categoryBreakdown {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0.0) + e.amount;
    }
    return map;
  }

  int get spendingScore {
    final spent = thisMonthSpent;
    if (spent <= 5000) return 92;
    if (spent <= 10000) return 85;
    if (spent <= 20000) return 72;
    if (spent <= 40000) return 58;
    return 40;
  }

  String get spendingStatus {
    final s = spendingScore;
    if (s >= 85) return 'Excellent 🟢';
    if (s >= 70) return 'Good 🟢';
    if (s >= 50) return 'Moderate 🟡';
    return 'High Spending 🔴';
  }

  MoneyState copyWith({
    WalletModel? wallet,
    List<ExpenseModel>? expenses,
    ExpenseModel? recentlyDeleted,
    bool clearRecentlyDeleted = false,
    String? filterCategory,
    bool clearFilterCategory = false,
    String? searchQuery,
    bool? isLoading,
  }) {
    return MoneyState(
      wallet: wallet ?? this.wallet,
      expenses: expenses ?? this.expenses,
      recentlyDeleted: clearRecentlyDeleted ? null : recentlyDeleted ?? this.recentlyDeleted,
      filterCategory: clearFilterCategory ? null : filterCategory ?? this.filterCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MoneyNotifier extends AutoDisposeAsyncNotifier<MoneyState> {
  @override
  Future<MoneyState> build() async {
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return const MoneyState();

    final repo = await ref.watch(moneyRepositoryProvider.future);
    final wallet = await repo.getOrCreateWallet(auth.user.id);
    final expenses = await repo.getExpenses(auth.user.id);

    return MoneyState(wallet: wallet, expenses: expenses);
  }

  Future<void> updateBalance(double newBalance, {String? currency}) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;
    final repo = await ref.read(moneyRepositoryProvider.future);
    await repo.updateWalletBalance(auth.user.id, newBalance, currency: currency);
    ref.invalidateSelf();
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
    List<String> tags = const [],
  }) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;
    final repo = await ref.read(moneyRepositoryProvider.future);

    final expense = ExpenseModel()
      ..userId = auth.user.id
      ..title = title
      ..amount = amount
      ..category = category
      ..date = date
      ..note = note
      ..tags = tags;

    await repo.addExpense(expense);
    ref.invalidateSelf();
  }

  Future<void> editExpense(ExpenseModel oldExp, ExpenseModel newExp) async {
    final repo = await ref.read(moneyRepositoryProvider.future);
    await repo.updateExpense(oldExp, newExp);
    ref.invalidateSelf();
  }

  Future<void> deleteExpense(ExpenseModel expense) async {
    final repo = await ref.read(moneyRepositoryProvider.future);
    await repo.softDeleteExpense(expense);
    final current = state.valueOrNull ?? const MoneyState();
    state = AsyncValue.data(current.copyWith(recentlyDeleted: expense));
    ref.invalidateSelf();
  }

  Future<void> undoDelete() async {
    final current = state.valueOrNull;
    if (current?.recentlyDeleted == null) return;
    final repo = await ref.read(moneyRepositoryProvider.future);
    await repo.restoreExpense(current!.recentlyDeleted!);
    state = AsyncValue.data(current.copyWith(clearRecentlyDeleted: true));
    ref.invalidateSelf();
  }

  void setFilterCategory(String? cat) {
    final current = state.valueOrNull ?? const MoneyState();
    state = AsyncValue.data(current.copyWith(
      filterCategory: cat,
      clearFilterCategory: cat == null,
    ));
  }

  void setSearchQuery(String q) {
    final current = state.valueOrNull ?? const MoneyState();
    state = AsyncValue.data(current.copyWith(searchQuery: q));
  }
}

final moneyProvider = AutoDisposeAsyncNotifierProvider<MoneyNotifier, MoneyState>(
  MoneyNotifier.new,
);

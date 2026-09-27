import 'package:isar/isar.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/wallet_model.dart';
import '../models/expense_model.dart';

class MoneyRepository {
  MoneyRepository({required Isar isar}) : _isar = isar;
  final Isar _isar;

  // ─── Wallet Operations ───────────────────────────────────────────────────

  Future<WalletModel> getOrCreateWallet(int userId) async {
    try {
      final existing = await _isar.walletModels
          .where()
          .userIdEqualTo(userId)
          .findFirst();
      if (existing != null) return existing;

      final newWallet = WalletModel()
        ..userId = userId
        ..name = 'Main Wallet'
        ..balance = 10000.0
        ..currency = 'Rs.'
        ..isDefault = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await _isar.writeTxn(() => _isar.walletModels.put(newWallet));
      return newWallet;
    } catch (e, st) {
      AppLogger.e('Failed to get/create wallet', tag: 'MoneyRepo', error: e, st: st);
      return WalletModel()
        ..userId = userId
        ..balance = 10000.0;
    }
  }

  Future<void> updateWalletBalance(int userId, double newBalance, {String? currency}) async {
    try {
      final wallet = await getOrCreateWallet(userId);
      wallet.balance = newBalance;
      if (currency != null) wallet.currency = currency;
      wallet.updatedAt = DateTime.now();
      await _isar.writeTxn(() => _isar.walletModels.put(wallet));
    } catch (e, st) {
      AppLogger.e('Failed to update wallet balance', tag: 'MoneyRepo', error: e, st: st);
    }
  }

  // ─── Expense Operations ──────────────────────────────────────────────────

  Future<List<ExpenseModel>> getExpenses(int userId, {bool includeDeleted = false}) async {
    try {
      final list = await _isar.expenseModels
          .where()
          .userIdEqualTo(userId)
          .findAll();
      if (!includeDeleted) {
        return list.where((e) => !e.isDeleted).toList();
      }
      return list;
    } catch (e, st) {
      AppLogger.e('Failed to fetch expenses', tag: 'MoneyRepo', error: e, st: st);
      return [];
    }
  }

  Future<({ExpenseModel? expense, AppFailure? error})> addExpense(ExpenseModel expense) async {
    try {
      final now = DateTime.now();
      expense.createdAt = now;
      expense.updatedAt = now;

      final wallet = await getOrCreateWallet(expense.userId);
      wallet.balance -= expense.amount; // Automatic balance deduction
      wallet.updatedAt = now;

      await _isar.writeTxn(() async {
        await _isar.expenseModels.put(expense);
        await _isar.walletModels.put(wallet);
      });

      return (expense: expense, error: null);
    } catch (e, st) {
      AppLogger.e('Failed to add expense', tag: 'MoneyRepo', error: e, st: st);
      return (expense: null, error: UnexpectedFailure('Failed to save expense', error: e, stackTrace: st));
    }
  }

  Future<void> updateExpense(ExpenseModel oldExpense, ExpenseModel newExpense) async {
    try {
      final now = DateTime.now();
      newExpense.updatedAt = now;

      final wallet = await getOrCreateWallet(oldExpense.userId);
      // Adjust balance difference
      final diff = newExpense.amount - oldExpense.amount;
      wallet.balance -= diff;
      wallet.updatedAt = now;

      await _isar.writeTxn(() async {
        await _isar.expenseModels.put(newExpense);
        await _isar.walletModels.put(wallet);
      });
    } catch (e, st) {
      AppLogger.e('Failed to update expense', tag: 'MoneyRepo', error: e, st: st);
    }
  }

  Future<void> softDeleteExpense(ExpenseModel expense) async {
    try {
      final now = DateTime.now();
      expense.isDeleted = true;
      expense.deletedAt = now;
      expense.updatedAt = now;

      // Refund balance
      final wallet = await getOrCreateWallet(expense.userId);
      wallet.balance += expense.amount;
      wallet.updatedAt = now;

      await _isar.writeTxn(() async {
        await _isar.expenseModels.put(expense);
        await _isar.walletModels.put(wallet);
      });
    } catch (e, st) {
      AppLogger.e('Failed to soft delete expense', tag: 'MoneyRepo', error: e, st: st);
    }
  }

  Future<void> restoreExpense(ExpenseModel expense) async {
    try {
      final now = DateTime.now();
      expense.isDeleted = false;
      expense.deletedAt = null;
      expense.updatedAt = now;

      // Deduct balance again
      final wallet = await getOrCreateWallet(expense.userId);
      wallet.balance -= expense.amount;
      wallet.updatedAt = now;

      await _isar.writeTxn(() async {
        await _isar.expenseModels.put(expense);
        await _isar.walletModels.put(wallet);
      });
    } catch (e, st) {
      AppLogger.e('Failed to restore expense', tag: 'MoneyRepo', error: e, st: st);
    }
  }
}

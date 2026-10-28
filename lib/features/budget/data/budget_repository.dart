import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/myday_database.dart';

class MyDayWallet {
  final String id;
  final String accountId;
  final String name;
  final String currency;
  final int initialBalance; // in minor units (paisa)
  final int currentBalance; // in minor units (paisa)
  final bool isArchived;
  final bool isDeleted;

  const MyDayWallet({
    required this.id,
    required this.accountId,
    required this.name,
    this.currency = 'Rs',
    required this.initialBalance,
    required this.currentBalance,
    this.isArchived = false,
    this.isDeleted = false,
  });

  factory MyDayWallet.fromRow(QueryRow row, int computedBalance) {
    return MyDayWallet(
      id: row.read<String>('id'),
      accountId: row.read<String>('account_id'),
      name: row.read<String>('name'),
      currency: row.read<String>('currency'),
      initialBalance: row.read<int>('initial_balance'),
      currentBalance: computedBalance,
      isArchived: row.read<int>('is_archived') == 1,
      isDeleted: row.read<int>('is_deleted') == 1,
    );
  }
}

class MyDayTransaction {
  final String id;
  final String accountId;
  final String walletId;
  final String? toWalletId;
  final String type; // 'Income' | 'Expense' | 'Transfer'
  final String category;
  final int amount; // in minor units (paisa)
  final int transactionTime; // milliseconds since epoch
  final String note;
  final bool isDeleted;

  const MyDayTransaction({
    required this.id,
    required this.accountId,
    required this.walletId,
    this.toWalletId,
    required this.type,
    required this.category,
    required this.amount,
    required this.transactionTime,
    this.note = '',
    this.isDeleted = false,
  });

  factory MyDayTransaction.fromRow(QueryRow row) {
    return MyDayTransaction(
      id: row.read<String>('id'),
      accountId: row.read<String>('account_id'),
      walletId: row.read<String>('wallet_id'),
      toWalletId: row.read<String?>('to_wallet_id'),
      type: row.read<String>('type'),
      category: row.read<String>('category'),
      amount: row.read<int>('amount'),
      transactionTime: row.read<int>('transaction_time'),
      note: row.read<String>('note'),
      isDeleted: row.read<int>('is_deleted') == 1,
    );
  }
}

class MyDayBudget {
  final String id;
  final String accountId;
  final String category;
  final int monthlyLimit; // in minor units (paisa)
  final int spentThisMonth; // in minor units (paisa)

  const MyDayBudget({
    required this.id,
    required this.accountId,
    required this.category,
    required this.monthlyLimit,
    required this.spentThisMonth,
  });

  int get remaining => monthlyLimit - spentThisMonth;
  double get percent => monthlyLimit > 0 ? (spentThisMonth / monthlyLimit) : 0.0;
  bool get isOverspent => spentThisMonth > monthlyLimit;
}

class BudgetRepository {
  final MyDayDatabase db;
  static const _uuid = Uuid();

  BudgetRepository(this.db);

  /// Formats minor units (paisa) to human-readable currency string, e.g. "Rs 1,82,650"
  static String formatAmount(int amountInMinorUnits, {String currency = 'Rs'}) {
    final double value = amountInMinorUnits / 100.0;
    final formatter = NumberFormat('#,##,###.##', 'en_IN');
    final formattedNum = formatter.format(value);
    return '$currency $formattedNum';
  }

  /// Retrieves all wallets with dynamically computed ledger balances
  Future<List<MyDayWallet>> getWallets(String accountId) async {
    final walletRows = await db.customSelect(
      'SELECT * FROM wallets WHERE account_id = ? AND is_deleted = 0 ORDER BY created_at ASC',
      variables: [Variable(accountId)],
    ).get();

    final List<MyDayWallet> result = [];

    for (final row in walletRows) {
      final walletId = row.read<String>('id');
      final initBal = row.read<int>('initial_balance');

      // Incomes to this wallet
      final incRows = await db.customSelect(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total 
        FROM transactions 
        WHERE account_id = ? AND wallet_id = ? AND type = 'Income' AND is_deleted = 0
        ''',
        variables: [Variable(accountId), Variable(walletId)],
      ).getSingle();

      // Expenses from this wallet
      final expRows = await db.customSelect(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total 
        FROM transactions 
        WHERE account_id = ? AND wallet_id = ? AND type = 'Expense' AND is_deleted = 0
        ''',
        variables: [Variable(accountId), Variable(walletId)],
      ).getSingle();

      // Transfers out of this wallet
      final tfOutRows = await db.customSelect(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total 
        FROM transactions 
        WHERE account_id = ? AND wallet_id = ? AND type = 'Transfer' AND is_deleted = 0
        ''',
        variables: [Variable(accountId), Variable(walletId)],
      ).getSingle();

      // Transfers into this wallet
      final tfInRows = await db.customSelect(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total 
        FROM transactions 
        WHERE account_id = ? AND to_wallet_id = ? AND type = 'Transfer' AND is_deleted = 0
        ''',
        variables: [Variable(accountId), Variable(walletId)],
      ).getSingle();

      final totalIncome = incRows.read<int>('total');
      final totalExpense = expRows.read<int>('total');
      final totalTransferOut = tfOutRows.read<int>('total');
      final totalTransferIn = tfInRows.read<int>('total');

      final computedBal = initBal + totalIncome - totalExpense - totalTransferOut + totalTransferIn;

      result.add(MyDayWallet.fromRow(row, computedBal));
    }

    return result;
  }

  /// Calculates total net worth across all active wallets
  Future<int> getTotalNetWorth(String accountId) async {
    final wallets = await getWallets(accountId);
    return wallets.fold<int>(0, (sum, w) => sum + w.currentBalance);
  }

  /// Adds a new wallet
  Future<MyDayWallet> addWallet({
    required String accountId,
    required String name,
    String currency = 'Rs',
    required int initialBalanceMinor,
  }) async {
    final id = _uuid.v4().substring(0, 8);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.customInsert(
      '''
      INSERT INTO wallets (id, account_id, name, currency, initial_balance, is_archived, is_deleted, sync_status, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, 0, 0, 'pending', ?, ?)
      ''',
      variables: [
        Variable(id),
        Variable(accountId),
        Variable(name),
        Variable(currency),
        Variable(initialBalanceMinor),
        Variable(nowMs),
        Variable(nowMs),
      ],
    );

    return MyDayWallet(
      id: id,
      accountId: accountId,
      name: name,
      currency: currency,
      initialBalance: initialBalanceMinor,
      currentBalance: initialBalanceMinor,
    );
  }

  /// Sets/Adjusts the total current balance of a wallet to targetBalanceInPaisa
  Future<void> updateWalletBalance({
    required String accountId,
    required String walletId,
    required int targetBalanceInPaisa,
  }) async {
    final incRows = await db.customSelect(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total 
      FROM transactions 
      WHERE account_id = ? AND wallet_id = ? AND type = 'Income' AND is_deleted = 0
      ''',
      variables: [Variable(accountId), Variable(walletId)],
    ).getSingle();

    final expRows = await db.customSelect(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total 
      FROM transactions 
      WHERE account_id = ? AND wallet_id = ? AND type = 'Expense' AND is_deleted = 0
      ''',
      variables: [Variable(accountId), Variable(walletId)],
    ).getSingle();

    final tfOutRows = await db.customSelect(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total 
      FROM transactions 
      WHERE account_id = ? AND wallet_id = ? AND type = 'Transfer' AND is_deleted = 0
      ''',
      variables: [Variable(accountId), Variable(walletId)],
    ).getSingle();

    final tfInRows = await db.customSelect(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total 
      FROM transactions 
      WHERE account_id = ? AND to_wallet_id = ? AND type = 'Transfer' AND is_deleted = 0
      ''',
      variables: [Variable(accountId), Variable(walletId)],
    ).getSingle();

    final totalIncome = incRows.read<int>('total');
    final totalExpense = expRows.read<int>('total');
    final totalTransferOut = tfOutRows.read<int>('total');
    final totalTransferIn = tfInRows.read<int>('total');

    final netTransactions = totalIncome - totalExpense - totalTransferOut + totalTransferIn;
    final newInitialBalance = targetBalanceInPaisa - netTransactions;

    await db.customUpdate(
      'UPDATE wallets SET initial_balance = ?, updated_at = ? WHERE id = ? AND account_id = ?',
      variables: [
        Variable(newInitialBalance),
        Variable(DateTime.now().millisecondsSinceEpoch),
        Variable(walletId),
        Variable(accountId),
      ],
    );
  }

  /// Retrieves transactions within a date range with optional wallet and type filters
  Future<List<MyDayTransaction>> getTransactions({
    required String accountId,
    String? walletId,
    String typeFilter = 'all', // 'all', 'Expense', 'Income', 'Transfer'
    String categoryFilter = 'all',
    int? startTimeMs,
    int? endTimeMs,
    String searchQuery = '',
  }) async {
    String where = 'account_id = ? AND is_deleted = 0';
    List<Variable> vars = [Variable(accountId)];

    if (walletId != null && walletId != 'all') {
      where += ' AND (wallet_id = ? OR to_wallet_id = ?)';
      vars.add(Variable(walletId));
      vars.add(Variable(walletId));
    }

    if (typeFilter != 'all') {
      where += ' AND type = ?';
      vars.add(Variable(typeFilter));
    }

    if (categoryFilter != 'all' && categoryFilter.isNotEmpty) {
      where += ' AND category = ?';
      vars.add(Variable(categoryFilter));
    }

    if (startTimeMs != null) {
      where += ' AND transaction_time >= ?';
      vars.add(Variable(startTimeMs));
    }

    if (endTimeMs != null) {
      where += ' AND transaction_time < ?';
      vars.add(Variable(endTimeMs));
    }

    if (searchQuery.isNotEmpty) {
      where += ' AND (note LIKE ? OR category LIKE ?)';
      vars.add(Variable('%$searchQuery%'));
      vars.add(Variable('%$searchQuery%'));
    }

    final rows = await db.customSelect(
      'SELECT * FROM transactions WHERE $where ORDER BY transaction_time DESC, created_at DESC',
      variables: vars,
    ).get();

    return rows.map(MyDayTransaction.fromRow).toList();
  }

  /// Adds a new transaction (Income, Expense, or Transfer)
  Future<MyDayTransaction> addTransaction({
    required String accountId,
    required String walletId,
    String? toWalletId,
    required String type, // 'Income' | 'Expense' | 'Transfer'
    required String category,
    required int amountMinor,
    required int transactionTime,
    String note = '',
  }) async {
    final id = _uuid.v4().substring(0, 8);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.customInsert(
      '''
      INSERT INTO transactions (
        id, account_id, wallet_id, to_wallet_id, type, category,
        amount, transaction_time, note, is_deleted, sync_status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 'pending', ?, ?)
      ''',
      variables: [
        Variable(id),
        Variable(accountId),
        Variable(walletId),
        Variable(toWalletId),
        Variable(type),
        Variable(category),
        Variable(amountMinor),
        Variable(transactionTime),
        Variable(note),
        Variable(nowMs),
        Variable(nowMs),
      ],
    );

    return MyDayTransaction(
      id: id,
      accountId: accountId,
      walletId: walletId,
      toWalletId: toWalletId,
      type: type,
      category: category,
      amount: amountMinor,
      transactionTime: transactionTime,
      note: note,
    );
  }

  /// Updates an existing transaction
  Future<void> updateTransaction(MyDayTransaction tx) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customUpdate(
      '''
      UPDATE transactions SET
        wallet_id = ?, to_wallet_id = ?, type = ?, category = ?,
        amount = ?, transaction_time = ?, note = ?, sync_status = 'pending', updated_at = ?
      WHERE id = ?
      ''',
      variables: [
        Variable(tx.walletId),
        Variable(tx.toWalletId),
        Variable(tx.type),
        Variable(tx.category),
        Variable(tx.amount),
        Variable(tx.transactionTime),
        Variable(tx.note),
        Variable(nowMs),
        Variable(tx.id),
      ],
    );
  }

  /// Soft deletes transaction (moves to trash)
  Future<void> deleteTransaction(String transactionId) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customUpdate(
      "UPDATE transactions SET is_deleted = 1, deleted_at = ?, sync_status = 'pending' WHERE id = ?",
      variables: [Variable(nowMs), Variable(transactionId)],
    );
  }

  /// Retrieves category spending totals for a given date range
  Future<Map<String, int>> getCategoryExpenses({
    required String accountId,
    String? walletId,
    required int startTimeMs,
    required int endTimeMs,
  }) async {
    String where =
        "account_id = ? AND type = 'Expense' AND is_deleted = 0 AND transaction_time >= ? AND transaction_time < ?";
    List<Variable> vars = [
      Variable(accountId),
      Variable(startTimeMs),
      Variable(endTimeMs),
    ];

    if (walletId != null && walletId != 'all') {
      where += ' AND wallet_id = ?';
      vars.add(Variable(walletId));
    }

    final rows = await db.customSelect(
      '''
      SELECT category, SUM(amount) AS total 
      FROM transactions 
      WHERE $where 
      GROUP BY category 
      ORDER BY total DESC
      ''',
      variables: vars,
    ).get();

    final Map<String, int> result = {};
    for (final r in rows) {
      result[r.read<String>('category')] = r.read<int>('total');
    }
    return result;
  }

  Future<Map<String, int>> getExpensesByCategory({
    required String accountId,
    String? walletId,
    int? startTimeMs,
    int? endTimeMs,
    bool allTime = false,
  }) async {
    final now = DateTime.now();
    final start = allTime
        ? 0
        : (startTimeMs ?? DateTime(now.year, now.month, 1).millisecondsSinceEpoch);
    final end = allTime
        ? DateTime(2100).millisecondsSinceEpoch
        : (endTimeMs ?? DateTime(now.year, now.month + 1, 1).millisecondsSinceEpoch);
    return getCategoryExpenses(
      accountId: accountId,
      walletId: walletId,
      startTimeMs: start,
      endTimeMs: end,
    );
  }

  /// Retrieves monthly budgets with actual spending calculated
  Future<List<MyDayBudget>> getBudgets(String accountId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final endOfMonth = DateTime(now.year, now.month + 1, 1).millisecondsSinceEpoch;

    final budgetRows = await db.customSelect(
      'SELECT * FROM budgets WHERE account_id = ? AND is_deleted = 0 ORDER BY created_at ASC',
      variables: [Variable(accountId)],
    ).get();

    final List<MyDayBudget> list = [];

    for (final row in budgetRows) {
      final category = row.read<String>('category');
      final limit = row.read<int>('monthly_limit');

      final spentRow = await db.customSelect(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total 
        FROM transactions 
        WHERE account_id = ? AND category = ? AND type = 'Expense' AND is_deleted = 0
          AND transaction_time >= ? AND transaction_time < ?
        ''',
        variables: [
          Variable(accountId),
          Variable(category),
          Variable(startOfMonth),
          Variable(endOfMonth),
        ],
      ).getSingle();

      final spent = spentRow.read<int>('total');

      list.add(
        MyDayBudget(
          id: row.read<String>('id'),
          accountId: accountId,
          category: category,
          monthlyLimit: limit,
          spentThisMonth: spent,
        ),
      );
    }

    return list;
  }

  /// Adds or updates a monthly budget
  Future<void> setBudget({
    required String accountId,
    required String category,
    required int limitMinor,
    String? existingId,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    if (existingId != null) {
      await db.customUpdate(
        'UPDATE budgets SET category = ?, monthly_limit = ?, updated_at = ? WHERE id = ?',
        variables: [
          Variable(category),
          Variable(limitMinor),
          Variable(nowMs),
          Variable(existingId),
        ],
      );
    } else {
      final id = _uuid.v4().substring(0, 8);
      await db.customInsert(
        '''
        INSERT INTO budgets (id, account_id, category, monthly_limit, is_deleted, sync_status, created_at, updated_at)
        VALUES (?, ?, ?, ?, 0, 'pending', ?, ?)
        ''',
        variables: [
          Variable(id),
          Variable(accountId),
          Variable(category),
          Variable(limitMinor),
          Variable(nowMs),
          Variable(nowMs),
        ],
      );
    }
  }

  /// Soft deletes budget
  Future<void> deleteBudget(String budgetId) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customUpdate(
      "UPDATE budgets SET is_deleted = 1, deleted_at = ?, sync_status = 'pending' WHERE id = ?",
      variables: [Variable(nowMs), Variable(budgetId)],
    );
  }

  /// Exports transactions to CSV string
  Future<String> exportTransactionsCsv(String accountId) async {
    final txs = await getTransactions(accountId: accountId);
    final wallets = await getWallets(accountId);
    final walletMap = {for (var w in wallets) w.id: w.name};

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Date,Type,Category,Wallet,Amount,Note');

    for (final t in txs) {
      final dateStr = DateFormat('yyyy-MM-dd').format(
        DateTime.fromMillisecondsSinceEpoch(t.transactionTime),
      );
      final walletName = walletMap[t.walletId] ?? 'Main';
      final cleanNote = '"${t.note.replaceAll('"', '""')}"';
      final amt = (t.amount / 100.0).toStringAsFixed(2);

      buffer.writeln('$dateStr,${t.type},${t.category},$walletName,$amt,$cleanNote');
    }

    return buffer.toString();
  }
}

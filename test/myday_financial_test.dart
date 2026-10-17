import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/database/myday_database.dart';
import 'package:pocketdesk/features/budget/data/budget_repository.dart';

void main() {
  group('MyDay Financial & Ledger Tests', () {
    late MyDayDatabase db;
    late BudgetRepository budgetRepo;
    const testAccountId = 'test_user_financial';

    setUp(() async {
      db = MyDayDatabase.create(inMemory: true);
      await db.initDatabase();
      budgetRepo = BudgetRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Minor-unit currency formatting respects en_IN grouping', () {
      expect(BudgetRepository.formatAmount(18265000), 'Rs 1,82,650');
      expect(BudgetRepository.formatAmount(5000), 'Rs 50');
      expect(BudgetRepository.formatAmount(12550), 'Rs 125.5');
      expect(BudgetRepository.formatAmount(0), 'Rs 0');
    });

    test('Multi-wallet balance dynamically computes ledger transactions', () async {
      // 1. Create wallet with initial balance 50,000 paisa (Rs 500)
      final wallet = await budgetRepo.addWallet(
        accountId: testAccountId,
        name: 'Checking',
        initialBalanceMinor: 50000,
      );

      var wallets = await budgetRepo.getWallets(testAccountId);
      expect(wallets.length, 1);
      expect(wallets.first.currentBalance, 50000);

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 2. Add income (+25,000 paisa = Rs 250)
      await budgetRepo.addTransaction(
        accountId: testAccountId,
        walletId: wallet.id,
        type: 'Income',
        category: 'Salary',
        amountMinor: 25000,
        transactionTime: nowMs,
        note: 'Part-time freelance',
      );

      // 3. Add expense (-10,000 paisa = Rs 100)
      await budgetRepo.addTransaction(
        accountId: testAccountId,
        walletId: wallet.id,
        type: 'Expense',
        category: 'Food',
        amountMinor: 10000,
        transactionTime: nowMs + 1000,
        note: 'Lunch at cafe',
      );

      wallets = await budgetRepo.getWallets(testAccountId);
      expect(wallets.first.currentBalance, 65000); // 50000 + 25000 - 10000 = 65000
    });

    test('Spendee Transfer Neutrality: transfers move funds without inflating income/expense', () async {
      // Wallet A: 100,000 paisa (Rs 1,000)
      final walletA = await budgetRepo.addWallet(
        accountId: testAccountId,
        name: 'Bank',
        initialBalanceMinor: 100000,
      );

      // Wallet B: 20,000 paisa (Rs 200)
      final walletB = await budgetRepo.addWallet(
        accountId: testAccountId,
        name: 'Cash Pocket',
        initialBalanceMinor: 20000,
      );

      // Total net worth before transfer
      final netWorthBefore = await budgetRepo.getTotalNetWorth(testAccountId);
      expect(netWorthBefore, 120000);

      // Execute transfer: 15,000 paisa from Bank to Cash Pocket
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await budgetRepo.addTransaction(
        accountId: testAccountId,
        walletId: walletA.id,
        toWalletId: walletB.id,
        type: 'Transfer',
        category: 'Transfer',
        amountMinor: 15000,
        transactionTime: nowMs,
        note: 'ATM withdrawal',
      );

      // Verify wallet balances after transfer
      final wallets = await budgetRepo.getWallets(testAccountId);
      final updatedA = wallets.firstWhere((w) => w.id == walletA.id);
      final updatedB = wallets.firstWhere((w) => w.id == walletB.id);

      expect(updatedA.currentBalance, 85000); // 100,000 - 15,000
      expect(updatedB.currentBalance, 35000); // 20,000 + 15,000

      // Net worth MUST remain strictly neutral
      final netWorthAfter = await budgetRepo.getTotalNetWorth(testAccountId);
      expect(netWorthAfter, 120000);

      // Expense category breakdown must NOT include transfers
      final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1).millisecondsSinceEpoch;
      final endOfMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 1).millisecondsSinceEpoch;

      final categoryExpenses = await budgetRepo.getCategoryExpenses(
        accountId: testAccountId,
        startTimeMs: startOfMonth,
        endTimeMs: endOfMonth,
      );

      expect(categoryExpenses.containsKey('Transfer'), isFalse);
      expect(categoryExpenses.values.fold<int>(0, (sum, v) => sum + v), 0);
    });

    test('Monthly budgets accurately track spending, remaining balance, and overspent states', () async {
      // Set monthly budget of 20,000 paisa (Rs 200) for 'Food'
      await budgetRepo.setBudget(
        accountId: testAccountId,
        category: 'Food',
        limitMinor: 20000,
      );

      final wallet = await budgetRepo.addWallet(
        accountId: testAccountId,
        name: 'Main',
        initialBalanceMinor: 500000,
      );

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // Expense 1: 12,000 paisa on Food
      await budgetRepo.addTransaction(
        accountId: testAccountId,
        walletId: wallet.id,
        type: 'Expense',
        category: 'Food',
        amountMinor: 12000,
        transactionTime: nowMs,
      );

      var budgets = await budgetRepo.getBudgets(testAccountId);
      expect(budgets.length, 1);
      final budget = budgets.first;
      expect(budget.category, 'Food');
      expect(budget.monthlyLimit, 20000);
      expect(budget.spentThisMonth, 12000);
      expect(budget.remaining, 8000);
      expect(budget.percent, closeTo(0.6, 0.001));
      expect(budget.isOverspent, isFalse);

      // Expense 2: additional 10,000 paisa on Food (total 22,000 paisa > 20,000 limit)
      await budgetRepo.addTransaction(
        accountId: testAccountId,
        walletId: wallet.id,
        type: 'Expense',
        category: 'Food',
        amountMinor: 10000,
        transactionTime: nowMs + 1000,
      );

      budgets = await budgetRepo.getBudgets(testAccountId);
      final overspentBudget = budgets.first;
      expect(overspentBudget.spentThisMonth, 22000);
      expect(overspentBudget.remaining, -2000);
      expect(overspentBudget.percent, closeTo(1.1, 0.001));
      expect(overspentBudget.isOverspent, isTrue);
    });

    test('CSV export generates compliant format with quoted notes', () async {
      final wallet = await budgetRepo.addWallet(
        accountId: testAccountId,
        name: 'Personal Card',
        initialBalanceMinor: 100000,
      );

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await budgetRepo.addTransaction(
        accountId: testAccountId,
        walletId: wallet.id,
        type: 'Expense',
        category: 'Shopping',
        amountMinor: 4999,
        transactionTime: nowMs,
        note: 'Book: "Clean Code", 2nd Edition',
      );

      final csv = await budgetRepo.exportTransactionsCsv(testAccountId);
      expect(csv.startsWith('Date,Type,Category,Wallet,Amount,Note'), isTrue);
      expect(csv.contains('Personal Card'), isTrue);
      expect(csv.contains('49.99'), isTrue);
      expect(csv.contains('""Clean Code""'), isTrue);
    });
  });
}

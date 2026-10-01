import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/theme/app_theme.dart';
import 'package:pocketdesk/features/money_tracker/data/models/expense_model.dart';
import 'package:pocketdesk/features/money_tracker/data/models/wallet_model.dart';
import 'package:pocketdesk/features/money_tracker/presentation/pages/money_health_page.dart';
import 'package:pocketdesk/features/money_tracker/presentation/providers/money_notifier.dart';

class _MoneyNotifierWithTransactions extends MoneyNotifier {
  @override
  Future<MoneyState> build() async {
    final now = DateTime.now();
    return MoneyState(
      wallet: WalletModel()
        ..userId = 1
        ..balance = 8300
        ..currency = 'Rs.',
      expenses: [
        ExpenseModel()
          ..userId = 1
          ..title = 'Coffee'
          ..amount = 500
          ..category = 'Food'
          ..date = DateTime(now.year, now.month, 2),
        ExpenseModel()
          ..userId = 1
          ..title = 'Groceries'
          ..amount = 1200
          ..category = 'Food'
          ..date = DateTime(now.year, now.month, 3),
        ExpenseModel()
          ..userId = 1
          ..title = 'Older trip'
          ..amount = 9000
          ..category = 'Travel'
          ..date = DateTime(now.year, now.month - 1, 12),
      ],
    );
  }
}

void main() {
  testWidgets('report totals only current-month expenses in light theme',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moneyProvider.overrideWith(_MoneyNotifierWithTransactions.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MoneyHealthPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ITEMIZED TRANSACTIONS'), findsOneWidget);
    expect(find.text('Rs. 8,300.00'), findsOneWidget);
    expect(find.text('Rs. 1,700.00'), findsAtLeastNWidgets(1));
    expect(find.text('Food'), findsNWidgets(2));
    expect(find.text('Older trip'), findsNothing);
  });
}

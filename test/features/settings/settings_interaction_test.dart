import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/database/myday_database.dart';
import 'package:pocketdesk/core/design_system/widgets/app_scaffold.dart';
import 'package:pocketdesk/features/auth/data/auth_repository.dart';
import 'package:pocketdesk/features/budget/data/budget_repository.dart';
import 'package:pocketdesk/features/feed/data/feed_repository.dart';
import 'package:pocketdesk/features/notes/data/notes_repository.dart';
import 'package:pocketdesk/features/settings/presentation/settings_screen.dart';
import 'package:pocketdesk/features/tasks/data/tasks_repository.dart';
import 'package:pocketdesk/features/trash/data/trash_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SettingsScreen interactions test', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      'last_username': 'akash',
    });
    final db = MyDayDatabase.create(inMemory: true);
    await db.initDatabase();

    final session = UserSession(
      accountId: 'acc_1',
      name: 'Akash Test',
      handle: 'akash',
      bio: 'Developer',
      isCloud: false,
      isBioEnabled: true,
    );

    MyDayNavTab? navigatedTab;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsScreen(
            session: session,
            authRepository: AuthRepository(db),
            tasksRepository: TasksRepository(db),
            notesRepository: NotesRepository(db),
            budgetRepository: BudgetRepository(db),
            feedRepository: FeedRepository(db),
            trashRepository: TrashRepository(db),
            isDarkMode: true,
            onThemeToggle: () {},
            onNavigate: (tab) => navigatedTab = tab,
            onLogout: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Find and tap Default Currency
    final currencyFinder = find.text('Default Currency');
    expect(currencyFinder, findsOneWidget);
    await tester.tap(currencyFinder);
    await tester.pumpAndSettle();

    // Verify bottom sheet opened
    expect(find.text('Select Default Currency'), findsOneWidget);
    // Tap close or currency
    await tester.tap(find.text('USD - United States Dollar'));
    await tester.pumpAndSettle();

    // 2. Find and tap Auto-Lock
    final autoLockFinder = find.text('Auto-Lock');
    expect(autoLockFinder, findsOneWidget);
    await tester.tap(autoLockFinder);
    await tester.pumpAndSettle();

    expect(find.text('Auto-Lock Timeout'), findsOneWidget);
    await tester.tap(find.text('After 5 minutes'));
    await tester.pumpAndSettle();

    // 3. Find and tap Pull Old Pocketdesk Data
    final pullFinder = find.text('Pull Old Pocketdesk Data');
    expect(pullFinder, findsOneWidget);
    await tester.tap(pullFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    for (int i = 0; i < 25; i++) {
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    expect(find.text('Pull Old Pocketdesk Data'), findsWidgets);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 4. Test Empty Trash confirmation dialog
    final emptyTrashFinder = find.text('Empty Trash');
    expect(emptyTrashFinder, findsOneWidget);
    await tester.tap(emptyTrashFinder);
    await tester.pumpAndSettle();

    expect(find.text('Empty Trash?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 5. Test Device & Home Screen Widgets navigation
    final widgetsFinder = find.text('Device & Home Screen Widgets');
    expect(widgetsFinder, findsOneWidget);
    await tester.tap(widgetsFinder);
    await tester.pumpAndSettle();
    expect(navigatedTab, equals(MyDayNavTab.widgets));

    await db.close();
  });
}

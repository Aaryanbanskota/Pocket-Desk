import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/database/myday_database.dart';
import 'package:pocketdesk/core/design_system/app_icons.dart';
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

  testWidgets('Settings -> Version -> About App -> 10-tap Developer Mode Unlock & Inspector Test',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      'developer_mode_unlocked': false,
    });

    final db = MyDayDatabase.create(inMemory: true);
    await db.initDatabase();

    const session = UserSession(
      accountId: 'test_dev_acc',
      name: 'Tester',
      handle: 'tester',
      bio: 'Testing Dev Mode',
      isCloud: false,
      isBioEnabled: false,
    );

    // Seed some test data in tasks and notes to verify decrypted display
    final tasksRepo = TasksRepository(db);
    final notesRepo = NotesRepository(db);
    await tasksRepo.addTask(
      accountId: 'test_dev_acc',
      title: 'Dev Test Task',
      dueDate: '2026-10-28',
      tags: ['event', 'testing'],
      note: 'Decrypted Task Note',
    );
    await notesRepo.createNote(
      accountId: 'test_dev_acc',
      title: 'Dev Test Note',
      body: 'Decrypted Note Content',
    );

    // 1. Pump SettingsScreen
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsScreen(
            session: session,
            authRepository: AuthRepository(db),
            tasksRepository: tasksRepo,
            notesRepository: notesRepo,
            budgetRepository: BudgetRepository(db),
            feedRepository: FeedRepository(db),
            trashRepository: TrashRepository(db),
            isDarkMode: true,
            onThemeToggle: () {},
            onNavigate: (_) {},
            onLogout: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Version row is displayed in Settings
    final versionRowFinder = find.text('Version');
    expect(versionRowFinder, findsOneWidget);

    // Tap Version to open AboutAppScreen
    await tester.tap(versionRowFinder);
    await tester.pumpAndSettle();

    // Verify AboutAppScreen is open
    expect(find.text('About Pocketdesk'), findsOneWidget);
    expect(find.text('Recent Update Date:'), findsOneWidget);
    expect(find.text('October 26, 2026'), findsOneWidget);

    // Find the version target container
    final versionTarget = find.text('Recent Update Date:');
    expect(versionTarget, findsOneWidget);

    // Tap 10 times to unlock Developer Mode
    for (int i = 0; i < 10; i++) {
      await tester.tap(versionTarget);
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Allow any floating snackbars/toasts to finish
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Verify Developer Mode is unlocked and button is present
    expect(find.text('Developer Mode Active'), findsOneWidget);
    final openDevBtn = find.text('Open Developer Tools & Inspector');
    expect(openDevBtn, findsOneWidget);

    // Dismiss any active snackbar toast before navigating
    ScaffoldMessenger.of(tester.element(openDevBtn)).clearSnackBars();
    await tester.pump(const Duration(milliseconds: 500));

    // 2. Open DeveloperModeScreen
    await tester.ensureVisible(openDevBtn);
    await tester.tap(openDevBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify DeveloperModeScreen rendered with tabs
    expect(find.text('Developer Mode'), findsOneWidget);
    expect(find.text('Architecture'), findsOneWidget);
    expect(find.text('Calendar Hub'), findsOneWidget);
    expect(find.text('Tables Explorer'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);

    // Verify Architecture tab information
    expect(find.text('Local SQLite Engine'), findsOneWidget);
    expect(find.text('Architecture Analysis & Evaluation'), findsOneWidget);

    // 3. Switch to Calendar Hub tab
    await tester.tap(find.text('Calendar Hub'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('How Calendar Data is Stored'), findsOneWidget);
    expect(find.text('Tasks & Scheduled Events'), findsOneWidget);

    // 4. Switch to Tables Explorer tab
    await tester.tap(find.text('Tables Explorer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Dev Test Task'), findsOneWidget);
    expect(find.text('Inspect JSON'), findsWidgets);

    // Inspect JSON bottom sheet
    await tester.tap(find.text('Inspect JSON').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Decrypted Record Data'), findsOneWidget);

    // Close JSON sheet
    await tester.tap(find.byIcon(AppIcons.close).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 5. Back navigation
    await tester.tap(find.byIcon(AppIcons.back).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/database/myday_database.dart';
import 'package:pocketdesk/features/auth/data/auth_repository.dart';
import 'package:pocketdesk/features/auth/presentation/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AuthScreen Local & Cloud Flow Tests', () {
    late MyDayDatabase inMemoryDb;
    late AuthRepository authRepository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      inMemoryDb = MyDayDatabase.create(inMemory: true);
      await inMemoryDb.initDatabase();
      authRepository = AuthRepository(inMemoryDb);
    });

    tearDown(() async {
      await inMemoryDb.close();
    });

    testWidgets('Local account creation: 4th digit visual feedback & successful confirmation', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      UserSession? authenticatedSession;

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            authRepository: authRepository,
            onAuthenticated: (session) {
              authenticatedSession = session;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify on Local account tab by default
      expect(find.text('Create local account'), findsOneWidget);

      // 1. Enter name and accept terms
      await tester.enterText(find.byType(TextField).first, 'Aaryan Test');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Now on Step 1: Create a PIN
      expect(find.text('Create a PIN'), findsOneWidget);
      expect(find.textContaining('Step 1 of 2'), findsOneWidget);

      // Tap digits 1, 2, 3
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();

      // Tap digit 4
      await tester.tap(find.text('4'));
      await tester.pump(); // Frame renders with all 4 dots filled

      // Wait past the 220ms visual feedback delay
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Should now be on Step 2: Confirm your PIN
      expect(find.text('Confirm your PIN'), findsOneWidget);
      expect(find.textContaining('Step 2 of 2'), findsOneWidget);

      // Confirm with 1, 2, 3, 4
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();

      // Wait past delay
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify user was successfully authenticated!
      expect(authenticatedSession, isNotNull);
      expect(authenticatedSession!.name, equals('Aaryan Test'));
      expect(authenticatedSession!.isCloud, isFalse);
    });

    testWidgets('Local account PIN mismatch keeps confirmation step and allows retry', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            authRepository: authRepository,
            onAuthenticated: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Enter name & agree
      await tester.enterText(find.byType(TextField).first, 'Aaryan Test');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Enter 1, 2, 3, 4
      for (final d in ['1', '2', '3', '4']) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Enter mismatched PIN: 9, 9, 9, 9
      for (final d in ['9', '9', '9', '9']) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Error should be displayed and stay on confirmation
      expect(find.text('PINs did not match. Please re-enter your 4-digit PIN.'), findsOneWidget);
      expect(find.text('Confirm your PIN'), findsOneWidget);

      // User can tap 'Change PIN' button to go back to Step 1
      expect(find.text('Change PIN'), findsOneWidget);
      await tester.tap(find.text('Change PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Create a PIN'), findsOneWidget);
    });

    testWidgets('Physical keyboard input enters PIN digits and Backspace deletes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            authRepository: authRepository,
            onAuthenticated: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Enter name & agree
      await tester.enterText(find.byType(TextField).first, 'Aaryan Keyboard');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Create a PIN'), findsOneWidget);

      // Send key events for '1', '2'
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pump();

      // Send backspace
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      // Send '5', '6', '7'
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
      await tester.pump();

      // Wait 300ms
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Step 2 should be reached with PIN "1567"
      expect(find.text('Confirm your PIN'), findsOneWidget);
    });

    testWidgets('Cloud tab renders Forgot Password and opens dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            authRepository: authRepository,
            onAuthenticated: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Cloud tab
      await tester.tap(find.text('Cloud account'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);

      // Tap Forgot password?
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Link'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsNothing);
    });
  });
}

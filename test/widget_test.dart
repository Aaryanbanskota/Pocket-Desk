import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/app/app.dart';
import 'package:pocketdesk/features/auth/presentation/pages/login_page.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';

/// Resolves auth immediately as unauthenticated — exercises router redirect
/// without waiting on Isar / secure storage in the widget test harness.
class _ImmediateUnauthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthUnauthenticated();
}

void main() {
  testWidgets('PocketDesk root widget renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PocketDeskApp(),
      ),
    );

    expect(find.byType(PocketDeskApp), findsOneWidget);
  });

  testWidgets('Unauthenticated users redirect from splash to login',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_ImmediateUnauthNotifier.new),
        ],
        child: const PocketDeskApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}

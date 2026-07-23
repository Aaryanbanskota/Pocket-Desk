import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/app/app.dart';

void main() {
  testWidgets('PocketDesk root widget renders successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: PocketDeskApp(),
      ),
    );

    // Verify that the foundation active screen renders.
    expect(find.text('PocketDesk Foundation Active'), findsOneWidget);
  });
}

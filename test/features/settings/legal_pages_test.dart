import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/settings/data/models/ai_settings_model.dart';
import 'package:pocketdesk/features/settings/presentation/pages/legal_document_page.dart';
import 'package:pocketdesk/features/settings/presentation/providers/ai_settings_notifier.dart';
import 'package:pocketdesk/features/settings/presentation/widgets/ai_settings_widget.dart';

class _TestAISettingsNotifier extends AISettingsNotifier {
  @override
  Future<AISettingsModel> build() async => AISettingsModel();

  @override
  Future<void> updateSettings(AISettingsModel settings) async {
    state = AsyncValue.data(settings);
  }
}

void main() {
  testWidgets('legal documents render in app pages', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TermsAndConditionsPage()),
    );
    expect(find.text('Terms and Conditions'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: PrivacyPolicyPage()),
    );
    expect(find.text('Privacy Policy'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: PocketDeskLicensesPage()),
    );
    expect(find.text('Licenses'), findsOneWidget);
  });

  testWidgets('AI Master Control defaults off and can be enabled',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiSettingsProvider.overrideWith(_TestAISettingsNotifier.new),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: const Scaffold(body: AISettingsWidget()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final control = find.widgetWithText(SwitchListTile, 'AI Master Control');
    expect(tester.widget<SwitchListTile>(control).value, isFalse);
    await tester.tap(control);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(control).value, isTrue);
  });
}

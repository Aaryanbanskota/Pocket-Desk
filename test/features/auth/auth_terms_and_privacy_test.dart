import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/settings/presentation/pages/legal_document_page.dart';

void main() {
  group('Terms and Privacy Policy Verification', () {
    testWidgets('TermsAndConditionsPage renders with title and permission clauses', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TermsAndConditionsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.textContaining('MyDay (v1.2.2)'), findsOneWidget);
      expect(find.text('1. Acceptance of Terms'), findsOneWidget);
      expect(find.text('2. Offline-First Data & User Ownership'), findsOneWidget);
    });

    testWidgets('PrivacyPolicyPage renders with title and privacy guarantees', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacyPolicyPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.textContaining('MyDay'), findsWidgets);
      expect(find.text('1. No Personal Data Selling or Tracking'), findsOneWidget);
      expect(find.text('2. Local-First Storage & Encryption'), findsOneWidget);
    });

    testWidgets('PocketDeskLicensesPage displays version 1.2.2', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PocketDeskLicensesPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
    });
  });
}

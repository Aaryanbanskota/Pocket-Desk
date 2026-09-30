import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/services/app_update_service.dart';

void main() {
  group('AppUpdateInfo & ReleaseChannel Unit Tests', () {
    test('parses version channel suffixes (-t, -rev, -offi) correctly', () {
      final trialUpdate = AppUpdateInfo.fromJson({
        'version': '1.3.0-t',
        'buildNumber': 5,
        'url': 'https://example.com/pocketdesk.apk',
        'required': false,
        'releaseNotes': 'Trial build',
        'newFeatures': ['Feature 1', 'Feature 2'],
      });

      expect(trialUpdate.version, '1.3.0-t');
      expect(trialUpdate.channel, ReleaseChannel.trial);
      expect(trialUpdate.channel.displayName, 'Trial / Experimental');
      expect(trialUpdate.newFeatures.length, 2);

      final revUpdate = AppUpdateInfo.fromJson({
        'version': '1.3.0-rev',
        'buildNumber': 5,
        'url': 'https://example.com/pocketdesk.apk',
        'required': false,
        'releaseNotes': 'Review build',
      });
      expect(revUpdate.channel, ReleaseChannel.review);
      expect(revUpdate.channel.displayName, 'Review / Pre-release');

      final offiUpdate = AppUpdateInfo.fromJson({
        'version': '1.3.0-offi',
        'buildNumber': 5,
        'url': 'https://example.com/pocketdesk.apk',
        'required': false,
        'releaseNotes': 'Official build',
      });
      expect(offiUpdate.channel, ReleaseChannel.official);
      expect(offiUpdate.channel.displayName, 'Official / Stable');
    });

    test('rejects invalid version suffixes or insecure HTTP URLs', () {
      expect(
        () => AppUpdateInfo.fromJson({
          'version': '1.3.0-beta',
          'buildNumber': 4,
          'url': 'https://example.com/pocketdesk.apk',
        }),
        throwsFormatException,
      );

      expect(
        () => AppUpdateInfo.fromJson({
          'version': '1.3.0-offi',
          'buildNumber': 4,
          'url': 'http://insecure.com/pocketdesk.apk',
        }),
        throwsFormatException,
      );
    });
  });

  group('AppUpdateService Update Detection Rules', () {
    test('detects build number increases correctly', () {
      const update = AppUpdateInfo(
        version: '1.2.1-offi',
        buildNumber: 5,
        url: 'https://example.com/pocketdesk.apk',
        required: false,
        releaseNotes: '',
      );

      expect(
        AppUpdateService.isUpdateAvailable(
          currentVersion: '1.2.1-offi',
          currentBuildNumber: 4,
          update: update,
        ),
        isTrue,
      );

      expect(
        AppUpdateService.isUpdateAvailable(
          currentVersion: '1.2.1-offi',
          currentBuildNumber: 5,
          update: update,
        ),
        isFalse,
      );
    });

    test('detects semantic version increases correctly', () {
      const update = AppUpdateInfo(
        version: '1.3.0-offi',
        buildNumber: 4,
        url: 'https://example.com/pocketdesk.apk',
        required: false,
        releaseNotes: '',
      );

      expect(
        AppUpdateService.isUpdateAvailable(
          currentVersion: '1.2.1-offi',
          currentBuildNumber: 4,
          update: update,
        ),
        isTrue,
      );
    });

    test('handles channel promotion (-t -> -rev -> -offi) at same build number', () {
      const offiUpdate = AppUpdateInfo(
        version: '1.2.1-offi',
        buildNumber: 4,
        url: 'https://example.com/pocketdesk.apk',
        required: false,
        releaseNotes: '',
      );

      expect(
        AppUpdateService.isUpdateAvailable(
          currentVersion: '1.2.1-t',
          currentBuildNumber: 4,
          update: offiUpdate,
        ),
        isTrue,
      );

      expect(
        AppUpdateService.isUpdateAvailable(
          currentVersion: '1.2.1-rev',
          currentBuildNumber: 4,
          update: offiUpdate,
        ),
        isTrue,
      );

      const trialUpdate = AppUpdateInfo(
        version: '1.2.1-t',
        buildNumber: 4,
        url: 'https://example.com/pocketdesk.apk',
        required: false,
        releaseNotes: '',
      );

      expect(
        AppUpdateService.isUpdateAvailable(
          currentVersion: '1.2.1-offi',
          currentBuildNumber: 4,
          update: trialUpdate,
        ),
        isFalse,
      );
    });
  });

  group('Widget UI verification for Update & What\'s New Walkthrough', () {
    testWidgets('renders Update Dialog with Channel badges and notes', (tester) async {
      const trialUpdate = AppUpdateInfo(
        version: '1.3.0-t',
        buildNumber: 5,
        url: 'https://example.com/pocketdesk.apk',
        required: false,
        releaseNotes: 'Trial build test notes',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Update Available'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(trialUpdate.channel.displayName),
                        Text(trialUpdate.releaseNotes),
                      ],
                    ),
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('Trial / Experimental'), findsOneWidget);
      expect(find.text('Trial build test notes'), findsOneWidget);
    });

    testWidgets('renders What\'s New Walkthrough dialog with PageView controls', (tester) async {
      const updateInfo = AppUpdateInfo(
        version: '1.2.2-offi',
        buildNumber: 5,
        url: 'https://example.com/pocketdesk.apk',
        required: false,
        releaseNotes: 'Official notes',
        newFeatures: [
          'Feature Page 1: Trial, Review, Official tag support.',
          'Feature Page 2: What\'s new walkthrough setup wizard.',
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppUpdateService.showWhatIsNewWalkthrough(context, updateInfo);
                },
                child: const Text('Show Walkthrough'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Walkthrough'));
      await tester.pumpAndSettle();

      expect(find.text('What\'s New in v1.2.2-offi'), findsOneWidget);
      expect(find.text('Feature Page 1: Trial, Review, Official tag support.'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Feature Page 2: What\'s new walkthrough setup wizard.'), findsOneWidget);
      expect(find.text('Got it!'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      await tester.tap(find.text('Got it!'));
      await tester.pumpAndSettle();

      expect(find.text('What\'s New in v1.2.2-offi'), findsNothing);
    });
  });
}

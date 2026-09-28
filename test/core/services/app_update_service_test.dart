import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/services/app_update_service.dart';

void main() {
  group('AppUpdateInfo', () {
    test('parses a secure APK update manifest', () {
      final update = AppUpdateInfo.fromJson({
        'version': '1.3.0',
        'buildNumber': 4,
        'url': 'https://example.com/pocketdesk.apk',
        'required': false,
        'releaseNotes': 'Bug fixes',
      });

      expect(update.version, '1.3.0');
      expect(update.buildNumber, 4);
      expect(update.url, 'https://example.com/pocketdesk.apk');
    });

    test('rejects an invalid version or insecure download URL', () {
      expect(
        () => AppUpdateInfo.fromJson({
          'version': 'latest',
          'buildNumber': 4,
          'url': 'http://example.com/pocketdesk.apk',
        }),
        throwsFormatException,
      );
    });
  });

  group('AppUpdateService.isUpdateAvailable', () {
    const update = AppUpdateInfo(
      version: '1.3.0',
      buildNumber: 4,
      url: 'https://example.com/pocketdesk.apk',
      required: false,
      releaseNotes: '',
    );

    test('requires both a newer app version and Android build number', () {
      expect(
        AppUpdateService.isUpdateAvailable(
          currentVersion: '1.2.0',
          currentBuildNumber: 3,
          update: update,
        ),
        isTrue,
      );
      expect(
        AppUpdateService.isUpdateAvailable(
          currentVersion: '1.2.0',
          currentBuildNumber: 4,
          update: update,
        ),
        isFalse,
      );
    });

    test('allows a build-only update but rejects version downgrades', () {
      const buildOnlyUpdate = AppUpdateInfo(
        version: '1.2.0',
        buildNumber: 4,
        url: 'https://example.com/pocketdesk.apk',
        required: false,
        releaseNotes: '',
      );
      expect(
        AppUpdateService.isUpdateAvailable(
          currentVersion: '1.2.0',
          currentBuildNumber: 3,
          update: buildOnlyUpdate,
        ),
        isTrue,
      );
      expect(
        AppUpdateService.isUpdateAvailable(
          currentVersion: '1.3.0',
          currentBuildNumber: 3,
          update: buildOnlyUpdate,
        ),
        isFalse,
      );
    });
  });
}

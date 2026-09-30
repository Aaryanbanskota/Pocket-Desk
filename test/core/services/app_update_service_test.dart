import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/services/app_update_service.dart';

void main() {
  group('AppUpdateInfo & ReleaseChannel', () {
    test('parses version channel suffixes correctly', () {
      final trialUpdate = AppUpdateInfo.fromJson({
        'version': '1.3.0-t',
        'buildNumber': 5,
        'url': 'https://example.com/pocketdesk.apk',
        'required': false,
        'releaseNotes': 'Trial build',
        'newFeatures': ['Feature A'],
      });

      expect(trialUpdate.version, '1.3.0-t');
      expect(trialUpdate.channel, ReleaseChannel.trial);
      expect(trialUpdate.newFeatures, ['Feature A']);

      final revUpdate = AppUpdateInfo.fromJson({
        'version': '1.3.0-rev',
        'buildNumber': 5,
        'url': 'https://example.com/pocketdesk.apk',
        'required': false,
        'releaseNotes': 'Review build',
      });
      expect(revUpdate.channel, ReleaseChannel.review);

      final offiUpdate = AppUpdateInfo.fromJson({
        'version': '1.3.0-offi',
        'buildNumber': 5,
        'url': 'https://example.com/pocketdesk.apk',
        'required': false,
        'releaseNotes': 'Official build',
      });
      expect(offiUpdate.channel, ReleaseChannel.official);
    });

    test('rejects invalid suffixes or insecure URLs', () {
      expect(
        () => AppUpdateInfo.fromJson({
          'version': '1.3.0-invalid',
          'buildNumber': 4,
          'url': 'https://example.com/pocketdesk.apk',
        }),
        throwsFormatException,
      );
    });
  });

  group('AppUpdateService.isUpdateAvailable with Channel Precedence', () {
    test('handles channel upgrades when build number is identical', () {
      const offiUpdate = AppUpdateInfo(
        version: '1.2.1-offi',
        buildNumber: 4,
        url: 'https://example.com/pocketdesk.apk',
        required: false,
        releaseNotes: '',
      );

      // Upgrading from trial to official with same build number is allowed
      expect(
        AppUpdateService.isUpdateAvailable(
          currentVersion: '1.2.1-t',
          currentBuildNumber: 4,
          update: offiUpdate,
        ),
        isTrue,
      );

      // Downgrading from official to trial with same build number is rejected
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
}

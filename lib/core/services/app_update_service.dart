import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../logging/app_logger.dart';

enum ReleaseChannel {
  trial('-t', 'Trial / Experimental', 'Experimental release. Contains new features but may have bugs. Proceed with caution.', Colors.orange),
  review('-rev', 'Review / Pre-release', 'Stable preview. Low chance of errors, but some features & designs may change before final release.', Colors.blue),
  official('-offi', 'Official / Stable', 'Official release. Thoroughly tested, highly trusted, and recommended for all users.', Colors.green);

  const ReleaseChannel(this.suffix, this.displayName, this.description, this.color);
  final String suffix;
  final String displayName;
  final String description;
  final Color color;

  static ReleaseChannel fromVersion(String version) {
    if (version.endsWith('-t')) return ReleaseChannel.trial;
    if (version.endsWith('-rev')) return ReleaseChannel.review;
    if (version.endsWith('-offi')) return ReleaseChannel.official;
    return ReleaseChannel.official;
  }
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.url,
    required this.required,
    required this.releaseNotes,
    this.newFeatures = const [],
  });

  final String version;
  final int buildNumber;
  final String url;
  final bool required;
  final String releaseNotes;
  final List<String> newFeatures;

  ReleaseChannel get channel => ReleaseChannel.fromVersion(version);

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final buildNumber = json['buildNumber'];
    final url = json['url'];
    final required = json['required'] ?? false;
    final releaseNotes = json['releaseNotes'] ?? 'New version available.';
    final newFeaturesRaw = json['newFeatures'];
    final downloadUri = url is String ? Uri.tryParse(url) : null;

    final List<String> newFeatures = newFeaturesRaw is List
        ? newFeaturesRaw.map((e) => e.toString()).toList()
        : [];

    if (version is! String ||
        !_isValidVersion(version) ||
        buildNumber is! int ||
        buildNumber <= 0 ||
        downloadUri == null ||
        downloadUri.scheme != 'https' ||
        downloadUri.host.isEmpty ||
        required is! bool ||
        releaseNotes is! String) {
      throw const FormatException('Invalid update manifest.');
    }

    return AppUpdateInfo(
      version: version,
      buildNumber: buildNumber,
      url: downloadUri.toString(),
      required: required,
      releaseNotes: releaseNotes,
      newFeatures: newFeatures,
    );
  }

  static bool _isValidVersion(String version) =>
      RegExp(r'^\d+\.\d+\.\d+(-(t|rev|offi))?$').hasMatch(version);
}

class AppUpdateService {
  static const String updateJsonUrl =
      'https://raw.githubusercontent.com/Aaryanbanskota/Pocket-Desk/main/update.json';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _lastSeenVersionKey = 'last_seen_app_version';

  static Future<void> checkForUpdates(
    BuildContext context, {
    bool showStatus = false,
  }) async {
    // First, check if user just updated and has unseen new features
    await checkAndShowWhatIsNew(context);

    if (!Platform.isAndroid) {
      if (showStatus && context.mounted) {
        _showMessage(context, 'APK updates are available on Android only.');
      }
      return;
    }

    try {
      final response = await http
          .get(Uri.parse(updateJsonUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
            'Update check failed (HTTP ${response.statusCode}).');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid update manifest.');
      }
      final jsonMap = decoded;
      final updateInfo = AppUpdateInfo.fromJson(jsonMap);

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber);
      if (currentBuildNumber == null) {
        throw const FormatException(
            'The installed app has an invalid build number.');
      }

      if (isUpdateAvailable(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        update: updateInfo,
      )) {
        if (context.mounted) {
          _showUpdateDialog(context, updateInfo, currentVersion);
        }
      } else if (showStatus && context.mounted) {
        _showMessage(context, 'PocketDesk is up to date.');
      }
    } catch (e, st) {
      AppLogger.w('Update check failed: $e',
          tag: 'AppUpdateService', error: e, st: st);
      if (showStatus && context.mounted) {
        _showMessage(context, 'Could not check for updates: $e');
      }
    }
  }

  static bool isUpdateAvailable({
    required String currentVersion,
    required int currentBuildNumber,
    required AppUpdateInfo update,
  }) {
    if (update.buildNumber > currentBuildNumber) {
      return true;
    }
    
    final currentSemver = _cleanVersion(currentVersion);
    final updateSemver = _cleanVersion(update.version);
    final current = _versionParts(currentSemver);
    final latest = _versionParts(updateSemver);

    if (current == null || latest == null) {
      return false;
    }

    for (var i = 0; i < current.length; i++) {
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }

    // If semver is identical, check channel precedence: -t < -rev < -offi
    if (update.buildNumber == currentBuildNumber) {
      final currentChannel = ReleaseChannel.fromVersion(currentVersion);
      final updateChannel = update.channel;
      if (updateChannel.index > currentChannel.index) {
        return true;
      }
    }

    return false;
  }

  static String _cleanVersion(String version) {
    final dashIndex = version.indexOf('-');
    if (dashIndex != -1) {
      return version.substring(0, dashIndex);
    }
    return version;
  }

  static List<int>? _versionParts(String version) {
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) return null;
    return version.split('.').map(int.parse).toList();
  }

  static Future<void> checkAndShowWhatIsNew(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final lastSeenVersion = await _storage.read(key: _lastSeenVersionKey);

      if (lastSeenVersion != currentVersion) {
        await _storage.write(key: _lastSeenVersionKey, value: currentVersion);
        if (lastSeenVersion != null && context.mounted) {
          // Fetch update manifest to display new feature onboarding flow
          final response = await http
              .get(Uri.parse(updateJsonUrl))
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == HttpStatus.ok) {
            final decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic>) {
              final updateInfo = AppUpdateInfo.fromJson(decoded);
              if (updateInfo.newFeatures.isNotEmpty && context.mounted) {
                showWhatIsNewWalkthrough(context, updateInfo);
              }
            }
          }
        }
      }
    } catch (_) {
      // Non-blocking onboarding check
    }
  }

  static void showWhatIsNewWalkthrough(
      BuildContext context, AppUpdateInfo updateInfo) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => _WhatIsNewWalkthroughDialog(updateInfo: updateInfo),
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static void _showUpdateDialog(
    BuildContext context,
    AppUpdateInfo updateInfo,
    String currentVersion,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: !updateInfo.required,
      builder: (dialogCtx) => _UpdateDialogWidget(
        updateInfo: updateInfo,
        currentVersion: currentVersion,
      ),
    );
  }
}

class _UpdateDialogWidget extends StatefulWidget {
  const _UpdateDialogWidget({
    required this.updateInfo,
    required this.currentVersion,
  });

  final AppUpdateInfo updateInfo;
  final String currentVersion;

  @override
  State<_UpdateDialogWidget> createState() => _UpdateDialogWidgetState();
}

class _UpdateDialogWidgetState extends State<_UpdateDialogWidget> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _statusText;

  Future<void> _startDownloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _statusText = 'Connecting to server...';
    });

    final client = http.Client();
    File? apkFile;
    try {
      final request = http.Request('GET', Uri.parse(widget.updateInfo.url));
      final response =
          await client.send(request).timeout(const Duration(seconds: 30));

      if (response.statusCode != HttpStatus.ok ||
          response.request?.url.scheme != 'https') {
        throw HttpException(
          'APK download failed (HTTP ${response.statusCode}) or was not secure.',
        );
      }

      final contentLength = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      apkFile = File(
        '${tempDir.path}/pocketdesk-update-${widget.updateInfo.version}.apk',
      );
      final sink = apkFile.openWrite();
      int downloaded = 0;
      try {
        await for (final chunk
            in response.stream.timeout(const Duration(seconds: 30))) {
          sink.add(chunk);
          downloaded += chunk.length;
          if (contentLength > 0 && mounted) {
            setState(() {
              _downloadProgress = downloaded / contentLength;
              _statusText =
                  'Downloading update: ${(downloaded / (1024 * 1024)).toStringAsFixed(1)} / ${(contentLength / (1024 * 1024)).toStringAsFixed(1)} MB';
            });
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      if (downloaded == 0 ||
          (contentLength > 0 && downloaded != contentLength)) {
        throw const HttpException('The downloaded APK is incomplete.');
      }

      await const MethodChannel('pocketdesk/device').invokeMethod<void>(
        'installApk',
        {'path': apkFile.path},
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (apkFile != null && await apkFile.exists()) {
        await apkFile.delete();
      }
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Could not start Android installer: $e';
        });
      }
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final channel = widget.updateInfo.channel;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.system_update_rounded, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Update Available'),
                Text(
                  'v${widget.currentVersion} → v${widget.updateInfo.version}',
                  style: tt.bodySmall?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Channel Badge & Recommendation Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: channel.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: channel.color.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(
                    channel == ReleaseChannel.official
                        ? Icons.verified_rounded
                        : channel == ReleaseChannel.review
                            ? Icons.rate_review_rounded
                            : Icons.bug_report_rounded,
                    size: 16,
                    color: channel.color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      channel.displayName,
                      style: tt.bodySmall?.copyWith(
                        color: channel.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              channel.description,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Text('What\'s New:',
                style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.updateInfo.releaseNotes,
                style: tt.bodySmall?.copyWith(height: 1.4),
              ),
            ),
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null),
              const SizedBox(height: 8),
              if (_statusText != null)
                Text(
                  _statusText!,
                  style: tt.bodySmall?.copyWith(color: cs.primary),
                ),
            ] else if (_statusText != null) ...[
              const SizedBox(height: 12),
              Text(
                _statusText!,
                style: tt.bodySmall?.copyWith(color: cs.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!widget.updateInfo.required && !_isDownloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
        FilledButton.icon(
          onPressed: _isDownloading ? null : _startDownloadAndInstall,
          icon: const Icon(Icons.download_rounded),
          label: Text(_isDownloading ? 'Downloading...' : 'Update Now'),
        ),
      ],
    );
  }
}

class _WhatIsNewWalkthroughDialog extends StatefulWidget {
  const _WhatIsNewWalkthroughDialog({required this.updateInfo});

  final AppUpdateInfo updateInfo;

  @override
  State<_WhatIsNewWalkthroughDialog> createState() =>
      _WhatIsNewWalkthroughDialogState();
}

class _WhatIsNewWalkthroughDialogState
    extends State<_WhatIsNewWalkthroughDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final features = widget.updateInfo.newFeatures;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'What\'s New in v${widget.updateInfo.version}',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Skip'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                itemCount: features.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: cs.primary,
                          radius: 20,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          features[index],
                          textAlign: TextAlign.center,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                features.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? cs.primary
                        : cs.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  OutlinedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                FilledButton(
                  onPressed: () {
                    if (_currentPage < features.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    _currentPage == features.length - 1 ? 'Got it!' : 'Next',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../logging/app_logger.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.url,
    required this.required,
    required this.releaseNotes,
  });

  final String version;
  final int buildNumber;
  final String url;
  final bool required;
  final String releaseNotes;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final buildNumber = json['buildNumber'];
    final url = json['url'];
    final required = json['required'] ?? false;
    final releaseNotes = json['releaseNotes'] ?? 'New version available.';
    final downloadUri = url is String ? Uri.tryParse(url) : null;

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
    );
  }

  static bool _isValidVersion(String version) =>
      RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version);
}

class AppUpdateService {
  static const String updateJsonUrl =
      'https://raw.githubusercontent.com/Aaryanbanskota/Pocket-Desk/main/update.json';

  static Future<void> checkForUpdates(
    BuildContext context, {
    bool showStatus = false,
  }) async {
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
    final current = _versionParts(currentVersion);
    final latest = _versionParts(update.version);
    if (current == null ||
        latest == null ||
        update.buildNumber <= currentBuildNumber) {
      return false;
    }

    for (var i = 0; i < current.length; i++) {
      if (latest[i] != current[i]) return latest[i] > current[i];
    }
    return true;
  }

  static List<int>? _versionParts(String version) {
    if (!AppUpdateInfo._isValidVersion(version)) return null;
    return version.split('.').map(int.parse).toList();
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

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final String version;
  final String url;
  final bool required;
  final String releaseNotes;

  AppUpdateInfo({
    required this.version,
    required this.url,
    required this.required,
    required this.releaseNotes,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
        version: json['version'] as String? ?? '1.0.0',
        url: json['url'] as String? ?? '',
        required: json['required'] as bool? ?? false,
        releaseNotes: json['releaseNotes'] as String? ?? 'New version available.',
      );
}

class AppUpdateService {
  static const String updateJsonUrl =
      'https://raw.githubusercontent.com/Aaryanbanskota/Pocket-Desk/main/update.json';

  /// Performs background check for app update.
  /// Skips silently if offline or on error so app functionality is never affected.
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(updateJsonUrl)).timeout(
        const Duration(seconds: 4),
        onTimeout: () => http.Response('', 408),
      );

      if (response.statusCode != 200 || response.body.isEmpty) return;

      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      final updateInfo = AppUpdateInfo.fromJson(jsonMap);

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isNewerVersion(currentVersion, updateInfo.version)) {
        if (context.mounted) {
          _showUpdateDialog(context, updateInfo, currentVersion);
        }
      }
    } catch (_) {
      // Offline-first: ignore errors silently
    }
  }

  /// Version comparison helper (semver compliant e.g. 1.2.0 > 1.1.0)
  static bool _isNewerVersion(String current, String latest) {
    try {
      final cParts = current.split('+')[0].split('.').map(int.parse).toList();
      final lParts = latest.split('+')[0].split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < cParts.length ? cParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (l > c) return true;
        if (c > l) return false;
      }
    } catch (_) {}
    return false;
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

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.updateInfo.url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Download failed (HTTP ${response.statusCode})';
        });
        return;
      }

      final contentLength = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/pocketdesk-update-${widget.updateInfo.version}.apk');
      final sink = apkFile.openWrite();

      int downloaded = 0;
      response.stream.listen(
        (chunk) {
          sink.add(chunk);
          downloaded += chunk.length;
          if (contentLength > 0 && mounted) {
            setState(() {
              _downloadProgress = downloaded / contentLength;
              _statusText =
                  'Downloading update: ${(downloaded / (1024 * 1024)).toStringAsFixed(1)} / ${(contentLength / (1024 * 1024)).toStringAsFixed(1)} MB';
            });
          }
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          client.close();

          if (mounted) {
            setState(() {
              _isDownloading = false;
              _statusText = 'Opening Android installer...';
            });

            final fileUri = Uri.file(apkFile.path);
            if (await canLaunchUrl(fileUri)) {
              await launchUrl(fileUri, mode: LaunchMode.externalApplication);
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Update downloaded. Please install the APK file from downloads.')),
              );
            }
          }
        },
        onError: (e) async {
          await sink.close();
          client.close();
          if (mounted) {
            setState(() {
              _isDownloading = false;
              _statusText = 'Download interrupted';
            });
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Download failed';
        });
      }
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
                  style: tt.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
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
            Text('What\'s New:', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
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
              LinearProgressIndicator(value: _downloadProgress > 0 ? _downloadProgress : null),
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

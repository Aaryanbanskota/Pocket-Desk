import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../dashboard/presentation/widgets/app_hamburger_drawer.dart';

class FileSharePage extends ConsumerStatefulWidget {
  const FileSharePage({super.key});

  @override
  ConsumerState<FileSharePage> createState() => _FileSharePageState();
}

class _FileSharePageState extends ConsumerState<FileSharePage> {
  final List<PlatformFile> _selectedFiles = [];
  HttpServer? _server;
  String? _localIp;
  static const int _port = 8080;
  String _accessPin = '1234';

  @override
  void initState() {
    super.initState();
    _generatePin();
    _startLocalNetworkServer();
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  void _generatePin() {
    _accessPin = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
  }

  Future<void> _startLocalNetworkServer() async {
    try {
      // Find local WiFi IP address
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      String? ip;
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            ip = addr.address;
            break;
          }
        }
        if (ip != null) break;
      }
      _localIp = ip ?? '127.0.0.1';

      // Bind HTTP server
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);

      _server?.listen((HttpRequest request) async {
        final uri = request.uri;
        final response = request.response;

        // CORS headers
        response.headers.set('Access-Control-Allow-Origin', '*');

        if (uri.path == '/') {
          // Serve Web Portal HTML
          response.headers.contentType = ContentType.html;
          response.write(_buildWebPortalHtml());
          await response.close();
        } else if (uri.path == '/api/verify') {
          final queryPin = uri.queryParameters['pin'];
          response.headers.contentType = ContentType.json;
          if (queryPin == _accessPin) {
            final filesJson = _selectedFiles.map((f) => {
              'name': f.name,
              'size': f.size,
              'path': f.path,
            }).toList();
            response.write(jsonEncode({'success': true, 'files': filesJson}));
          } else {
            response.write(jsonEncode({'success': false, 'error': 'Invalid PIN'}));
          }
          await response.close();
        } else if (uri.path == '/download') {
          final queryPin = uri.queryParameters['pin'];
          final fileName = uri.queryParameters['file'];
          if (queryPin == _accessPin && fileName != null) {
            final file = _selectedFiles.firstWhere(
              (f) => f.name == fileName,
              orElse: () => PlatformFile(name: '', size: 0),
            );
            if (file.path != null && File(file.path!).existsSync()) {
              final realFile = File(file.path!);
              response.headers.contentType = ContentType.binary;
              response.headers.set('Content-Disposition', 'attachment; filename="${file.name}"');
              await realFile.openRead().pipe(response);
              return;
            }
          }
          response.statusCode = HttpStatus.unauthorized;
          response.write('Unauthorized or File not found');
          await response.close();
        } else {
          response.statusCode = HttpStatus.notFound;
          response.write('404 Not Found');
          await response.close();
        }
      });
    } catch (_) {
      // Server initialization error fallback
    }
  }

  String _buildWebPortalHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PocketDesk Wi-Fi File Transfer</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 20px; display: flex; justify-content: center; }
    .card { background: #1e293b; border: 1px solid #334155; border-radius: 16px; padding: 24px; max-width: 480px; width: 100%; box-shadow: 0 10px 25px rgba(0,0,0,0.3); }
    h2 { margin-top: 0; color: #38bdf8; }
    input { width: 100%; padding: 12px; font-size: 18px; border-radius: 8px; border: 1px solid #475569; background: #0f172a; color: #fff; text-align: center; letter-spacing: 4px; box-sizing: border-box; }
    button { width: 100%; margin-top: 12px; padding: 12px; font-size: 16px; font-weight: bold; background: #0284c7; color: #fff; border: none; border-radius: 8px; cursor: pointer; }
    button:hover { background: #0369a1; }
    .file-item { background: #334155; border-radius: 8px; padding: 12px; margin-top: 10px; display: flex; justify-content: space-between; align-items: center; }
    .dl-btn { width: auto; margin-top: 0; padding: 6px 12px; font-size: 14px; background: #10b981; }
  </style>
</head>
<body>
  <div class="card">
    <h2>🚀 PocketDesk File Portal</h2>
    <p>Enter the 4-digit PIN displayed on PocketDesk app to view & download files over local Wi-Fi.</p>
    <div id="login-sec">
      <input type="password" id="pin" maxlength="4" placeholder="••••">
      <button onclick="unlock()">Access Files</button>
      <p id="err" style="color:#ef4444; display:none;"></p>
    </div>
    <div id="files-sec" style="display:none;">
      <h3>Shared Files</h3>
      <div id="file-list"></div>
    </div>
  </div>
  <script>
    async function unlock() {
      const pin = document.getElementById('pin').value;
      const res = await fetch('/api/verify?pin=' + pin);
      const data = await res.json();
      if (data.success) {
        document.getElementById('login-sec').style.display = 'none';
        document.getElementById('files-sec').style.display = 'block';
        const list = document.getElementById('file-list');
        list.innerHTML = '';
        if (data.files.length === 0) {
          list.innerHTML = '<p style="color:#94a3b8;">No files currently shared.</p>';
        } else {
          data.files.forEach(f => {
            const sizeMb = (f.size / (1024*1024)).toFixed(2);
            list.innerHTML += `<div class="file-item"><div><strong>\${f.name}</strong><br><small style="color:#94a3b8;">\${sizeMb} MB</small></div><a href="/download?pin=\${pin}&file=\${encodeURIComponent(f.name)}"><button class="dl-btn">Download</button></a></div>`;
          });
        }
      } else {
        const err = document.getElementById('err');
        err.innerText = data.error || 'Invalid PIN';
        err.style.display = 'block';
      }
    }
  </script>
</body>
</html>
''';
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  String get _portalUrl => 'http://${_localIp ?? '127.0.0.1'}:$_port';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      drawer: const AppHamburgerDrawer(),
      appBar: AppBar(
        title: const Text('Network File Share'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _generatePin());
            },
            tooltip: 'New PIN',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Network Access Portal Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primaryContainer, cs.surfaceContainerHighest],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_tethering_rounded, color: cs.primary, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Direct Browser Share',
                        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No app needed! Any device on your local Wi-Fi can open this link in a browser, enter the PIN, and download files instantly.',
                    textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  // QR Code & Link
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: _portalUrl,
                          version: QrVersions.auto,
                          size: 110.0,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'URL Link:',
                              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: _portalUrl));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Portal URL copied!')),
                                );
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _portalUrl,
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.copy_rounded, size: 16, color: cs.primary),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Access PIN:',
                              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _accessPin,
                                style: TextStyle(
                                  color: cs.onPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Files Header & Add Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Files to Share (${_selectedFiles.length})',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                FilledButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Files'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Selected Files List
            if (_selectedFiles.isEmpty)
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.drive_folder_upload_rounded, size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text(
                        'No files added yet. Tap "Add Files" above.',
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) {
                  final file = _selectedFiles[index];
                  final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(2);
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.insert_drive_file_rounded, color: cs.primary, size: 20),
                      ),
                      title: Text(file.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('$sizeMb MB'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          setState(() {
                            _selectedFiles.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

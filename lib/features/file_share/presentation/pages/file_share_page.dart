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
  String? _serverError;
  bool _serverReady = false;
  bool _pickingFiles = false;
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
    _accessPin =
        (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
  }

  Future<void> _startLocalNetworkServer() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      final candidates = interfaces.where((interface) {
        final name = interface.name.toLowerCase();
        return !name.contains('docker') &&
            !name.contains('veth') &&
            !name.contains('bridge') &&
            !name.contains('virbr') &&
            !name.contains('tun') &&
            !name.contains('tap');
      }).toList()
        ..sort((a, b) {
          int priority(String name) {
            final value = name.toLowerCase();
            if (value.startsWith('wl') || value.contains('wifi')) return 0;
            if (value.startsWith('en') || value.startsWith('eth')) return 1;
            return 2;
          }

          return priority(a.name).compareTo(priority(b.name));
        });
      for (final interface in candidates) {
        for (final address in interface.addresses) {
          if (_isPrivateIpv4(address.address)) {
            _localIp = address.address;
            break;
          }
        }
        if (_localIp != null) break;
      }
      if (_localIp == null) {
        throw const SocketException(
          'Connect this computer to Wi-Fi or a local network first.',
        );
      }

      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _server!.listen((HttpRequest request) async {
        final uri = request.uri;
        final response = request.response;

        response.headers.set('Access-Control-Allow-Origin', '*');

        if (uri.path == '/') {
          response.headers.contentType = ContentType.html;
          response.write(_buildWebPortalHtml());
          await response.close();
        } else if (uri.path == '/api/verify' || uri.path == '/api/files') {
          final queryPin = uri.queryParameters['pin'];
          response.headers.contentType = ContentType.json;
          if (queryPin == _accessPin) {
            final filesJson = _selectedFiles
                .map((f) => {'name': f.name, 'size': f.size})
                .toList();
            response.write(jsonEncode({'success': true, 'files': filesJson}));
          } else {
            response
                .write(jsonEncode({'success': false, 'error': 'Invalid PIN'}));
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
              response.headers.contentLength = await realFile.length();
              final safeName = file.name.replaceAll(RegExp(r'["\r\n]'), '_');
              response.headers.set(
                'Content-Disposition',
                "attachment; filename=\"$safeName\"; filename*=UTF-8''${Uri.encodeComponent(file.name)}",
              );
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
      if (mounted) setState(() => _serverReady = true);
    } catch (error, stackTrace) {
      debugPrint('Could not start file share server: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _serverError = error.toString();
          _serverReady = false;
        });
      }
    }
  }

  bool _isPrivateIpv4(String address) {
    final parts = address.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) return false;
    final a = parts[0]!;
    final b = parts[1]!;
    return a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168);
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
    button { width: 100%; margin-top: 12px; padding: 12px; font-size: 16px; font-weight: bold; background: #0284c7; color: #fff; border: none; border-radius: 10px; cursor: pointer; transition: background .2s, transform .2s; }
    button:hover { background: #0369a1; }
    button:disabled { opacity: .65; cursor: wait; }
    .file-item { background: #26364b; border: 1px solid #3b4c63; border-radius: 12px; padding: 14px; margin-top: 10px; display: flex; gap: 12px; justify-content: space-between; align-items: center; }
    .file-item strong { overflow-wrap: anywhere; }
    .file-item > div { min-width: 0; flex: 1; }
    .dl-btn { width: auto; min-width: 100px; margin-top: 0; padding: 9px 14px; font-size: 14px; background: #059669; }
    progress { width: 100%; height: 8px; margin-top: 8px; accent-color: #38bdf8; }
    #file-count { color: #94a3b8; }
    @media (max-width: 420px) { body { padding: 12px; } .card { padding: 18px; } .file-item { align-items: flex-start; flex-direction: column; } .dl-btn { width: 100%; } }
  </style>
</head>
<body>
  <div class="card">
    <h2>🚀 PocketDesk File Portal</h2>
    <p>Enter the 4-digit PIN shown in PocketDesk to view and download files on the same local network.</p>
    <div id="login-sec">
      <input type="password" id="pin" maxlength="4" inputmode="numeric" placeholder="••••">
      <button onclick="unlock()">Access Files</button>
      <p id="err" style="color:#ef4444; display:none;"></p>
    </div>
    <div id="files-sec" style="display:none;">
      <h3>Shared Files <small id="file-count"></small></h3>
      <p id="empty" style="color:#94a3b8; display:none;">No files yet. This list updates automatically when files are added in PocketDesk.</p>
      <div id="file-list"></div>
    </div>
  </div>
  <script>
    let activePin = '';
    function renderFiles(files) {
      const list = document.getElementById('file-list');
      list.replaceChildren();
      document.getElementById('file-count').textContent = '(' + files.length + ')';
      document.getElementById('empty').style.display = files.length ? 'none' : 'block';
      files.forEach(f => {
        const item = document.createElement('div');
        item.className = 'file-item';
        const info = document.createElement('div');
        const name = document.createElement('strong');
        name.textContent = f.name;
        const size = document.createElement('small');
        size.style.color = '#94a3b8';
        size.textContent = (f.size / (1024*1024)).toFixed(2) + ' MB';
        const progress = document.createElement('progress');
        progress.max = 100;
        progress.value = 0;
        progress.style.display = 'none';
        const status = document.createElement('small');
        status.style.display = 'none';
        info.append(name, document.createElement('br'), size, document.createElement('br'), progress, status);
        const button = document.createElement('button');
        button.className = 'dl-btn';
        button.textContent = 'Download';
        button.onclick = () => downloadFile(f.name, button, progress, status);
        item.append(info, button);
        list.append(item);
      });
    }
    async function refreshFiles() {
      try {
        const res = await fetch('/api/files?pin=' + encodeURIComponent(activePin));
        const data = await res.json();
        if (data.success) renderFiles(data.files);
      } catch (_) {}
    }
    async function downloadFile(name, button, progress, status) {
      button.disabled = true;
      button.textContent = 'Downloading…';
      progress.style.display = 'block';
      status.style.display = 'block';
      status.textContent = 'Starting…';
      try {
        const res = await fetch('/download?pin=' + encodeURIComponent(activePin) + '&file=' + encodeURIComponent(name));
        if (!res.ok) throw new Error('Download failed (' + res.status + ')');
        const total = Number(res.headers.get('content-length')) || 0;
        const reader = res.body.getReader();
        const chunks = [];
        let received = 0;
        while (true) {
          const part = await reader.read();
          if (part.done) break;
          chunks.push(part.value);
          received += part.value.length;
          if (total) {
            progress.value = received / total * 100;
            status.textContent = Math.round(progress.value) + '% · ' + (received / 1048576).toFixed(1) + ' / ' + (total / 1048576).toFixed(1) + ' MB';
          } else {
            status.textContent = (received / 1048576).toFixed(1) + ' MB downloaded';
          }
        }
        const blob = new Blob(chunks, {type: 'application/octet-stream'});
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = name;
        link.click();
        URL.revokeObjectURL(link.href);
        progress.value = 100;
        status.textContent = 'Download complete';
      } catch (error) {
        status.textContent = error.message;
      } finally {
        button.disabled = false;
        button.textContent = 'Download';
      }
    }
    async function unlock() {
      const pin = document.getElementById('pin').value;
      const res = await fetch('/api/verify?pin=' + encodeURIComponent(pin));
      const data = await res.json();
      if (data.success) {
        activePin = pin;
        document.getElementById('login-sec').style.display = 'none';
        document.getElementById('files-sec').style.display = 'block';
        renderFiles(data.files);
        setInterval(refreshFiles, 1500);
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
    if (_pickingFiles) return;
    setState(() => _pickingFiles = true);
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && mounted && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (!_selectedFiles.any(
              (selected) =>
                  file.path != null &&
                  selected.path != null &&
                  selected.path == file.path,
            )) {
              _selectedFiles.add(file);
            }
          }
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add files: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingFiles = false);
    }
  }

  String get _portalUrl => _localIp == null ? '' : 'http://$_localIp:$_port';

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
                      Icon(Icons.wifi_tethering_rounded,
                          color: cs.primary, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Direct Browser Share',
                        style: tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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
                  if (_serverError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        'Could not start sharing: $_serverError',
                        style: tt.bodySmall?.copyWith(color: cs.error),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        _serverReady
                            ? 'Open this address on a device connected to the same Wi-Fi. Keep this page open while sharing. If it cannot connect, allow TCP port $_port through the computer firewall.'
                            : 'Starting local share server…',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _serverReady
                            ? QrImageView(
                                data: _portalUrl,
                                version: QrVersions.auto,
                                size: 110.0,
                              )
                            : const SizedBox(
                                width: 110,
                                height: 110,
                                child: Center(
                                  child: Icon(Icons.wifi_off_rounded),
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'URL Link:',
                              style: tt.labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            InkWell(
                              onTap: () {
                                if (!_serverReady) return;
                                Clipboard.setData(
                                    ClipboardData(text: _portalUrl));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Portal URL copied!')),
                                );
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _serverReady
                                          ? _portalUrl
                                          : 'Server unavailable',
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.copy_rounded,
                                      size: 16, color: cs.primary),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Access PIN:',
                              style: tt.labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
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
              children: [
                IconButton.filledTonal(
                  onPressed: _pickingFiles ? null : _pickFiles,
                  tooltip: 'Add files',
                  icon: _pickingFiles
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    minimumSize: const Size(48, 48),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Files to Share',
                    style:
                        tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${_selectedFiles.length}',
                  style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
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
                  border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.drive_folder_upload_rounded,
                          size: 40,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to choose files. They will appear in the browser automatically.',
                        style:
                            tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.insert_drive_file_rounded,
                            color: cs.primary, size: 20),
                      ),
                      title: Text(file.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
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

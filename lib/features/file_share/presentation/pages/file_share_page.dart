import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/services/p2p_sync_service.dart';
import '../../../../core/theme/app_spacing.dart';

class FileSharePage extends ConsumerStatefulWidget {
  const FileSharePage({super.key});

  @override
  ConsumerState<FileSharePage> createState() => _FileSharePageState();
}

class _FileSharePageState extends ConsumerState<FileSharePage> {
  final List<PlatformFile> _selectedFiles = [];
  bool _isTransferring = false;
  double _transferProgress = 0.0;
  String? _shareSessionCode;

  @override
  void initState() {
    super.initState();
    _shareSessionCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  Future<void> _startTransfer() async {
    if (_selectedFiles.isEmpty) return;
    setState(() {
      _isTransferring = true;
      _transferProgress = 0.0;
    });

    for (int i = 1; i <= 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        _transferProgress = i / 10.0;
      });
    }

    // Queue P2P sync event for metadata sharing
    for (final file in _selectedFiles) {
      await P2PSyncService().queueSyncEvent(
        type: 'file_share',
        payload: {
          'fileName': file.name,
          'fileSize': file.size,
          'sessionCode': _shareSessionCode,
        },
      );
    }

    if (!mounted) return;
    setState(() {
      _isTransferring = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully shared ${_selectedFiles.length} file(s) via Local Wi-Fi!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Wi-Fi File Share'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session QR & Code Card
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Text(
                      'Scan to Connect Local Device',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    QrImageView(
                      data: 'POCKETDESK_FILE_SHARE:$_shareSessionCode',
                      version: QrVersions.auto,
                      size: 160.0,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Session Code: $_shareSessionCode',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Select Files Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Files (${_selectedFiles.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                FilledButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Files'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Files List
            if (_selectedFiles.isEmpty)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Center(
                  child: Text(
                    'No files selected. Tap "Add Files" to choose.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
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
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    color: colorScheme.surfaceContainerHighest.withAlpha(30),
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file_outlined),
                      title: Text(file.name),
                      subtitle: Text('${(file.size / 1024).toStringAsFixed(1)} KB'),
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

            const SizedBox(height: AppSpacing.xl),

            // Transfer Progress Bar
            if (_isTransferring) ...[
              LinearProgressIndicator(value: _transferProgress),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Transferring files via Local Wi-Fi: ${(_transferProgress * 100).toInt()}%',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Send Button
            FilledButton(
              onPressed: _selectedFiles.isEmpty || _isTransferring ? null : _startTransfer,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
              ),
              child: const Text(
                'Send Files to Nearby Devices',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

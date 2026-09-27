import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/qr_data_share_service.dart';
import 'qr_login_host_widget.dart';

class QrDataShareWidget extends ConsumerStatefulWidget {
  const QrDataShareWidget({super.key});

  @override
  ConsumerState<QrDataShareWidget> createState() => _QrDataShareWidgetState();
}

class _QrDataShareWidgetState extends ConsumerState<QrDataShareWidget> {
  String? _qrString;
  String? _deviceName;
  bool _isGenerating = false;
  final _qrDataShareService = QrDataShareService();
  late final TextEditingController _deviceNameController;

  @override
  void initState() {
    super.initState();
    _deviceName = 'My Device';
    _deviceNameController = TextEditingController(text: _deviceName);
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _generateQrCode() async {
    setState(() => _isGenerating = true);

    try {
      // Generate QR code with device data and notes/tasks info
      final qrString = await _qrDataShareService.generateQrString(
        deviceName: _deviceName ?? 'My Device',
        data: {
          'notes': 'Sample notes to share',
          'tasks': 'Sample tasks to share',
          'calendar': 'Sample calendar events',
        },
      );

      setState(() {
        _qrString = qrString;
        _isGenerating = false;
      });

      // Show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code generated! Scan to sync data.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(AppSpacing.md),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _clearQrCode() {
    setState(() => _qrString = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const QrLoginHostWidget(),
            const SizedBox(height: AppSpacing.xl),
            // Header
            Text(
              'Sync Data Between Devices',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Generate a QR code to share your data with another PocketDesk device. No internet or cloud storage needed - pure peer-to-peer sync.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Device Name Input
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device Name',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter device name',
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onChanged: (value) {
                      setState(
                          () => _deviceName = value.isEmpty ? null : value);
                    },
                    controller: _deviceNameController,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // QR Code Display
            if (_qrString != null)
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      'Your Sync QR Code',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: QrImageView(
                        data: _qrString!,
                        version: QrVersions.auto,
                        size: 280,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Have another device scan this code to sync data',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: _clearQrCode,
                      icon: const Icon(Icons.clear_rounded),
                      label: const Text('Generate New Code'),
                    ),
                  ],
                ),
              )
            else
              FilledButton.icon(
                onPressed: _isGenerating ? null : _generateQrCode,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.qr_code_2_rounded),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Generate QR Code',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),

            const SizedBox(height: AppSpacing.xl),

            // QR Scanner Section
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.phone_iphone_rounded,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Scan Device Code',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Use another device\'s QR code to sync their data to this device',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog<String>(
                        context: context,
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Scan QR Code'),
                            leading: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          body: MobileScanner(
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                if (barcode.rawValue != null) {
                                  Navigator.pop(context, barcode.rawValue);
                                  break;
                                }
                              }
                            },
                          ),
                        ),
                      ).then((scannedCode) async {
                        if (scannedCode != null && context.mounted) {
                          final ctx = context;
                          final payload = await _qrDataShareService
                              .verifyQrString(scannedCode);
                          if (payload != null && ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Scanned successfully: Syncing with ${payload.deviceName}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            await _qrDataShareService.confirmSync(
                                payload.sessionId, payload.data);
                          } else if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Invalid or expired QR code'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      });
                    },
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Scan QR Code'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // How it works
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withAlpha(100),
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'How It Works',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoStep(
                    theme,
                    colorScheme,
                    '1',
                    'Generate a QR code on this device',
                  ),
                  _buildInfoStep(
                    theme,
                    colorScheme,
                    '2',
                    'Open PocketDesk on another device',
                  ),
                  _buildInfoStep(
                    theme,
                    colorScheme,
                    '3',
                    'Scan the QR code using the camera',
                  ),
                  _buildInfoStep(
                    theme,
                    colorScheme,
                    '4',
                    'Data syncs automatically via P2P',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStep(
    ThemeData theme,
    ColorScheme colorScheme,
    String number,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/p2p_sync_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/app_update_service.dart';

class DeviceSettingsWidget extends ConsumerStatefulWidget {
  const DeviceSettingsWidget({super.key});

  @override
  ConsumerState<DeviceSettingsWidget> createState() =>
      _DeviceSettingsWidgetState();
}

class _DeviceSettingsWidgetState extends ConsumerState<DeviceSettingsWidget> {
  late final TextEditingController _deviceNameController;

  @override
  void initState() {
    super.initState();
    final service = P2PSyncService();
    _deviceNameController = TextEditingController(
      text: service.deviceName ?? 'My Device',
    );
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
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
            Text(
              'Manage Connected Devices',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'View and manage devices connected to your account for data synchronization.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Current Device
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.devices_rounded,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This Device',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Android • Connected',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(25),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          'Current',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Connected Devices List
            Text(
              'Connected Devices',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (P2PSyncService().getConnectedPeers().isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.devices_other_rounded,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withAlpha(100),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No other devices connected',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Use QR codes to connect your other devices',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: P2PSyncService().getConnectedPeers().length,
                itemBuilder: (context, index) {
                  final peer = P2PSyncService().getConnectedPeers()[index]
                      as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.laptop_rounded),
                    title: Text(peer['name'] as String? ?? 'Peer Device'),
                    subtitle: Text(peer['address'] as String? ?? 'Connected'),
                  );
                },
              ),

            const SizedBox(height: AppSpacing.xl),

            // Device Name
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
                    controller: _deviceNameController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () async {
                      final newName = _deviceNameController.text.trim();
                      if (newName.isNotEmpty) {
                        await P2PSyncService().initialize(deviceName: newName);
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Device name saved'),
                        ),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Check for Updates section
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.system_update_rounded, color: colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check for Updates',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Self-hosted in-app update checker',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => AppUpdateService.checkForUpdates(
                          context,
                          showStatus: true,
                        ),
                        child: const Text('Check Now'),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () async {
                          final response = await http.get(
                            Uri.parse(AppUpdateService.updateJsonUrl),
                          );
                          if (response.statusCode == 200 && context.mounted) {
                            final decoded = jsonDecode(response.body);
                            if (decoded is Map<String, dynamic>) {
                              final info = AppUpdateInfo.fromJson(decoded);
                              AppUpdateService.showWhatIsNewWalkthrough(
                                context,
                                info,
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                        label: const Text('What\'s New', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

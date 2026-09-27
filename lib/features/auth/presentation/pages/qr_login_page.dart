import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/isar_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/p2p_sync_service.dart';
import '../../data/services/qr_login_service.dart';
import '../providers/auth_notifier.dart';

class QrLoginPage extends ConsumerStatefulWidget {
  const QrLoginPage({super.key});

  @override
  ConsumerState<QrLoginPage> createState() => _QrLoginPageState();
}

class _QrLoginPageState extends ConsumerState<QrLoginPage> {
  final _deviceId = const Uuid().v4();
  final _scannerController =
      MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  final _deviceNameController = TextEditingController(
    text: P2PSyncService().deviceName ?? 'New device',
  );
  final _pinController = TextEditingController();
  final _qrLoginService = QrLoginService();
  QrLoginQr? _qr;
  bool _handlingScan = false;
  bool _working = false;
  bool _importing = false;
  bool _cancelled = false;
  String? _error;
  String _status = '';

  @override
  void dispose() {
    _scannerController.dispose();
    _deviceNameController.dispose();
    _pinController.dispose();
    unawaited(_qrLoginService.dispose());
    super.dispose();
  }

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_handlingScan) return;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (value == null) return;

    _handlingScan = true;
    final qr = QrLoginQr.parse(value);
    if (qr == null) {
      _handlingScan = false;
      setState(() => _error = 'This is not a valid PocketDesk login QR code.');
      return;
    }
    await _scannerController.stop();
    if (!mounted) return;
    setState(() {
      _qr = qr;
      _error = null;
    });
  }

  Future<void> _beginLogin() async {
    final qr = _qr;
    final name = _deviceNameController.text.trim();
    final pin = _pinController.text.trim();
    if (qr == null ||
        name.isEmpty ||
        name.length > 32 ||
        !RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = 'Enter a device name and the four-digit PIN.');
      return;
    }

    setState(() {
      _working = true;
      _error = null;
      _status = 'Checking this device…';
    });
    try {
      final isar = await ref.read(isarProvider.future);
      if (!await QrLoginService.isDatabaseEmpty(isar)) {
        throw const QrLoginException(
          'This device already has local data. QR login is only available on an empty device.',
        );
      }

      await _qrLoginService.sendLoginRequest(
        qr: qr,
        deviceName: name,
        deviceId: _deviceId,
        pin: pin,
      );
      setState(() => _status = 'Waiting for approval on ${qr.deviceName}…');

      final deadline = DateTime.now().add(const Duration(minutes: 5));
      while (mounted && !_cancelled && DateTime.now().isBefore(deadline)) {
        final response = await _qrLoginService.poll(qr);
        final status = response['status'];
        if (status == 'rejected') {
          throw const QrLoginException(
              'The signed-in user declined this request.');
        }
        if (status == 'failed') {
          throw QrLoginException(
            response['error'] as String? ??
                'The signed-in device could not prepare the account transfer.',
          );
        }
        if (status == 'cancelled' ||
            status == 'expired' ||
            status == 'blocked') {
          throw const QrLoginException(
              'The login transfer was cancelled or expired.');
        }
        if (status == 'approved') {
          final transferResponse = await _qrLoginService.downloadTransfer(qr);
          if (!mounted || _cancelled) return;
          final transfer = transferResponse['transfer'];
          if (transfer is! Map<String, dynamic>) {
            throw const QrLoginException(
                'The signed-in device sent invalid transfer data.');
          }
          setState(() {
            _importing = true;
            _status = 'Applying account data securely…';
          });
          final user = await _qrLoginService.importAccount(
            isar,
            transfer,
            deviceId: _deviceId,
          );
          await P2PSyncService().initialize(
            deviceId: user.deviceId,
            deviceName: name,
          );
          await ref
              .read(authNotifierProvider.notifier)
              .loginWithTransferredUser(user);
          await _qrLoginService.complete(qr);
          if (mounted) context.go(AppRoutes.dashboard);
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
      if (!_cancelled) {
        throw const QrLoginException('The login request timed out.');
      }
    } catch (e) {
      if (mounted && !_cancelled) {
        setState(() {
          _error = e.toString();
          _status = '';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
          _importing = false;
        });
      }
    }
  }

  Future<void> _cancel() async {
    _cancelled = true;
    final qr = _qr;
    if (qr != null) unawaited(_qrLoginService.cancelGuest(qr));
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with QR'),
        leading: IconButton(
          tooltip: 'Cancel QR login',
          onPressed: _importing
              ? null
              : _working
                  ? _cancel
                  : () => context.go(AppRoutes.login),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_qr == null) ...[
                  Text(
                    'Scan the QR shown on your signed-in device',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: MobileScanner(
                        controller: _scannerController,
                        onDetect: _handleScan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Both devices must be connected to the same Wi-Fi network.',
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    'Connect to ${_qr!.deviceName}',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter a temporary name so the account owner can identify this device, then enter the four-digit PIN shown beside the QR.',
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _deviceNameController,
                    maxLength: 32,
                    enabled: !_working,
                    decoration: const InputDecoration(
                      labelText: 'Temporary device name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    obscureText: true,
                    enabled: !_working,
                    decoration: const InputDecoration(
                      labelText: 'Four-digit PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _working ? null : _beginLogin,
                    icon: _working
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_user_outlined),
                    label: Text(_working ? 'Waiting…' : 'Request sign-in'),
                  ),
                  if (_working) ...[
                    const SizedBox(height: 12),
                    Text(_status, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _importing ? null : _cancel,
                      child: Text(
                        _importing ? 'Finishing sign-in…' : 'Cancel transfer',
                      ),
                    ),
                  ],
                  if (!_working)
                    TextButton(
                      onPressed: () async {
                        await _scannerController.start();
                        setState(() {
                          _qr = null;
                          _handlingScan = false;
                          _error = null;
                        });
                      },
                      child: const Text('Scan a different QR'),
                    ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

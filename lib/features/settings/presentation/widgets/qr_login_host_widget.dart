import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/database/isar_provider.dart';
import '../../../../core/services/p2p_sync_service.dart';
import '../../../auth/data/services/qr_login_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class QrLoginHostWidget extends ConsumerStatefulWidget {
  const QrLoginHostWidget({super.key});

  @override
  ConsumerState<QrLoginHostWidget> createState() => _QrLoginHostWidgetState();
}

class _QrLoginHostWidgetState extends ConsumerState<QrLoginHostWidget> {
  bool _starting = false;

  Future<void> _startLogin() async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) {
      _showMessage('Sign in before generating a QR login code.');
      return;
    }

    setState(() => _starting = true);
    final service = QrLoginService();
    try {
      final isar = await ref.read(isarProvider.future);
      final qr = await service.startHost(
        isar: isar,
        user: auth.user,
        deviceName: P2PSyncService().deviceName ?? 'This device',
      );
      if (!mounted) {
        await service.dispose();
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _QrLoginHostDialog(service: service, qr: qr),
      );
    } catch (e) {
      if (mounted) _showMessage(e.toString());
    } finally {
      await service.dispose();
      if (mounted) setState(() => _starting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QR Login to This Account',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Transfer this account and its data to an empty device on the same Wi-Fi. You must approve the device before it signs in.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _starting ? null : _startLogin,
                icon: _starting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_2_rounded),
                label: Text(_starting ? 'Starting…' : 'Generate Login QR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrLoginHostDialog extends StatefulWidget {
  const _QrLoginHostDialog({required this.service, required this.qr});

  final QrLoginService service;
  final String qr;

  @override
  State<_QrLoginHostDialog> createState() => _QrLoginHostDialogState();
}

class _QrLoginHostDialogState extends State<_QrLoginHostDialog> {
  StreamSubscription<QrLoginRequest>? _requestSubscription;
  StreamSubscription<QrLoginRequest>? _completeSubscription;
  String _status = 'Waiting for another device to scan…';
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _requestSubscription = widget.service.requests.listen(_confirmDevice);
    _completeSubscription =
        widget.service.completedDevices.listen(_onTransferComplete);
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _completeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _confirmDevice(QrLoginRequest request) async {
    if (!mounted || _processing) return;
    _processing = true;
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve account sign-in?'),
        content: Text(
          '${request.deviceName} wants to sign in as this account.\n\n'
          'Approving transfers your local account and data, including the saved AI API key, over an encrypted Wi-Fi connection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Approve sign-in'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    try {
      if (approved == true) {
        setState(() => _status = 'Preparing encrypted account transfer…');
        await widget.service.approveRequest();
        if (mounted) {
          setState(
              () => _status = 'Waiting for ${request.deviceName} to finish…');
        }
      } else {
        widget.service.rejectRequest();
        setState(() => _status = 'Request declined. Waiting for another scan…');
      }
    } catch (e) {
      widget.service.rejectRequest();
      if (mounted) setState(() => _status = e.toString());
    } finally {
      _processing = false;
    }
  }

  void _onTransferComplete(QrLoginRequest request) {
    unawaited(P2PSyncService().registerPeer(
      peerId: request.deviceId,
      peerName: request.deviceName,
      peerAddress: request.address,
    ));
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${request.deviceName} signed in successfully.')),
      );
    }
  }

  Future<void> _cancel() async {
    await widget.service.stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title:
            Text('Sign in from ${widget.service.deviceName ?? 'this device'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan on the new device. Both devices must stay on the same Wi-Fi until transfer completes.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: QrImageView(data: widget.qr, size: 220),
              ),
              const SizedBox(height: 16),
              const Text('Enter this one-time PIN on the new device'),
              Text(
                widget.service.pin ?? '----',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
              ),
              const SizedBox(height: 8),
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'The QR and PIN expire after 5 minutes. Cancel at any time to stop the transfer.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _cancel,
            child: const Text('Cancel login transfer'),
          ),
        ],
      ),
    );
  }
}

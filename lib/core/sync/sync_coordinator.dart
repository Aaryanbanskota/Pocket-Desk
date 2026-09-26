import 'dart:async';
import 'dart:convert';
import '../logging/app_logger.dart';
import 'delta_sync_engine.dart';
import 'device_pairing_service.dart';
import 'sync_encryptor.dart';
import 'sync_protocol.dart';

/// Orchestrates synchronization between devices:
/// - Connects client and processes incoming messages.
/// - Performs delta packetization (offline queue sync).
/// - Encrypts / decrypts messages using [SyncEncryptor].
class SyncCoordinator {
  SyncCoordinator({
    required this.pairingService,
    required this.syncEngine,
    List<int>? encryptionKey,
  }) : _encryptor = encryptionKey != null
            ? SyncEncryptor(sharedKeyBytes: encryptionKey)
            : null {
    _initListener();
  }

  final DevicePairingService pairingService;
  final DeltaSyncEngine syncEngine;
  final SyncEncryptor? _encryptor;
  StreamSubscription<SyncMessage>? _sub;

  final _syncStateCtrl = StreamController<bool>.broadcast();
  Stream<bool> get syncProgress => _syncStateCtrl.stream;

  void _initListener() {
    _sub = pairingService.wsClient.messages.listen(_handleMessage);
  }

  /// Initiates synchronization: packages local changes and sends them.
  Future<void> triggerSync(int userId) async {
    if (!pairingService.wsClient.isConnected) {
      AppLogger.w('Cannot sync: WebSocket disconnected', tag: 'SyncCoord');
      return;
    }
    _syncStateCtrl.add(true);
    AppLogger.i('Starting sync transmission...', tag: 'SyncCoord');

    try {
      final changes = await syncEngine.getPendingChanges(userId);
      if (changes.isEmpty) {
        AppLogger.i('No offline changes to sync.', tag: 'SyncCoord');
        _syncStateCtrl.add(false);
        return;
      }

      final payloadJson = jsonEncode(changes.map((c) => c.toJson()).toList());
      String finalPayload = payloadJson;

      if (_encryptor != null) {
        finalPayload = await _encryptor.encrypt(payloadJson);
      }

      pairingService.wsClient.send(SyncMessage(
        type: SyncProtocol.msgSync,
        deviceId: pairingService.localDeviceId,
        payload: {
          'data': finalPayload,
          'encrypted': _encryptor != null,
        },
      ));
    } catch (e, st) {
      AppLogger.e('Sync transmission failed', tag: 'SyncCoord', error: e, st: st);
    } finally {
      _syncStateCtrl.add(false);
    }
  }

  Future<void> _handleMessage(SyncMessage msg) async {
    if (msg.type == SyncProtocol.msgSync) {
      await _processIncomingSync(msg);
    } else if (msg.type == SyncProtocol.msgSyncAck) {
      AppLogger.i('Sync completed successfully on remote device.', tag: 'SyncCoord');
    }
  }

  Future<void> _processIncomingSync(SyncMessage msg) async {
    _syncStateCtrl.add(true);
    try {
      final isEncrypted = msg.payload?['encrypted'] as bool? ?? false;
      final rawData = msg.payload?['data'] as String?;
      if (rawData == null) return;

      String decryptedJson = rawData;
      if (isEncrypted) {
        if (_encryptor == null) {
          AppLogger.e('Received encrypted payload but no key is configured!', tag: 'SyncCoord');
          return;
        }
        decryptedJson = await _encryptor.decrypt(rawData);
      }

      final decodedList = jsonDecode(decryptedJson) as List<dynamic>;
      final changes = decodedList
          .map((item) => DeltaChange.fromJson(item as Map<String, dynamic>))
          .toList();

      // Apply changes using DeltaSyncEngine (LWW conflict resolution)
      final activeUserId = await pairingService.wsClient.getConnectedUserId() ?? 1;
      await syncEngine.applyChanges(activeUserId, changes);

      // Ack completion
      pairingService.wsClient.send(SyncMessage(
        type: SyncProtocol.msgSyncAck,
        deviceId: pairingService.localDeviceId,
      ));

      AppLogger.i('Successfully applied ${changes.length} remote changes.', tag: 'SyncCoord');
    } catch (e, st) {
      AppLogger.e('Failed to process incoming sync', tag: 'SyncCoord', error: e, st: st);
    } finally {
      _syncStateCtrl.add(false);
    }
  }

  void dispose() {
    _sub?.cancel();
    _syncStateCtrl.close();
  }
}

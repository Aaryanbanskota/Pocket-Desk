import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../logging/app_logger.dart';
import 'pairing_token_service.dart';
import 'sync_protocol.dart';
import 'websocket_sync_client.dart';

/// Current pairing/connection state.
enum PairingStatus { unpaired, pairing, paired, error }

/// Holds info about a paired device.
class PairedDevice {
  const PairedDevice({
    required this.deviceId,
    required this.name,
    required this.wsUrl,
    required this.pairedAt,
  });

  final String deviceId;
  final String name;
  final String wsUrl;
  final DateTime pairedAt;

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'name': name,
        'wsUrl': wsUrl,
        'pairedAt': pairedAt.toIso8601String(),
      };

  factory PairedDevice.fromJson(Map<String, dynamic> j) => PairedDevice(
        deviceId: j['deviceId'] as String,
        name: j['name'] as String,
        wsUrl: j['wsUrl'] as String,
        pairedAt: DateTime.parse(j['pairedAt'] as String),
      );
}

/// Manages device pairing and the REST-style pairing handshake over WebSocket.
///
/// Pairing flow:
/// 1. Host generates a [PairingTokenService] token + encodes it in QR.
/// 2. Guest scans QR, calls [initiatePairing] with the decoded payload.
/// 3. Both sides exchange PAIR / PAIR_ACK messages, then transition to `paired`.
class DevicePairingService {
  DevicePairingService({
    required this.localDeviceId,
    required this.localDeviceName,
    PairingTokenService? tokenService,
  })  : _tokenService = tokenService ?? PairingTokenService(),
        _wsClient = WebSocketSyncClient(deviceId: localDeviceId);

  final String localDeviceId;
  final String localDeviceName;
  final PairingTokenService _tokenService;
  final WebSocketSyncClient _wsClient;

  PairingStatus _status = PairingStatus.unpaired;
  PairingStatus get status => _status;

  PairedDevice? _pairedDevice;
  PairedDevice? get pairedDevice => _pairedDevice;

  WebSocketSyncClient get wsClient => _wsClient;

  // ─── QR Payload generation ────────────────────────────────────────────────

  /// Returns a JSON string to encode in a QR code.
  /// Contains wsUrl, token, and device name.
  String generateQrPayload({required String wsUrl, required int userId}) {
    final token = _tokenService.issueToken(
      deviceId: localDeviceId,
      userId: userId,
    );
    return jsonEncode({
      'wsUrl': wsUrl,
      'token': token,
      'deviceId': localDeviceId,
      'deviceName': localDeviceName,
    });
  }

  // ─── Pairing initiation (guest side) ─────────────────────────────────────

  /// Called on the guest device after scanning the QR code.
  Future<bool> initiatePairing(String qrPayload) async {
    try {
      _status = PairingStatus.pairing;
      final data = jsonDecode(qrPayload) as Map<String, dynamic>;
      final wsUrl = data['wsUrl'] as String;
      final token = data['token'] as String;
      final remoteId = data['deviceId'] as String;
      final remoteName = data['deviceName'] as String;

      _wsClient.connect(wsUrl);

      // Listen for PAIR_ACK
      bool paired = false;
      await for (final msg in _wsClient.messages.timeout(
        SyncProtocol.pairingTimeout,
        onTimeout: (sink) => sink.close(),
      )) {
        if (msg.type == SyncProtocol.msgHello) {
          // Send PAIR request with token
          _wsClient.send(SyncMessage(
            type: SyncProtocol.msgPair,
            deviceId: localDeviceId,
            payload: {
              'token': token,
              'deviceName': localDeviceName,
            },
          ));
        } else if (msg.type == SyncProtocol.msgPairAck) {
          _pairedDevice = PairedDevice(
            deviceId: remoteId,
            name: remoteName,
            wsUrl: wsUrl,
            pairedAt: DateTime.now(),
          );
          _status = PairingStatus.paired;
          paired = true;
          AppLogger.i('Paired with $remoteName ($remoteId)', tag: 'PairingService');
          break;
        } else if (msg.type == SyncProtocol.msgPairReject) {
          _status = PairingStatus.error;
          AppLogger.w('Pairing rejected by $remoteId', tag: 'PairingService');
          break;
        }
      }
      return paired;
    } catch (e, st) {
      _status = PairingStatus.error;
      AppLogger.e('Pairing failed', tag: 'PairingService', error: e, st: st);
      return false;
    }
  }

  // ─── Host-side: handle incoming PAIR request ──────────────────────────────

  /// Called on the host when a PAIR message arrives.
  /// Returns true and sends PAIR_ACK if token is valid.
  bool handlePairRequest(SyncMessage msg, int expectedUserId) {
    final token = msg.payload?['token'] as String?;
    if (token == null) {
      _wsClient.send(SyncMessage(
          type: SyncProtocol.msgPairReject, deviceId: localDeviceId));
      return false;
    }
    final payload = _tokenService.verifyToken(token);
    if (payload == null || payload['userId'] != expectedUserId) {
      _wsClient.send(SyncMessage(
          type: SyncProtocol.msgPairReject, deviceId: localDeviceId));
      AppLogger.w('Invalid pairing token from ${msg.deviceId}', tag: 'PairingService');
      return false;
    }
    _wsClient.send(SyncMessage(
      type: SyncProtocol.msgPairAck,
      deviceId: localDeviceId,
      payload: {'deviceName': localDeviceName},
    ));
    _status = PairingStatus.paired;
    _pairedDevice = PairedDevice(
      deviceId: msg.deviceId,
      name: (msg.payload?['deviceName'] as String?) ?? 'Unknown',
      wsUrl: '',
      pairedAt: DateTime.now(),
    );
    AppLogger.i('Accepted pairing from ${msg.deviceId}', tag: 'PairingService');
    return true;
  }

  void unpair() {
    _pairedDevice = null;
    _status = PairingStatus.unpaired;
    _wsClient.disconnect();
  }

  void dispose() => _wsClient.dispose();

  /// Unique device ID — in production, use platform-specific device ID.
  static String generateDeviceId() {
    final bytes = utf8.encode(DateTime.now().toIso8601String());
    return sha256.convert(bytes).toString().substring(0, 16);
  }
}

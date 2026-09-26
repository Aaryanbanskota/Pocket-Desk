import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../logging/app_logger.dart';
import 'sync_protocol.dart';

/// Manages the WebSocket connection to a paired device.
///
/// - Auto-reconnects with exponential back-off (max 30 s).
/// - Sends PING heartbeats every [SyncProtocol.heartbeatInterval].
/// - Exposes [messages] stream for incoming [SyncMessage]s.
class WebSocketSyncClient {
  WebSocketSyncClient({required this.deviceId});

  final String deviceId;

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  final _messagesCtrl = StreamController<SyncMessage>.broadcast();
  Stream<SyncMessage> get messages => _messagesCtrl.stream;

  bool _connected = false;
  bool get isConnected => _connected;
  int? _connectedUserId;

  Future<int?> getConnectedUserId() async => _connectedUserId;

  String? _serverUrl;
  Duration _reconnectDelay = const Duration(seconds: 2);

  static const Duration _maxReconnectDelay = Duration(seconds: 30);

  // ─── Connect ──────────────────────────────────────────────────────────────

  void connect(String wsUrl) {
    _serverUrl = wsUrl;
    _doConnect();
  }

  void _doConnect() {
    if (_serverUrl == null) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl!));
      _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      _connected = true;
      _reconnectDelay = const Duration(seconds: 2);
      _startHeartbeat();
      _sendHello();
      AppLogger.i('WS connected to $_serverUrl', tag: 'WSSyncClient');
    } catch (e) {
      AppLogger.e('WS connect failed', tag: 'WSSyncClient', error: e);
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final msg = SyncMessage.fromJson(json);
      if (msg.type == SyncProtocol.msgHeartbeatAck) return; // swallow pongs
      _messagesCtrl.add(msg);
    } catch (e) {
      AppLogger.w('WS bad message: $raw', tag: 'WSSyncClient');
    }
  }

  void _onError(Object error) {
    AppLogger.e('WS error', tag: 'WSSyncClient', error: error);
    _connected = false;
    _scheduleReconnect();
  }

  void _onDone() {
    AppLogger.i('WS connection closed', tag: 'WSSyncClient');
    _connected = false;
    _heartbeatTimer?.cancel();
    _scheduleReconnect();
  }

  // ─── Heartbeat ────────────────────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(SyncProtocol.heartbeatInterval, (_) {
      send(SyncMessage(type: SyncProtocol.msgHeartbeat, deviceId: deviceId));
    });
  }

  // ─── Reconnect ────────────────────────────────────────────────────────────

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      AppLogger.i('WS reconnecting…', tag: 'WSSyncClient');
      _doConnect();
    });
    // Exponential back-off
    _reconnectDelay = _reconnectDelay * 2;
    if (_reconnectDelay > _maxReconnectDelay) {
      _reconnectDelay = _maxReconnectDelay;
    }
  }

  // ─── Send ─────────────────────────────────────────────────────────────────

  void send(SyncMessage message) {
    if (!_connected) return;
    try {
      _channel!.sink.add(jsonEncode(message.toJson()));
    } catch (e) {
      AppLogger.e('WS send failed', tag: 'WSSyncClient', error: e);
    }
  }

  void _sendHello() {
    send(SyncMessage(type: SyncProtocol.msgHello, deviceId: deviceId));
  }

  // ─── Disconnect ───────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    send(SyncMessage(type: SyncProtocol.msgDisconnect, deviceId: deviceId));
    await _channel?.sink.close();
    _connected = false;
    AppLogger.i('WS disconnected', tag: 'WSSyncClient');
  }

  void dispose() {
    disconnect();
    _messagesCtrl.close();
  }
}

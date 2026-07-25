import 'dart:convert';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:cryptography/cryptography.dart';

/// Represents shared data payload for QR code transfer
class SharedDataPayload {
  final String sessionId;
  final String deviceName;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int expiresInSeconds;

  SharedDataPayload({
    String? sessionId,
    required this.deviceName,
    required this.data,
    DateTime? createdAt,
    this.expiresInSeconds = 300, // 5 minutes default
  })  : sessionId = sessionId ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(createdAt).inSeconds > expiresInSeconds;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'deviceName': deviceName,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'expiresInSeconds': expiresInSeconds,
      };

  factory SharedDataPayload.fromJson(Map<String, dynamic> json) =>
      SharedDataPayload(
        sessionId: json['sessionId'] as String,
        deviceName: json['deviceName'] as String,
        data: json['data'] as Map<String, dynamic>,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresInSeconds: json['expiresInSeconds'] as int? ?? 300,
      );

  String toQrString() => base64Encode(utf8.encode(jsonEncode(toJson())));

  static SharedDataPayload? fromQrString(String qrString) {
    try {
      final decoded = utf8.decode(base64Decode(qrString));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return SharedDataPayload.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}

/// Service for handling QR code based data sharing and P2P synchronization
class QrDataShareService {
  static final QrDataShareService _instance = QrDataShareService._internal();

  factory QrDataShareService() {
    return _instance;
  }

  QrDataShareService._internal();



  // Store active sharing sessions
  final Map<String, SharedDataPayload> _activeSessions = {};
  final Map<String, StreamController<SharedDataPayload>> _sessionStreams = {};

  /// Generate a QR code string for the given data
  Future<String> generateQrString({
    required Map<String, dynamic> data,
    required String deviceName,
  }) async {
    final payload = SharedDataPayload(
      deviceName: deviceName,
      data: data,
      expiresInSeconds: 300,
    );

    _activeSessions[payload.sessionId] = payload;

    // Create a broadcast stream controller for this session
    _sessionStreams[payload.sessionId] = StreamController<SharedDataPayload>.broadcast();

    // Auto-cleanup expired session
    Timer(Duration(seconds: payload.expiresInSeconds), () {
      _activeSessions.remove(payload.sessionId);
      _sessionStreams[payload.sessionId]?.close();
      _sessionStreams.remove(payload.sessionId);
    });

    return payload.toQrString();
  }

  /// Verify and retrieve the shared data from a QR code string
  Future<SharedDataPayload?> verifyQrString(String qrString) async {
    final payload = SharedDataPayload.fromQrString(qrString);

    if (payload == null) return null;
    if (payload.isExpired) return null;

    // Get the active session
    final activeSession = _activeSessions[payload.sessionId];
    if (activeSession == null) return null;

    return activeSession;
  }

  /// Listen for sync confirmations from other devices
  Stream<SharedDataPayload> listenForSync(String sessionId) {
    if (!_sessionStreams.containsKey(sessionId)) {
      _sessionStreams[sessionId] = StreamController<SharedDataPayload>.broadcast();
    }
    return _sessionStreams[sessionId]!.stream;
  }

  /// Confirm data reception and sync
  Future<void> confirmSync(String sessionId, Map<String, dynamic> syncData) async {
    final session = _activeSessions[sessionId];
    if (session != null) {
      // ignore: close_sinks
      final stream = _sessionStreams[sessionId];
      if (stream != null && !stream.isClosed) {
        stream.add(session);
      }
    }
  }

  /// Generate encryption key for P2P communication
  Future<String> generateEncryptionKey() async {
    final algorithm = Chacha20.poly1305Aead();
    final secretKey = await algorithm.newSecretKey();
    return base64Encode(await secretKey.extractBytes());
  }

  /// Get active session details
  SharedDataPayload? getActiveSession(String sessionId) {
    return _activeSessions[sessionId];
  }

  /// List all active sessions
  List<SharedDataPayload> getActiveSessions() {
    // Clean expired sessions
    _activeSessions.removeWhere((_, payload) => payload.isExpired);
    return _activeSessions.values.toList();
  }

  /// Clear a specific session
  void clearSession(String sessionId) {
    _activeSessions.remove(sessionId);
    _sessionStreams[sessionId]?.close();
    _sessionStreams.remove(sessionId);
  }

  /// Clear all sessions
  void clearAllSessions() {
    for (var stream in _sessionStreams.values) {
      stream.close();
    }
    _activeSessions.clear();
    _sessionStreams.clear();
  }
}

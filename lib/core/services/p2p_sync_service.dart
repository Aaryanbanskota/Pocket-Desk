import 'dart:async';
import 'package:uuid/uuid.dart';

/// Represents a P2P sync event between devices
class SyncEvent {
  final String id;
  final String sourceDeviceId;
  final String targetDeviceId;
  final String type; // 'notes', 'tasks', 'calendar', etc.
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final bool isAcknowledged;

  SyncEvent({
    String? id,
    required this.sourceDeviceId,
    required this.targetDeviceId,
    required this.type,
    required this.payload,
    DateTime? timestamp,
    this.isAcknowledged = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceDeviceId': sourceDeviceId,
        'targetDeviceId': targetDeviceId,
        'type': type,
        'payload': payload,
        'timestamp': timestamp.toIso8601String(),
        'isAcknowledged': isAcknowledged,
      };

  factory SyncEvent.fromJson(Map<String, dynamic> json) => SyncEvent(
        id: json['id'] as String,
        sourceDeviceId: json['sourceDeviceId'] as String,
        targetDeviceId: json['targetDeviceId'] as String,
        type: json['type'] as String,
        payload: json['payload'] as Map<String, dynamic>,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isAcknowledged: json['isAcknowledged'] as bool? ?? false,
      );
}

/// P2P Data Sync Service for direct device-to-device synchronization
/// Supports peer-to-peer data sharing when devices are connected to the internet
class P2PSyncService {
  static final P2PSyncService _instance = P2PSyncService._internal();

  factory P2PSyncService() {
    return _instance;
  }

  P2PSyncService._internal();



  // Local device identifier
  String? _deviceId;
  String? _deviceName;

  // Connected peers
  final Map<String, dynamic> _connectedPeers = {};

  // Pending sync events
  final List<SyncEvent> _pendingSyncEvents = [];

  // Sync event streams
  final Map<String, StreamController<SyncEvent>> _syncStreams = {
    'all': StreamController<SyncEvent>.broadcast(),
    'notes': StreamController<SyncEvent>.broadcast(),
    'tasks': StreamController<SyncEvent>.broadcast(),
    'calendar': StreamController<SyncEvent>.broadcast(),
  };

  /// Initialize P2P sync with device information
  Future<void> initialize({
    String? deviceId,
    String? deviceName,
  }) async {
    _deviceId = deviceId ?? const Uuid().v4();
    _deviceName = deviceName ?? 'Unknown Device';
  }

  /// Get current device ID
  String? get deviceId => _deviceId;

  /// Get current device name
  String? get deviceName => _deviceName;

  /// Register a connected peer device
  Future<void> registerPeer({
    required String peerId,
    required String peerName,
    required String peerAddress, // IP address or connection string
  }) async {
    _connectedPeers[peerId] = {
      'name': peerName,
      'address': peerAddress,
      'connectedAt': DateTime.now(),
      'lastSync': DateTime.now(),
    };
  }

  /// Remove a peer from connected peers
  Future<void> removePeer(String peerId) async {
    _connectedPeers.remove(peerId);
  }

  /// Get list of connected peers
  List<dynamic> getConnectedPeers() {
    return _connectedPeers.values.toList();
  }

  /// Queue a sync event to be sent to peers
  Future<void> queueSyncEvent({
    required String type,
    required Map<String, dynamic> payload,
    String? targetDeviceId,
  }) async {
    if (_deviceId == null) {
      throw Exception('Device not initialized. Call initialize() first.');
    }

    final event = SyncEvent(
      sourceDeviceId: _deviceId!,
      targetDeviceId: targetDeviceId ?? 'broadcast',
      type: type,
      payload: payload,
    );

    _pendingSyncEvents.add(event);

    // Broadcast the event
    _syncStreams['all']?.add(event);
    _syncStreams[type]?.add(event);

    // Try to send immediately if we have connectivity
    await _sendPendingEvents();
  }

  /// Send pending sync events to peers
  Future<void> _sendPendingEvents() async {
    final List<SyncEvent> toRemove = [];

    for (final event in _pendingSyncEvents) {
      try {
        // In a real implementation, this would send via WebSocket or HTTP
        // For now, we simulate P2P delivery
        _simulateP2PDelivery(event);
        toRemove.add(event);
      } catch (e) {
        // Keep in queue for retry
      }
    }

    _pendingSyncEvents.removeWhere((e) => toRemove.contains(e));
  }

  /// Simulate P2P delivery (in production, use WebSocket or similar)
  void _simulateP2PDelivery(SyncEvent event) {
    // Emit to target peer's stream
    _syncStreams['all']?.add(event);
    _syncStreams[event.type]?.add(event);
  }

  /// Listen for sync events of all types
  Stream<SyncEvent> listenForAllSync() {
    return _syncStreams['all']?.stream ?? const Stream.empty();
  }

  /// Listen for sync events of a specific type
  Stream<SyncEvent> listenForSync(String type) {
    if (!_syncStreams.containsKey(type)) {
      _syncStreams[type] = StreamController<SyncEvent>.broadcast();
    }
    return _syncStreams[type]!.stream;
  }

  /// Acknowledge receipt of a sync event
  Future<void> acknowledgeSyncEvent(String eventId) async {
    // Find and mark event as acknowledged
    try {
      final index =
          _pendingSyncEvents.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        final event = _pendingSyncEvents[index];
        _pendingSyncEvents[index] = SyncEvent(
          id: event.id,
          sourceDeviceId: event.sourceDeviceId,
          targetDeviceId: event.targetDeviceId,
          type: event.type,
          payload: event.payload,
          timestamp: event.timestamp,
          isAcknowledged: true,
        );
      }
    } catch (e) {
      // Error acknowledging event
    }
  }

  /// Get pending sync events
  List<SyncEvent> getPendingSyncEvents() {
    return _pendingSyncEvents.toList();
  }

  /// Clear pending events
  void clearPendingEvents() {
    _pendingSyncEvents.clear();
  }

  /// Cleanup and close streams
  Future<void> dispose() async {
    for (var stream in _syncStreams.values) {
      await stream.close();
    }
    _syncStreams.clear();
    _connectedPeers.clear();
    _pendingSyncEvents.clear();
  }
}

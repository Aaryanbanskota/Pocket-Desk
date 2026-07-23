/// Sync protocol constants and message types for PocketDesk device pairing.
///
/// Milestone 7 — Backend & Sync Infrastructure
/// This defines the wire protocol used between paired devices over WebSocket.

abstract final class SyncProtocol {
  // ─── Message Types ────────────────────────────────────────────────────────
  static const String msgHello = 'HELLO';
  static const String msgPair = 'PAIR';
  static const String msgPairAck = 'PAIR_ACK';
  static const String msgPairReject = 'PAIR_REJECT';
  static const String msgSync = 'SYNC';
  static const String msgSyncAck = 'SYNC_ACK';
  static const String msgDelta = 'DELTA';
  static const String msgDeltaAck = 'DELTA_ACK';
  static const String msgHeartbeat = 'PING';
  static const String msgHeartbeatAck = 'PONG';
  static const String msgDisconnect = 'BYE';
  static const String msgError = 'ERROR';

  // ─── Collection Names ─────────────────────────────────────────────────────
  static const String colCalendarEvents = 'calendar_events';
  static const String colCalendars = 'calendars';
  static const String colTasks = 'tasks';
  static const String colNotes = 'notes';

  // ─── Protocol Version ─────────────────────────────────────────────────────
  static const int version = 1;

  // ─── Timeouts ─────────────────────────────────────────────────────────────
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration pairingTimeout = Duration(minutes: 5);
  static const Duration reconnectDelay = Duration(seconds: 5);
}

/// A single sync message sent over the wire (JSON-serialisable).
class SyncMessage {
  const SyncMessage({
    required this.type,
    required this.deviceId,
    this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? const _Now();

  final String type;
  final String deviceId;
  final Map<String, dynamic>? payload;
  final Object timestamp; // DateTime at runtime; workaround for const

  factory SyncMessage.fromJson(Map<String, dynamic> json) => SyncMessage(
        type: json['type'] as String,
        deviceId: json['deviceId'] as String,
        payload: json['payload'] as Map<String, dynamic>?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'deviceId': deviceId,
        'payload': payload,
        'timestamp': timestamp is DateTime
            ? (timestamp as DateTime).toIso8601String()
            : DateTime.now().toIso8601String(),
        'version': SyncProtocol.version,
      };
}

// Workaround: const placeholder for timestamp
class _Now {
  const _Now();
}

/// Represents a single delta change for one collection record.
class DeltaChange {
  const DeltaChange({
    required this.collection,
    required this.recordId,
    required this.operation,
    required this.data,
    required this.updatedAt,
  });

  final String collection; // e.g. SyncProtocol.colTasks
  final int recordId;
  final DeltaOp operation;
  final Map<String, dynamic> data;
  final DateTime updatedAt;

  factory DeltaChange.fromJson(Map<String, dynamic> j) => DeltaChange(
        collection: j['collection'] as String,
        recordId: j['recordId'] as int,
        operation: DeltaOp.values.byName(j['operation'] as String),
        data: (j['data'] as Map<String, dynamic>?) ?? {},
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'collection': collection,
        'recordId': recordId,
        'operation': operation.name,
        'data': data,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

enum DeltaOp { create, update, delete }

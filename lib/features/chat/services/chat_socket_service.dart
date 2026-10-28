import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../data/chat_repository.dart';
import 'call_audio_service.dart';

/// Single toggle for voice call debugging logs across transports, codecs, and filters.
const bool kCallDebug = true;

enum CallSignalType { invite, answer, end, busy, audioChunk, unknown }

class CallSignal {
  final CallSignalType type;
  final String callId;
  final String callerNumber;
  final String callerName;
  final String calleeNumber;
  final String senderNumber;
  final String? targetNumber;
  final String? senderDeviceId;
  final String? audioData;
  final String? codec; // 'mulaw' (G.711 mu-law 8kHz/16kHz) or 'pcm16' (raw 16-bit PCM)
  final int timestamp;
  final String? reason; // 'ended', 'declined', 'busy', 'missed'
  final String? token;

  const CallSignal({
    required this.type,
    required this.callId,
    required this.callerNumber,
    required this.callerName,
    required this.calleeNumber,
    String? senderNumber,
    this.targetNumber,
    this.senderDeviceId,
    this.audioData,
    this.codec,
    required this.timestamp,
    this.reason,
    this.token,
  }) : senderNumber = senderNumber ?? callerNumber;

  Map<String, dynamic> toJson() {
    final typeString = type == CallSignalType.audioChunk ? 'audio_chunk' : type.name;
    return {
      'signalType': typeString,
      'signal_type': typeString,
      'action': typeString,
      'callAction': typeString,
      'type': typeString,
      'callId': callId,
      'callerNumber': callerNumber,
      'callerName': callerName,
      'calleeNumber': calleeNumber,
      'senderNumber': senderNumber,
      'senderDeviceId': senderDeviceId ?? ChatSocketService.currentDeviceId,
      if (targetNumber != null) 'targetNumber': targetNumber,
      if (audioData != null) 'audioData': audioData,
      if (codec != null) 'codec': codec,
      'timestamp': timestamp,
      if (reason != null) 'reason': reason,
      if (token != null) 'token': token,
    };
  }

  factory CallSignal.fromJson(Map<String, dynamic> rawJson) {
    // If incoming json is wrapped inside outer Supabase 'payload' object(s), unwrap recursively:
    var json = rawJson;
    while (json['payload'] is Map) {
      json = Map<String, dynamic>.from(json['payload'] as Map);
    }

    CallSignalType parsedType;
    final typeStr = (json['signalType'] ??
            json['signal_type'] ??
            json['callAction'] ??
            json['action'] ??
            (json['type'] != null && json['type'].toString().toLowerCase() != 'broadcast'
                ? json['type']
                : null) ??
            (rawJson['signalType'] ??
                rawJson['signal_type'] ??
                rawJson['callAction'] ??
                rawJson['action'] ??
                (rawJson['type'] != null && rawJson['type'].toString().toLowerCase() != 'broadcast'
                    ? rawJson['type']
                    : null)) ??
            '')
        .toString()
        .toLowerCase();

    switch (typeStr) {
      case 'answer':
      case 'call_answer':
        parsedType = CallSignalType.answer;
        break;
      case 'end':
      case 'call_end':
      case 'hangup':
      case 'ended':
        parsedType = CallSignalType.end;
        break;
      case 'busy':
        parsedType = CallSignalType.busy;
        break;
      case 'invite':
      case 'call_invite':
        parsedType = CallSignalType.invite;
        break;
      case 'audio_chunk':
        parsedType = CallSignalType.audioChunk;
        break;
      default:
        parsedType = CallSignalType.unknown;
        break;
    }

    // Robust timestamp parsing tolerating int, double, and String
    int parseTimestamp(dynamic val) {
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) {
        final parsedInt = int.tryParse(val);
        if (parsedInt != null) return parsedInt;
        final parsedDouble = double.tryParse(val);
        if (parsedDouble != null) return parsedDouble.toInt();
      }
      return DateTime.now().millisecondsSinceEpoch;
    }

    return CallSignal(
      type: parsedType,
      callId: (json['callId'] ?? rawJson['callId'] ?? '').toString(),
      callerNumber: (json['callerNumber'] ?? rawJson['callerNumber'] ?? '').toString(),
      callerName: (json['callerName'] ?? rawJson['callerName'] ?? 'Caller').toString(),
      calleeNumber: (json['calleeNumber'] ?? rawJson['calleeNumber'] ?? '').toString(),
      senderNumber: (json['senderNumber'] ?? rawJson['senderNumber'] ?? json['callerNumber'] ?? rawJson['callerNumber'] ?? '').toString(),
      targetNumber: (json['targetNumber'] ?? rawJson['targetNumber'])?.toString(),
      senderDeviceId: (json['senderDeviceId'] ?? rawJson['senderDeviceId'])?.toString(),
      audioData: (json['audioData'] ?? rawJson['audioData'])?.toString(),
      codec: (json['codec'] ?? rawJson['codec'])?.toString(),
      timestamp: parseTimestamp(json['timestamp'] ?? rawJson['timestamp']),
      reason: (json['reason'] ?? rawJson['reason'])?.toString(),
      token: (json['token'] ?? rawJson['token'])?.toString(),
    );
  }
}

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  static const String _prefRelayKey = 'myday_chat_relay_url';
  static const String defaultRelayUrl = 'http://127.0.0.1:3000';

  // Per-launch unique session suffix ensures multiple app instances (e.g. running on desktop or sharing storage)
  // receive unique device IDs and never filter out each other's audio or signals.
  static final String _launchSessionSuffix = '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
  static String currentDeviceId = 'desk_dev_$_launchSessionSuffix';

  // Debug chunk counter at socket receive level
  static int _socketReceivedChunksCount = 0;

  static String normalize10(String num) {
    final d = num.replaceAll(RegExp(r'\D'), '');
    return d.length >= 10 ? d.substring(d.length - 10) : d;
  }

  static Future<void> initDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var baseId = prefs.getString('myday_device_instance_id');
      if (baseId == null || baseId.isEmpty) {
        baseId = 'desk_dev_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
        await prefs.setString('myday_device_instance_id', baseId);
      }
      // Combine persistent device base with this run's unique session suffix
      currentDeviceId = '${baseId}_$_launchSessionSuffix';
    } catch (_) {
      currentDeviceId = 'desk_dev_$_launchSessionSuffix';
    }
  }

  IO.Socket? _socket;
  WebSocket? _rawClientSocket;
  String _currentRelayUrl = defaultRelayUrl;
  String? _currentAccountId;
  String? _currentIdentityKey;
  String? _currentUserName;
  ChatRepository? _chatRepository;

  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  final ValueNotifier<String> relayUrlNotifier = ValueNotifier<String>(defaultRelayUrl);
  final ValueNotifier<bool> isLocalHostRunning = ValueNotifier<bool>(false);
  final ValueNotifier<String?> localHostIp = ValueNotifier<String?>(null);

  final StreamController<CallSignal> _callSignalController = StreamController<CallSignal>.broadcast();
  Stream<CallSignal> get onCallSignal => _callSignalController.stream;

  RealtimeChannel? _supabaseCallChannel;
  RealtimeChannel? _supabaseCallsBusChannel;
  RealtimeChannel? _activeCallChannel;
  String? _activeCallChannelId;
  String? _activeCallSessionId;

  String? get activeCallSessionId => _activeCallSessionId;

  void setActiveCallSessionId(String? callId) {
    _activeCallSessionId = callId;
  }

  String? _subscribedDirectChannelName;
  bool _isRealtimeSubscribed = false;
  HttpServer? _localRelayServer;
  final Map<String, WebSocket> _localRelayClients = {};
  final Map<String, int> _recentlyProcessedSignals = {};

  String get relayUrl => _currentRelayUrl;
  String? get currentIdentityKey => _currentIdentityKey;

  Future<void> initialize({
    required String accountId,
    required String identityKey,
    required String userName,
    required ChatRepository chatRepository,
  }) async {
    await initDeviceId();
    _currentAccountId = accountId;
    _currentIdentityKey = identityKey.trim().toLowerCase();
    _currentUserName = userName;
    _chatRepository = chatRepository;

    final prefs = await SharedPreferences.getInstance();
    _currentRelayUrl = prefs.getString(_prefRelayKey) ?? defaultRelayUrl;
    relayUrlNotifier.value = _currentRelayUrl;

    _connectSocket();
    _initSupabaseRealtime(_currentIdentityKey!);
  }

  void _initSupabaseRealtime(String identityKey) {
    try {
      final digits10 = normalize10(identityKey);
      final rawDigits = identityKey.replaceAll(RegExp(r'\D'), '');
      final directChannelName = 'pocketdesk_call_${digits10.isNotEmpty ? digits10 : (rawDigits.isNotEmpty ? rawDigits : identityKey)}';

      // If already initialized for this exact identity and channels are live, do not re-subscribe
      if (_isRealtimeSubscribed &&
          _subscribedDirectChannelName == directChannelName &&
          _supabaseCallChannel != null &&
          _supabaseCallsBusChannel != null) {
        return;
      }

      _isRealtimeSubscribed = true;
      _subscribedDirectChannelName = directChannelName;

      if (_supabaseCallChannel != null) {
        try {
          _supabaseCallChannel!.unsubscribe();
          Supabase.instance.client.removeChannel(_supabaseCallChannel!);
        } catch (_) {}
        _supabaseCallChannel = null;
      }
      if (_supabaseCallsBusChannel != null) {
        try {
          _supabaseCallsBusChannel!.unsubscribe();
          Supabase.instance.client.removeChannel(_supabaseCallsBusChannel!);
        } catch (_) {}
        _supabaseCallsBusChannel = null;
      }

      // 1. Direct personal incoming channel for control signals and messages
      final directCh = Supabase.instance.client.channel(
        directChannelName,
        opts: const RealtimeChannelConfig(self: true),
      );
      directCh.onBroadcast(
        event: 'call_signal',
        callback: (payload) {
          try {
            _handleIncomingCallSignal(payload);
          } catch (e) {
            debugPrint('Error parsing direct Supabase call signal: $e');
          }
        },
      );
      directCh.onBroadcast(
        event: 'direct_message',
        callback: (payload) {
          try {
            _handleIncomingMessage(payload);
          } catch (e) {
            debugPrint('Error parsing direct Supabase message: $e');
          }
        },
      );
      directCh.subscribe((status, [err]) {
        if (kCallDebug) {
          debugPrint('Direct call channel ($directChannelName) status: $status');
        }
      });
      _supabaseCallChannel = directCh;

      // 2. Global shared call bus (for invite/answer/end and fallback control signaling)
      const busChannelName = 'pocketdesk_calls_v2';
      final busCh = Supabase.instance.client.channel(
        busChannelName,
        opts: const RealtimeChannelConfig(self: true),
      );
      busCh.onBroadcast(
        event: 'call_signal',
        callback: (payload) {
          try {
            _handleIncomingCallSignal(payload);
          } catch (e) {
            debugPrint('Error parsing global bus call signal: $e');
          }
        },
      );
      busCh.onBroadcast(
        event: 'direct_message',
        callback: (payload) {
          try {
            _handleIncomingMessage(payload);
          } catch (e) {
            debugPrint('Error parsing global bus message: $e');
          }
        },
      );
      busCh.subscribe((status, [err]) {
        if (kCallDebug) {
          debugPrint('Global call bus ($busChannelName) status: $status');
        }
      });
      _supabaseCallsBusChannel = busCh;
    } catch (e) {
      debugPrint('Supabase realtime call init fallback: $e');
    }
  }

  /// Joins a dedicated per-call Supabase Realtime channel (call_<callId>) so audio chunks
  /// flow only between the two participants of this call, saving bandwidth and ensuring privacy.
  Future<void> joinCallChannel(String callId) async {
    if (_activeCallChannelId == callId && _activeCallChannel != null) return;
    await leaveCallChannel();
    _activeCallChannelId = callId;

    try {
      final channelName = 'call_$callId';
      final ch = Supabase.instance.client.channel(channelName);
      ch.onBroadcast(
        event: 'call_signal',
        callback: (payload) {
          try {
            _handleIncomingCallSignal(payload);
          } catch (e) {
            debugPrint('Error parsing per-call channel signal: $e');
          }
        },
      );
      ch.subscribe((status, [err]) {
        if (kCallDebug) {
          debugPrint('[CallAudio] Per-call channel ($channelName) status: $status');
        }
      });
      _activeCallChannel = ch;
    } catch (e) {
      debugPrint('Failed to join per-call channel call_$callId: $e');
    }
  }

  /// Leaves and disposes the dedicated per-call Supabase Realtime channel when the call ends.
  Future<void> leaveCallChannel() async {
    if (_activeCallChannel != null) {
      try {
        await _activeCallChannel!.unsubscribe();
        Supabase.instance.client.removeChannel(_activeCallChannel!);
      } catch (_) {}
      _activeCallChannel = null;
    }
    _activeCallChannelId = null;
  }

  void reconnectIfNeeded() {
    if (_currentIdentityKey != null) {
      _initSupabaseRealtime(_currentIdentityKey!);
      if ((_socket == null || !_socket!.connected) && _rawClientSocket == null) {
        _connectSocket();
      }
    }
  }

  Future<void> updateRelayUrl(String newUrl) async {
    final clean = newUrl.trim();
    if (clean.isEmpty) return;
    _currentRelayUrl = clean;
    relayUrlNotifier.value = clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefRelayKey, clean);
    _connectSocket();
  }

  /// Connects to either a raw WebSocket (if local relay / ws://) or a Socket.IO relay
  void _connectSocket() {
    _socket?.dispose();
    _socket = null;
    try {
      _rawClientSocket?.close();
    } catch (_) {}
    _rawClientSocket = null;
    isConnected.value = false;

    final trimmed = _currentRelayUrl.trim();
    final isPlainWs = trimmed.startsWith('ws://') ||
        trimmed.startsWith('wss://') ||
        (trimmed.contains(':3000') && isLocalHostRunning.value);

    // 1. Plain WebSocket connection mode (for built-in local Wi-Fi relay host)
    if (isPlainWs) {
      final wsUrl = trimmed.startsWith('http://')
          ? trimmed.replaceFirst('http://', 'ws://')
          : (trimmed.startsWith('https://') ? trimmed.replaceFirst('https://', 'wss://') : trimmed);
      WebSocket.connect(wsUrl).then((ws) {
        _rawClientSocket = ws;
        isConnected.value = true;
        if (kCallDebug) debugPrint('[ChatSocket] Connected via plain WebSocket to $wsUrl');

        // Register identity
        if (_currentIdentityKey != null) {
          ws.add(jsonEncode({
            'event': 'register',
            'data': {
              'identityKey': _currentIdentityKey,
              'name': _currentUserName ?? 'User',
            },
          }));
        }

        ws.listen(
          (rawMsg) {
            try {
              final parsed = jsonDecode(rawMsg.toString());
              final event = parsed['event'];
              final data = parsed['data'];
              if (event == 'call_signal') {
                _handleIncomingCallSignal(data);
              } else if (event == 'direct_message') {
                _handleIncomingMessage(data);
              }
            } catch (_) {}
          },
          onDone: () {
            isConnected.value = false;
            _rawClientSocket = null;
          },
          onError: (err) {
            isConnected.value = false;
            _rawClientSocket = null;
          },
        );
      }).catchError((Object err) {
        isConnected.value = false;
        _rawClientSocket = null;
        if (kCallDebug) debugPrint('[ChatSocket] Plain WebSocket connect failed: $err');
      });
      return;
    }

    // 2. Standard Socket.IO connection mode (for Node.js socket.io relays)
    try {
      final opts = IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(999)
          .build();

      final socket = IO.io(_currentRelayUrl, opts);

      socket.onConnect((_) {
        isConnected.value = true;
        if (kCallDebug) debugPrint('[ChatSocket] Connected to Socket.IO relay: $_currentRelayUrl');
        if (_currentIdentityKey != null) {
          socket.emit('register', {
            'identityKey': _currentIdentityKey,
            'name': _currentUserName ?? 'User',
          });
        }
      });

      socket.onDisconnect((_) {
        isConnected.value = false;
      });

      socket.onConnectError((err) {
        isConnected.value = false;
      });

      socket.on('direct_message', (data) async {
        await _handleIncomingMessage(data);
      });

      socket.on('call_signal', (data) {
        _handleIncomingCallSignal(data);
      });

      socket.connect();
      _socket = socket;
    } catch (e) {
      debugPrint('ChatSocketService connect error: $e');
      isConnected.value = false;
    }
  }

  void _handleIncomingCallSignal(dynamic rawData) {
    if (rawData == null) return;
    try {
      final map = rawData is String
          ? jsonDecode(rawData) as Map<String, dynamic>
          : Map<String, dynamic>.from(rawData as Map);
      final signal = CallSignal.fromJson(map);
      if (signal.type == CallSignalType.unknown) return;

      if (signal.type == CallSignalType.audioChunk) {
        _socketReceivedChunksCount++;
        if (kCallDebug) {
          debugPrint(
            '[CallAudio][RecvSocket #$_socketReceivedChunksCount] id=${signal.callId} '
            'fromDevice=${signal.senderDeviceId ?? "unknown"} '
            'senderNum=${signal.senderNumber} codec=${signal.codec ?? "legacy"} '
            'bytes=${signal.audioData?.length ?? 0}',
          );
        }
      }

      // 1. NEVER process signals sent by our own physical device instance
      // (Eliminates local mic audio echo and self-feedback loop)
      if (signal.senderDeviceId != null &&
          signal.senderDeviceId!.isNotEmpty &&
          signal.senderDeviceId == currentDeviceId) {
        return;
      }

      // 2. Deduplication check:
      // Multi-transport delivery means a chunk might arrive via both Socket/Relay and Supabase.
      // Deduplicate so each unique audio chunk or control signal is only handled once.
      final dedupeKey = signal.token != null
          ? signal.token!
          : (signal.type == CallSignalType.audioChunk
              ? '${signal.callId}_audio_${signal.timestamp}_${signal.senderDeviceId}_${signal.audioData?.length ?? 0}'
              : '${signal.callId}_${signal.type.name}');
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastSeen = _recentlyProcessedSignals[dedupeKey];
      if (lastSeen != null && (now - lastSeen) < (signal.type == CallSignalType.audioChunk ? 400 : 2000)) {
        return; // Duplicate chunk/signal already processed! Drop immediately to prevent duplicate playback!
      }
      _recentlyProcessedSignals[dedupeKey] = now;
      if (_recentlyProcessedSignals.length > 500) {
        _recentlyProcessedSignals.removeWhere((_, time) => now - time > 10000);
      }

      // 3. Routing check: Must be addressed to me or part of our active call session.
      // NOTE: We DO NOT reject audio when senderNumber matches our own identity number,
      // as long as senderDeviceId != currentDeviceId. This ensures developer and same-account
      // testing between two devices works smoothly.
      final isForMyActiveCall = _activeCallSessionId != null && signal.callId == _activeCallSessionId;

      final my10 = normalize10(_currentIdentityKey ?? '');
      final myRaw = (_currentIdentityKey ?? '').replaceAll(RegExp(r'\D'), '');
      final callee10 = normalize10(signal.calleeNumber);
      final caller10 = normalize10(signal.callerNumber);
      final target10 = normalize10(signal.targetNumber ?? '');

      final isAddressedToMe = isForMyActiveCall ||
          my10.isEmpty ||
          (target10.isNotEmpty && target10 == my10) ||
          (callee10.isNotEmpty && callee10 == my10) ||
          (caller10.isNotEmpty && caller10 == my10) ||
          (myRaw.isNotEmpty && (signal.calleeNumber.contains(myRaw) || myRaw.endsWith(callee10) || callee10.endsWith(myRaw))) ||
          (myRaw.isNotEmpty && ((signal.targetNumber ?? '').contains(myRaw) || myRaw.endsWith(target10) || target10.endsWith(myRaw))) ||
          (_activeCallChannelId != null && signal.callId == _activeCallChannelId);

      if (isAddressedToMe) {
        _callSignalController.add(signal);
      }
    } catch (e) {
      debugPrint('Error parsing incoming call signal: $e');
    }
  }

  /// Sends call signal over all available reliable transports:
  /// - Audio chunks go over active Socket.IO / plain WebSocket, local Wi-Fi relay,
  ///   the global call bus channel (pocketdesk_calls_v2), and the dedicated per-call channel.
  /// - Control signals go over Socket.IO, plain WebSocket, local relay, global bus,
  ///   and the target's direct personal channel.
  Future<void> sendCallSignal(CallSignal signal) async {
    final payload = signal.toJson();
    final broadcastPayload = {
      'payload': payload,
      ...payload,
    };

    // --- AUDIO CHUNK TRANSPORT ---
    if (signal.type == CallSignalType.audioChunk) {
      // 1. Emit on Socket.IO if connected
      if (_socket != null && _socket!.connected) {
        _socket!.emit('call_signal', payload);
      }

      // 2. Send over plain WebSocket if connected to local relay
      if (_rawClientSocket != null) {
        try {
          _rawClientSocket!.add(jsonEncode({'event': 'call_signal', 'data': payload}));
        } catch (_) {}
      }

      // 3. Forward via Local Wi-Fi relay server if hosting
      if (isLocalHostRunning.value) {
        final targetClean = normalize10(signal.targetNumber ?? signal.calleeNumber);
        final callerClean = normalize10(signal.callerNumber);
        try {
          _localRelayClients[targetClean]?.add(jsonEncode({
            'event': 'call_signal',
            'data': payload,
          }));
          if (callerClean.isNotEmpty && callerClean != targetClean) {
            _localRelayClients[callerClean]?.add(jsonEncode({
              'event': 'call_signal',
              'data': payload,
            }));
          }
        } catch (_) {}
      }

      // 4. Send over Supabase:
      // Always broadcast audio on _supabaseCallsBusChannel ('pocketdesk_calls_v2') which is
      // permanently subscribed from app startup and guarantees immediate delivery without dynamic join race conditions!
      if (_supabaseCallsBusChannel != null) {
        try {
          final res = await _supabaseCallsBusChannel!.sendBroadcastMessage(
            event: 'call_signal',
            payload: broadcastPayload,
          );
          if (res != ChannelResponse.ok) {
            // Fall back to target's direct personal channel via httpSend if websocket push was not ok
            final targetDigits = normalize10(signal.targetNumber ?? signal.calleeNumber);
            if (targetDigits.isNotEmpty) {
              final targetChName = 'pocketdesk_call_$targetDigits';
              Supabase.instance.client.channel(targetChName).httpSend(
                event: 'call_signal',
                payload: broadcastPayload,
              ).catchError((_) => ChannelResponse.error);
            }
          }
        } catch (e) {
          if (kCallDebug) debugPrint('[CallAudio] Bus broadcast error: $e');
        }
      }

      // If dedicated per-call channel is active and already SUBSCRIBED, also send there:
      if (_activeCallChannel != null &&
          _activeCallChannelId == signal.callId &&
          _activeCallChannel!.canPush) {
        try {
          await _activeCallChannel!.sendBroadcastMessage(
            event: 'call_signal',
            payload: broadcastPayload,
          );
        } catch (_) {}
      }
      return;
    }

    // --- CONTROL SIGNAL TRANSPORT (invite, answer, end, busy) ---
    // 1. Socket.IO relay
    if (_socket != null && _socket!.connected) {
      _socket!.emit('call_signal', payload);
    }

    // 2. Plain WebSocket relay
    if (_rawClientSocket != null) {
      try {
        _rawClientSocket!.add(jsonEncode({'event': 'call_signal', 'data': payload}));
      } catch (_) {}
    }

    // 3. Supabase global call bus (instant broadcast to all listening devices)
    if (_supabaseCallsBusChannel != null) {
      try {
        await _supabaseCallsBusChannel!.sendBroadcastMessage(
          event: 'call_signal',
          payload: broadcastPayload,
        );
      } catch (e) {
        if (kCallDebug) debugPrint('Supabase bus broadcast failed ($e), falling back to httpSend REST API');
        try {
          await _supabaseCallsBusChannel!.httpSend(
            event: 'call_signal',
            payload: broadcastPayload,
          );
        } catch (e2) {
          if (kCallDebug) debugPrint('Supabase bus httpSend fallback error: $e2');
        }
      }
    }

    // 4. Target's direct personal channel via httpSend (guaranteed delivery, zero subscription disruption)
    final targetClean = normalize10(signal.targetNumber ?? signal.calleeNumber);
    final callerClean = normalize10(signal.callerNumber);
    final targetRaw = (signal.targetNumber ?? signal.calleeNumber).replaceAll(RegExp(r'\D'), '');
    final callerRaw = signal.callerNumber.replaceAll(RegExp(r'\D'), '');
    final my10 = normalize10(_currentIdentityKey ?? '');
    final myRaw = (_currentIdentityKey ?? '').replaceAll(RegExp(r'\D'), '');

    final Set<String> targetNumbers = {};
    if (signal.type == CallSignalType.invite) {
      if (targetClean.isNotEmpty) targetNumbers.add(targetClean);
      if (targetRaw.isNotEmpty && targetRaw != targetClean) targetNumbers.add(targetRaw);
    } else if (signal.type == CallSignalType.answer) {
      if (callerClean.isNotEmpty) targetNumbers.add(callerClean);
      if (callerRaw.isNotEmpty && callerRaw != callerClean) targetNumbers.add(callerRaw);
      if (targetClean.isNotEmpty) targetNumbers.add(targetClean);
      if (targetRaw.isNotEmpty && targetRaw != targetClean) targetNumbers.add(targetRaw);
    } else if (signal.type == CallSignalType.end) {
      if (targetClean.isNotEmpty) targetNumbers.add(targetClean);
      if (targetRaw.isNotEmpty && targetRaw != targetClean) targetNumbers.add(targetRaw);
      if (callerClean.isNotEmpty) targetNumbers.add(callerClean);
      if (callerRaw.isNotEmpty && callerRaw != callerClean) targetNumbers.add(callerRaw);
    }

    targetNumbers.remove(my10);
    targetNumbers.remove(myRaw);

    for (final num in targetNumbers) {
      if (num.isEmpty) continue;
      try {
        final targetCh = Supabase.instance.client.channel('pocketdesk_call_$num');
        await targetCh.httpSend(
          event: 'call_signal',
          payload: broadcastPayload,
        );
      } catch (e) {
        if (kCallDebug) debugPrint('Target direct channel httpSend error for $num: $e');
      }
    }

    // 5. Local Wi-Fi relay host
    if (isLocalHostRunning.value) {
      try {
        _localRelayClients[targetClean]?.add(jsonEncode({
          'event': 'call_signal',
          'data': payload,
        }));
        if (callerClean.isNotEmpty && callerClean != targetClean) {
          _localRelayClients[callerClean]?.add(jsonEncode({
            'event': 'call_signal',
            'data': payload,
          }));
        }
      } catch (_) {}
    }
  }

  Future<void> _handleIncomingMessage(dynamic rawData) async {
    if (rawData == null || _chatRepository == null || _currentAccountId == null) return;
    try {
      final outer = rawData is String ? jsonDecode(rawData) : Map<String, dynamic>.from(rawData as Map);
      final data = (outer['payload'] is Map) ? Map<String, dynamic>.from(outer['payload'] as Map) : outer;

      final senderDeviceId = data['senderDeviceId']?.toString();
      final senderKey = (data['senderKey'] ?? '').toString().trim().toLowerCase();
      final receiverKey = (data['receiverKey'] ?? '').toString().trim().toLowerCase();
      final myKey = (_currentIdentityKey ?? '').trim().toLowerCase();
      final receiver10 = normalize10(data['receiverNumber']?.toString() ?? receiverKey);
      final my10 = normalize10(myKey);
      final sender10 = normalize10(data['senderNumber']?.toString() ?? senderKey);

      // 1. NEVER process, ding, or notify for messages sent by me (sender is me or our device instance)
      final isFromMe = (senderDeviceId != null && senderDeviceId.isNotEmpty && senderDeviceId == currentDeviceId) ||
          (senderKey.isNotEmpty && senderKey == myKey) ||
          (my10.isNotEmpty && sender10.isNotEmpty && sender10 == my10);

      if (isFromMe) {
        return; // Eliminates sender ding sound and sender notification!
      }

      final msgId = (data['id'] ?? '').toString();
      if (msgId.isNotEmpty) {
        if (_recentlyProcessedSignals.containsKey('msg_$msgId')) return;
        _recentlyProcessedSignals['msg_$msgId'] = DateTime.now().millisecondsSinceEpoch;
      }

      final myRaw = myKey.replaceAll(RegExp(r'\D'), '');
      final receiverRaw = (data['receiverNumber']?.toString() ?? receiverKey).replaceAll(RegExp(r'\D'), '');

      // Only process messages addressed to me (supports cross-region: India, USA, Britain, etc.)
      final isAddressedToMe = (receiverKey == myKey) ||
          (my10.isNotEmpty && receiver10 == my10) ||
          (myKey.isNotEmpty && receiverKey.contains(myKey)) ||
          (myRaw.isNotEmpty && receiverRaw.isNotEmpty && (myRaw == receiverRaw || myRaw.endsWith(receiverRaw) || receiverRaw.endsWith(myRaw))) ||
          myKey.isEmpty;
      if (!isAddressedToMe) return;

      final content = (data['content'] ?? '').toString();
      final mediaType = data['mediaType']?.toString();
      final mediaBase64 = data['mediaBase64']?.toString();
      final mediaUrl = data['mediaUrl']?.toString();
      final timestamp = data['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

      String? localMediaPath;
      if (mediaBase64 != null && mediaBase64.isNotEmpty) {
        try {
          final docsDir = await getApplicationDocumentsDirectory();
          final mediaDir = Directory('${docsDir.path}/chat_media');
          await mediaDir.create(recursive: true);
          final fileId = msgId.isNotEmpty ? msgId : 'img_${DateTime.now().millisecondsSinceEpoch}';
          final file = File('${mediaDir.path}/$fileId.jpg');
          await file.writeAsBytes(base64Decode(mediaBase64));
          localMediaPath = file.path;
        } catch (e) {
          debugPrint('Error saving incoming media base64: $e');
        }
      } else if (mediaUrl != null && mediaUrl.isNotEmpty) {
        localMediaPath = mediaUrl;
      }

      await _chatRepository!.saveIncomingMessage(
        accountId: _currentAccountId!,
        senderKey: senderKey,
        receiverKey: myKey,
        content: content,
        mediaPath: localMediaPath,
        mediaType: mediaType,
        timestamp: timestamp,
        customId: msgId.isNotEmpty ? msgId : null,
      );

      // Trigger incoming notification and ding sound strictly for incoming messages from PEER:
      try {
        CallAudioService.instance.playMessageDing();
        final senderName = (data['senderName'] ?? senderKey).toString();
        LocalNotificationService.showNotification(
          id: timestamp ~/ 1000,
          title: 'Message from $senderName',
          body: content.isNotEmpty
              ? content
              : (mediaType != null ? '📷 Sent a photo' : 'New message'),
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('Error processing incoming chat message: $e');
    }
  }

  Future<void> sendMessage({
    required String receiverKey,
    required String content,
    String? mediaPath,
    String? mediaType,
    String? customId,
  }) async {
    final cleanReceiver = receiverKey.trim().toLowerCase();
    final cleanSender = _currentIdentityKey ?? 'desk-key-user';
    final receiver10 = normalize10(cleanReceiver);
    final sender10 = normalize10(cleanSender);
    final receiverRaw = cleanReceiver.replaceAll(RegExp(r'\D'), '');
    final senderRaw = cleanSender.replaceAll(RegExp(r'\D'), '');
    final msgId = customId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final nowTimestamp = DateTime.now().millisecondsSinceEpoch;

    String? base64Media;
    String? mediaUrl;

    if (mediaPath != null && mediaPath.isNotEmpty) {
      final file = File(mediaPath);
      if (file.existsSync()) {
        try {
          final bytes = await file.readAsBytes();
          // Compress/scale so realtime WebSocket frame stays well under 60KB (Supabase limit is 256KB)
          Uint8List optimizedBytes = bytes;
          if (bytes.lengthInBytes > 60 * 1024) {
            try {
              final decoded = img.decodeImage(bytes);
              if (decoded != null) {
                final maxDim = max(decoded.width, decoded.height);
                img.Image resized = decoded;
                if (maxDim > 800) {
                  final scale = 800 / maxDim;
                  resized = img.copyResize(
                    decoded,
                    width: (decoded.width * scale).toInt(),
                    height: (decoded.height * scale).toInt(),
                    interpolation: img.Interpolation.linear,
                  );
                }
                optimizedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 65));
              }
            } catch (_) {
              optimizedBytes = bytes;
            }
          }
          base64Media = base64Encode(optimizedBytes);

          // Upload to Supabase Storage public files_bucket for high-res global CDN distribution
          try {
            final client = Supabase.instance.client;
            final storagePath = 'chat_images/${msgId}_$nowTimestamp.jpg';
            await client.storage.from('files_bucket').uploadBinary(
              storagePath,
              optimizedBytes,
              fileOptions: const FileOptions(upsert: true),
            );
            mediaUrl = client.storage.from('files_bucket').getPublicUrl(storagePath);
          } catch (uploadErr) {
            debugPrint('Chat image cloud storage upload notice: $uploadErr');
          }
        } catch (e) {
          debugPrint('Error preparing image for send: $e');
        }
      }
    }

    final payload = {
      'id': msgId,
      'senderKey': cleanSender,
      'senderNumber': sender10.isNotEmpty ? sender10 : senderRaw,
      'senderName': _currentUserName ?? 'User',
      'receiverKey': cleanReceiver,
      'receiverNumber': receiver10.isNotEmpty ? receiver10 : receiverRaw,
      'content': content,
      if (base64Media != null) 'mediaBase64': base64Media,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaType != null) 'mediaType': mediaType,
      'senderDeviceId': currentDeviceId,
      'timestamp': nowTimestamp,
    };

    final broadcastPayload = {
      'payload': payload,
      ...payload,
    };

    // 1. Emit via active Socket.io connection if connected
    if (_socket != null && _socket!.connected) {
      _socket!.emit('direct_message', payload);
    }

    // 2. Emit via plain WebSocket if connected
    if (_rawClientSocket != null) {
      try {
        _rawClientSocket!.add(jsonEncode({'event': 'direct_message', 'data': payload}));
      } catch (_) {}
    }

    // 3. Broadcast via Supabase global realtime bus (instant delivery worldwide: India, USA, Britain, etc.)
    if (_supabaseCallsBusChannel != null) {
      try {
        await _supabaseCallsBusChannel!.sendBroadcastMessage(
          event: 'direct_message',
          payload: broadcastPayload,
        );
      } catch (e) {
        if (kCallDebug) debugPrint('Supabase bus message send error ($e), trying httpSend');
        try {
          await _supabaseCallsBusChannel!.httpSend(
            event: 'direct_message',
            payload: broadcastPayload,
          );
        } catch (_) {}
      }
    }

    // 4. Broadcast to recipient's direct personal channel(s) via httpSend
    final Set<String> targetDirectKeys = {};
    if (receiver10.isNotEmpty && receiver10 != sender10) {
      targetDirectKeys.add(receiver10);
    }
    if (receiverRaw.isNotEmpty && receiverRaw != receiver10 && receiverRaw != senderRaw) {
      targetDirectKeys.add(receiverRaw);
    }

    for (final targetKey in targetDirectKeys) {
      try {
        final targetCh = Supabase.instance.client.channel('pocketdesk_call_$targetKey');
        await targetCh.httpSend(
          event: 'direct_message',
          payload: broadcastPayload,
        );
      } catch (e) {
        if (kCallDebug) debugPrint('Direct message httpSend error to $targetKey: $e');
      }
    }

    // 5. Save to Supabase Cloud public.chat_messages table for offline persistence
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession != null) {
        await client.from('chat_messages').insert({
          'id': payload['id'],
          'user_id': client.auth.currentUser?.id,
          'contact_key': cleanReceiver,
          'sender_key': cleanSender,
          'receiver_key': cleanReceiver,
          'content': content,
          'media_path': mediaUrl ?? mediaPath,
          'media_type': mediaType,
          'is_outgoing': true,
          'status': 'sent',
          'timestamp': payload['timestamp'],
        });
      }
    } catch (_) {}

    // 6. Also forward via Local Wi-Fi server if running as host
    if (isLocalHostRunning.value && _localRelayClients.containsKey(cleanReceiver)) {
      try {
        _localRelayClients[cleanReceiver]?.add(jsonEncode({
          'event': 'direct_message',
          'data': payload,
        }));
      } catch (_) {}
    }
  }

  /// Built-in local Wi-Fi relay host: runs in-memory stateless plain WebSocket relay server on port 3000.
  /// NOTE: This server uses plain WebSocket RFC6455 framing with {event, data} JSON.
  /// The client automatically connects using dart:io WebSocket when pointing to this local server.
  /// (If connecting external clients using socket.io-client library, a standard Node.js socket.io server is required).
  Future<bool> startLocalWifiRelayHost({int port = 3000}) async {
    try {
      await stopLocalWifiRelayHost();
      final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _localRelayServer = server;

      // Find local IP address
      String? foundIp;
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            foundIp = addr.address;
            break;
          }
        }
        if (foundIp != null) break;
      }
      localHostIp.value = foundIp ?? '127.0.0.1';
      isLocalHostRunning.value = true;

      server.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          // ignore: close_sinks
          final socket = await WebSocketTransformer.upgrade(request);
          String? registeredKey;

          socket.listen((rawMsg) {
            try {
              final parsed = jsonDecode(rawMsg.toString());
              final event = parsed['event'];
              final data = parsed['data'];

              if (event == 'register') {
                registeredKey = (data['identityKey'] ?? '').toString().trim().toLowerCase();
                if (registeredKey != null && registeredKey!.isNotEmpty) {
                  _localRelayClients[registeredKey!] = socket;
                }
              } else if (event == 'direct_message') {
                final targetKey = (data['receiverKey'] ?? '').toString().trim().toLowerCase();
                // ignore: close_sinks
                final targetSocket = _localRelayClients[targetKey];
                if (targetSocket != null) {
                  targetSocket.add(jsonEncode({
                    'event': 'direct_message',
                    'data': data,
                  }));
                }
              } else if (event == 'call_signal') {
                final targetKey = (data['calleeNumber'] ?? '').toString().replaceAll(RegExp(r'\D'), '').toLowerCase();
                final callerKey = (data['callerNumber'] ?? '').toString().replaceAll(RegExp(r'\D'), '').toLowerCase();
                _localRelayClients[targetKey]?.add(jsonEncode({
                  'event': 'call_signal',
                  'data': data,
                }));
                if (callerKey.isNotEmpty && callerKey != targetKey) {
                  _localRelayClients[callerKey]?.add(jsonEncode({
                    'event': 'call_signal',
                    'data': data,
                  }));
                }
              }
            } catch (_) {}
          }, onDone: () {
            if (registeredKey != null) {
              _localRelayClients.remove(registeredKey);
            }
          });
        } else {
          // HTTP health check
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'status': 'ok', 'relay': 'Pocketdesk Wi-Fi Relay'}))
            ..close();
        }
      });

      // Point our own client to our local host using ws:// so it connects via plain WebSocket
      await updateRelayUrl('ws://127.0.0.1:$port');
      return true;
    } catch (e) {
      debugPrint('Failed to start local Wi-Fi relay host: $e');
      isLocalHostRunning.value = false;
      return false;
    }
  }

  Future<void> stopLocalWifiRelayHost() async {
    await _localRelayServer?.close(force: true);
    _localRelayServer = null;
    _localRelayClients.clear();
    isLocalHostRunning.value = false;
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    try {
      _rawClientSocket?.close();
    } catch (_) {}
    _rawClientSocket = null;
    if (_supabaseCallChannel != null) {
      try {
        _supabaseCallChannel!.unsubscribe();
        Supabase.instance.client.removeChannel(_supabaseCallChannel!);
      } catch (_) {}
      _supabaseCallChannel = null;
    }
    if (_supabaseCallsBusChannel != null) {
      try {
        _supabaseCallsBusChannel!.unsubscribe();
        Supabase.instance.client.removeChannel(_supabaseCallsBusChannel!);
      } catch (_) {}
      _supabaseCallsBusChannel = null;
    }
    leaveCallChannel();
    stopLocalWifiRelayHost();
  }
}

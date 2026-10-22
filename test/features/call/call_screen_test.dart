import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketdesk/core/database/myday_database.dart';
import 'package:pocketdesk/features/auth/data/auth_repository.dart';
import 'package:pocketdesk/features/chat/data/chat_repository.dart';
import 'package:pocketdesk/features/chat/presentation/chat_screen.dart';
import 'package:pocketdesk/features/chat/presentation/widgets/phone_call_dialog.dart';
import 'package:pocketdesk/features/chat/services/call_audio_service.dart';
import 'package:pocketdesk/core/notifications/local_notification_service.dart';
import 'package:pocketdesk/features/chat/services/chat_socket_service.dart';
import 'package:pocketdesk/features/chat/services/voice_call_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MyDayDatabase db;
  late ChatRepository chatRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CallAudioService.instance.isAudioEnabled = false;
    LocalNotificationService.isNotificationEnabled = false;
    db = MyDayDatabase(NativeDatabase.memory());
    await db.initDatabase();
    chatRepo = ChatRepository(db);
  });

  tearDown(() async {
    CallAudioService.instance.stopAll();
    ChatSocketService().dispose();
    chatRepo.dispose();
    await db.close();
  });

  group('Call Signal Serialization & Dual Signaling', () {
    test('Serializes and deserializes CallSignal correctly', () {
      final invite = CallSignal(
        type: CallSignalType.invite,
        callId: 'call_12345',
        callerNumber: '9841928374',
        callerName: 'Aaryan',
        calleeNumber: '9860124892',
        timestamp: 1700000000000,
      );

      final json = invite.toJson();
      expect(json['type'], equals('invite'));
      expect(json['callId'], equals('call_12345'));
      expect(json['callerNumber'], equals('9841928374'));
      expect(json['calleeNumber'], equals('9860124892'));

      final reconstructed = CallSignal.fromJson(json);
      expect(reconstructed.type, equals(CallSignalType.invite));
      expect(reconstructed.callId, equals('call_12345'));
      expect(reconstructed.callerNumber, equals('9841928374'));
      expect(reconstructed.calleeNumber, equals('9860124892'));

      final answer = CallSignal(
        type: CallSignalType.answer,
        callId: 'call_12345',
        callerNumber: '9841928374',
        callerName: 'Aaryan',
        calleeNumber: '9860124892',
        timestamp: 1700000001000,
      );
      final reconstructedAnswer = CallSignal.fromJson(answer.toJson());
      expect(reconstructedAnswer.type, equals(CallSignalType.answer));

      final end = CallSignal(
        type: CallSignalType.end,
        callId: 'call_12345',
        callerNumber: '9841928374',
        callerName: 'Aaryan',
        calleeNumber: '9860124892',
        timestamp: 1700000002000,
        reason: 'declined',
      );
      final reconstructedEnd = CallSignal.fromJson(end.toJson());
      expect(reconstructedEnd.type, equals(CallSignalType.end));
      expect(reconstructedEnd.reason, equals('declined'));
    });

    test('Unwraps Supabase Realtime broadcast envelope and avoids false invite parsing', () {
      // Supabase delivers broadcast events wrapped in payload
      final supabaseBroadcast = {
        'event': 'call_signal',
        'type': 'broadcast',
        'payload': {
          'type': 'end',
          'callId': 'call_999',
          'callerNumber': '9841928374',
          'calleeNumber': '9860124892',
          'senderNumber': '9841928374',
          'targetNumber': '9860124892',
          'reason': 'hung_up',
        }
      };

      final parsed = CallSignal.fromJson(supabaseBroadcast);
      expect(parsed.type, equals(CallSignalType.end));
      expect(parsed.callId, equals('call_999'));
      expect(parsed.reason, equals('hung_up'));
      expect(parsed.senderNumber, equals('9841928374'));
      expect(parsed.targetNumber, equals('9860124892'));

      // An unknown envelope never defaults to invite (which previously caused self-call loop)
      final unknownEnvelope = {
        'type': 'system_ping',
        'callId': 'ping_1',
      };
      final parsedUnknown = CallSignal.fromJson(unknownEnvelope);
      expect(parsedUnknown.type, equals(CallSignalType.unknown));

      // Verifies that when Supabase overwrites 'type' with 'broadcast',
      // signalType and payload envelope preserve the real signal type
      final supabaseOverwrittenInvite = {
        'type': 'broadcast',
        'event': 'call_signal',
        'signalType': 'invite',
        'callId': 'call_abc',
        'callerNumber': '9841928374',
        'callerName': 'Laptop',
        'calleeNumber': '9860124892',
        'senderDeviceId': 'laptop_dev_1',
      };
      final parsedInvite = CallSignal.fromJson(supabaseOverwrittenInvite);
      expect(parsedInvite.type, equals(CallSignalType.invite));
      expect(parsedInvite.callId, equals('call_abc'));
      expect(parsedInvite.senderDeviceId, equals('laptop_dev_1'));
    });

    test('Normalize10 formats international and local numbers consistently', () {
      expect(ChatSocketService.normalize10('+977 9841928374'), equals('9841928374'));
      expect(ChatSocketService.normalize10('9841928374'), equals('9841928374'));
      expect(ChatSocketService.normalize10('9841-928-374'), equals('9841928374'));
      expect(ChatSocketService.normalize10('9779841928374'), equals('9841928374'));
    });

    test('Serializes and deserializes audioChunk signal', () {
      final audioSignal = CallSignal(
        type: CallSignalType.audioChunk,
        callId: 'call_audio_test',
        callerNumber: '9841928374',
        callerName: 'Aaryan',
        calleeNumber: '9860124892',
        senderNumber: '9841928374',
        targetNumber: '9860124892',
        audioData: 'AQIDBAUG',
        timestamp: 1700000003000,
      );

      final json = audioSignal.toJson();
      expect(json['type'], equals('audio_chunk'));
      expect(json['audioData'], equals('AQIDBAUG'));

      final reconstructed = CallSignal.fromJson(json);
      expect(reconstructed.type, equals(CallSignalType.audioChunk));
      expect(reconstructed.audioData, equals('AQIDBAUG'));
    });

    test('Serializes and deserializes CallSignal with tracking token for loopback prevention', () {
      final audioSignal = CallSignal(
        type: CallSignalType.audioChunk,
        callId: 'call_loopback_test',
        callerNumber: '9841928374',
        callerName: 'Aaryan',
        calleeNumber: '9860124892',
        senderNumber: '9841928374',
        targetNumber: '9860124892',
        token: 'token_chunk_12345',
        timestamp: 1700000004000,
      );

      final json = audioSignal.toJson();
      expect(json['token'], equals('token_chunk_12345'));

      final reconstructed = CallSignal.fromJson(json);
      expect(reconstructed.token, equals('token_chunk_12345'));
    });

    test('ChatSocketService manages activeCallSessionId correctly', () {
      final socketService = ChatSocketService();
      expect(socketService.activeCallSessionId, isNull);

      socketService.setActiveCallSessionId('call_session_999');
      expect(socketService.activeCallSessionId, equals('call_session_999'));

      socketService.setActiveCallSessionId(null);
      expect(socketService.activeCallSessionId, isNull);
    });

    test('G.711 mu-law encodes linear PCM and decodes faithfully', () {
      final originalPcm = Uint8List(3200);
      final byteData = ByteData.sublistView(originalPcm);
      for (int i = 0; i < 1600; i++) {
        // Generate a 16-bit linear sine-wave-like sample
        final sample = ((i % 100) * 300) - 15000;
        byteData.setInt16(i * 2, sample, Endian.little);
      }

      final encoded = VoiceCallAudioService.encodeMuLaw(originalPcm);
      expect(encoded.length, equals(1600)); // Exactly 50% compression

      final decoded = VoiceCallAudioService.decodeMuLaw(encoded);
      expect(decoded.length, equals(3200));

      final decodedData = ByteData.sublistView(decoded);
      // Verify samples retain their general waveform (within mu-law quantization error)
      for (int i = 0; i < 1600; i += 50) {
        final orig = byteData.getInt16(i * 2, Endian.little);
        final recon = decodedData.getInt16(i * 2, Endian.little);
        final diff = (orig - recon).abs();
        expect(diff < 2000, isTrue);
      }
    });

    test('calculateRms computes accurate signal energy for noise gate and AES', () {
      final silence = Uint8List(3200); // All zeros
      expect(VoiceCallAudioService.calculateRms(silence), equals(0.0));

      final activePcm = Uint8List(3200);
      final byteData = ByteData.sublistView(activePcm);
      for (int i = 0; i < 1600; i++) {
        byteData.setInt16(i * 2, 4000, Endian.little);
      }
      final energy = VoiceCallAudioService.calculateRms(activePcm);
      expect(energy, equals(4000.0));
    });
  });

  group('CallScreen UI Structure & Navigation', () {
    testWidgets('Opens with Dialpad view by default and shows small Call ID chip', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const cloudSession = UserSession(
        accountId: 'cloud_user_1',
        name: 'Aaryan Banskota',
        handle: 'aaryan',
        bio: 'Coding',
        email: 'aaryan@gmail.com',
        isCloud: true,
        isBioEnabled: false,
        customPhoneNumber: '9841928374',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallScreen(
              chatRepository: chatRepo,
              session: cloudSession,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify small Call ID chip is present with user's number
      expect(find.text('ID: 9841928374'), findsOneWidget);

      // 2. Verify Dialpad is opened by default
      expect(find.text('Type 10-digit number...'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('ABC'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // 3. Verify the 4 navigation tabs
      expect(find.text('Dialpad'), findsOneWidget);
      expect(find.text('Phonebook'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Recents'), findsOneWidget);

      // 4. Test typing numbers on dialpad
      await tester.tap(find.text('9'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('8'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('9841'), findsOneWidget);

      // 5. Test switching tabs to Phonebook
      await tester.tap(find.text('Phonebook'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Add Contact'), findsOneWidget);

      // 6. Test switching tabs to Messages
      await tester.tap(find.text('Messages'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('No Messages Yet'), findsOneWidget);

      // 7. Test switching tabs to Recents
      await tester.tap(find.text('Recents'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('No Recent Calls'), findsOneWidget);

      ChatSocketService().dispose();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('Local account shows Cloud Required banner in CallScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const localSession = UserSession(
        accountId: 'local_user_1',
        name: 'Local User',
        handle: 'local',
        bio: '',
        isCloud: false,
        isBioEnabled: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallScreen(
              chatRepository: chatRepo,
              session: localSession,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cloud Account Required'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
      expect(find.text('Call ID: Cloud Only'), findsOneWidget);
    });

    testWidgets('Renders Recent Call History items without overflow on narrow 360px screen', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Add call logs with long duration and names
      await chatRepo.addCallLog(
        'local_overflow_test',
        CallLogItem(
          id: 'log_1',
          contactKey: '9860124892',
          nickname: 'Prof. Christopher Alexander',
          type: 'outgoing',
          durationSeconds: 3672,
          timestamp: 1700000000000,
        ),
      );

      const localSession = UserSession(
        accountId: 'local_overflow_test',
        name: 'Aaryan Banskota',
        handle: 'aaryan',
        bio: '',
        isCloud: false,
        isBioEnabled: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallScreen(
              chatRepository: chatRepo,
              session: localSession,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Recents
      await tester.tap(find.text('Recents'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Recent Call History (1)'), findsOneWidget);
      expect(find.text('Prof. Christopher Alexander'), findsOneWidget);
      final exc = tester.takeException();
      if (exc is FlutterError) {
        for (final d in exc.diagnostics) {
          debugPrint('DIAG: ${d.value}');
        }
      }
      expect(exc, isNull);

      // Cleanly unmount
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });

  group('Phone Call Dialogs Rendering', () {
    testWidgets('Renders IncomingCallDialog with Accept and Decline buttons', (tester) async {
      final invite = CallSignal(
        type: CallSignalType.invite,
        callId: 'call_999',
        callerNumber: '9860124892',
        callerName: 'Akash Sharma',
        calleeNumber: '9841928374',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingCallDialog(
              invite: invite,
              accountId: 'test_acc',
              chatRepository: chatRepo,
              myNumber: '9841928374',
              myName: 'Aaryan',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Incoming Call...'), findsOneWidget);
      expect(find.text('Akash Sharma'), findsOneWidget);
      expect(find.text('9860124892'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);

      // Unmount dialog to cleanly dispose pulse controller animation
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}

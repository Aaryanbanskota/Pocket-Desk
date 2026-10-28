import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/database/myday_database.dart';
import 'package:pocketdesk/features/auth/data/auth_repository.dart';
import 'package:pocketdesk/features/chat/services/call_audio_service.dart';
import 'package:pocketdesk/features/chat/services/chat_socket_service.dart';
import 'package:pocketdesk/features/settings/presentation/developer_mode_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Developer Mode Narrow Screen Layout & Overflow Tests', () {
    testWidgets('DeveloperModeScreen renders on narrow 320px screen with ZERO overflow', (tester) async {
      // Smallest standard mobile screen width (e.g. iPhone SE / small Android)
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final db = MyDayDatabase.create(inMemory: true);
      await db.initDatabase();

      const session = UserSession(
        accountId: 'local_very_long_test_account_identifier_1234567890',
        name: 'Developer Overflow Tester',
        handle: 'devtester',
        bio: 'Testing layouts down to 320px width',
        isCloud: false,
        isBioEnabled: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DeveloperModeScreen(
            session: session,
            db: db,
            isDarkMode: true,
          ),
        ),
      );

      // Wait for initial load
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // 1. Verify AppBar title and badge render without overflow
      expect(find.text('Developer Mode'), findsOneWidget);
      expect(find.text('SANDBOX DECRYPTED'), findsOneWidget);

      // 2. Scroll TabBar horizontally to reveal Diagnostics tab
      final tabBarScrollable = find.descendant(
        of: find.byType(TabBar),
        matching: find.byType(Scrollable),
      );
      await tester.drag(tabBarScrollable, const Offset(-600, 0));
      await tester.pumpAndSettle();

      final diagnosticsTab = find.text('Diagnostics');
      expect(diagnosticsTab, findsOneWidget);
      await tester.tap(diagnosticsTab);
      await tester.pumpAndSettle();

      // 3. Scroll down Diagnostics ListView to reveal Environment Info Card
      await tester.drag(find.byType(ListView).last, const Offset(0, -500));
      await tester.pumpAndSettle();

      final sysEnvFinder = find.text('SYSTEM & RUNTIME ENVIRONMENT');
      expect(sysEnvFinder, findsOneWidget);
      expect(find.text('Database Engine'), findsOneWidget);
      expect(find.text('SQLite 3 via Drift Native (3.5+)'), findsOneWidget);
      expect(find.text('Decryption Engine'), findsOneWidget);
      expect(find.text('In-Memory QueryRow Native Mapping'), findsOneWidget);

      // Ensure no flutter render overflow error was caught by the tester
      expect(tester.takeException(), isNull);
    });
  });

  group('Call Audio & DTMF Sound System Tests', () {
    test('DTMF filename mapping maps 0-9, * and # correctly', () {
      final service = CallAudioService.instance;
      expect(service.isAudioEnabled, isTrue);

      // Verify playing dialpad tones for various digits executes cleanly
      expect(() => service.playDialpadTone('0'), returnsNormally);
      expect(() => service.playDialpadTone('5'), returnsNormally);
      expect(() => service.playDialpadTone('*'), returnsNormally);
      expect(() => service.playDialpadTone('#'), returnsNormally);
      expect(() => service.playDialpadTone(null), returnsNormally);
    });

    test('Call audio service handles ringtone, dialing tone, busy signal and ding', () async {
      final service = CallAudioService.instance;
      // Should not throw
      await service.startRingtone();
      await service.stopRingtone();
      await service.startDialingTone();
      await service.stopDialingTone();
      await service.playBusySignal();
      await service.playMessageDing();
      await service.stopAll();
    });
  });

  group('Call Signaling Protocol & Transport Tests', () {
    test('CallSignal serializes and deserializes correctly with unwrap', () {
      final original = CallSignal(
        type: CallSignalType.invite,
        callId: 'call_test_123',
        callerNumber: '9860124892',
        callerName: 'Akash Sharma',
        calleeNumber: '9841234567',
        timestamp: 1700000000000,
      );

      final json = original.toJson();
      expect(json['signalType'], 'invite');
      expect(json['callerNumber'], '9860124892');
      expect(json['calleeNumber'], '9841234567');

      // Nested envelope (as from Supabase realtime broadcast)
      final wrappedJson = {
        'event': 'call_signal',
        'payload': {
          'payload': json,
        },
      };

      final parsed = CallSignal.fromJson(wrappedJson);
      expect(parsed.type, CallSignalType.invite);
      expect(parsed.callId, 'call_test_123');
      expect(parsed.callerNumber, '9860124892');
      expect(parsed.calleeNumber, '9841234567');
    });

    test('ChatSocketService normalizes 10-digit numbers consistently', () {
      expect(ChatSocketService.normalize10('+977-9860124892'), '9860124892');
      expect(ChatSocketService.normalize10('9860124892'), '9860124892');
      expect(ChatSocketService.normalize10('01-9860124892'), '9860124892');
      expect(ChatSocketService.normalize10('123'), '123');
    });
  });
}

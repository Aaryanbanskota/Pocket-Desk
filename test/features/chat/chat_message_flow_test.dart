import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/database/myday_database.dart';
import 'package:pocketdesk/features/chat/data/chat_repository.dart';
import 'package:pocketdesk/features/chat/presentation/conversation_screen.dart';
import 'package:pocketdesk/features/chat/services/chat_socket_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MyDayDatabase db;
  late ChatRepository chatRepository;

  setUp(() async {
    db = MyDayDatabase(NativeDatabase.memory());
    await db.initDatabase();
    chatRepository = ChatRepository(db);
  });

  tearDown(() async {
    chatRepository.dispose();
    await db.close();
  });

  group('Chat Message Status & Outgoing Flow', () {
    test('Outgoing message is saved with status "sending" and transitions to "sent"', () async {
      const accountId = 'acc_test_1';
      const myKey = '9876543210';
      const contactKey = '2125551234';

      // 1. Initial save with 'sending'
      final msg = await chatRepository.saveOutgoingMessage(
        accountId: accountId,
        senderKey: myKey,
        receiverKey: contactKey,
        content: 'Hello from India to USA!',
        status: 'sending',
      );

      expect(msg.status, equals('sending'));
      expect(msg.isSending, isTrue);
      expect(msg.isSent, isFalse);

      // Verify in DB
      var messages = await chatRepository.getMessages(accountId, contactKey);
      expect(messages.length, equals(1));
      expect(messages.first.status, equals('sending'));

      // 2. Update to 'sent'
      await chatRepository.updateMessageStatus(msg.id, 'sent');

      messages = await chatRepository.getMessages(accountId, contactKey);
      expect(messages.first.status, equals('sent'));
      expect(messages.first.isSending, isFalse);
      expect(messages.first.isSent, isTrue);
    });

    test('Incoming message defaults to status "delivered"', () async {
      const accountId = 'acc_test_1';
      const peerKey = '2125551234';
      const myKey = '9876543210';

      final incoming = await chatRepository.saveIncomingMessage(
        accountId: accountId,
        senderKey: peerKey,
        receiverKey: myKey,
        content: 'Hello back from USA!',
      );

      expect(incoming.status, equals('delivered'));
      expect(incoming.isOutgoing, isFalse);
      expect(incoming.isSent, isTrue);
    });
  });

  group('Cross-Region & Country Code Phone Number Normalization', () {
    test('Normalizes Indian (+91), US (+1), and UK (+44) numbers consistently', () {
      // India: +91 98765 43210
      expect(ChatSocketService.normalize10('+919876543210'), equals('9876543210'));
      expect(ChatSocketService.normalize10('9876543210'), equals('9876543210'));

      // USA: +1 (212) 555-1234
      expect(ChatSocketService.normalize10('+12125551234'), equals('2125551234'));
      expect(ChatSocketService.normalize10('(212) 555-1234'), equals('2125551234'));

      // Britain / UK: +44 7911 123456 & local 07911 123456
      expect(ChatSocketService.normalize10('+447911123456'), equals('7911123456'));
      expect(ChatSocketService.normalize10('07911123456'), equals('7911123456'));
      expect(ChatSocketService.normalize10('7911123456'), equals('7911123456'));
    });
  });

  group('Conversation Screen Widget & Status Indicators', () {
    testWidgets('Renders sending status and sent double checkmark correctly', (tester) async {
      const accountId = 'acc_widget_1';
      const myKey = '9876543210';
      const contactKey = '2125551234';

      // Seed contact
      final contact = await chatRepository.addOrUpdateContact(
        accountId: accountId,
        contactKey: contactKey,
        nickname: 'Alice in USA',
      );

      // Seed 1 message sent, 1 message sending
      await chatRepository.saveOutgoingMessage(
        accountId: accountId,
        senderKey: myKey,
        receiverKey: contactKey,
        content: 'First message',
        status: 'sent',
      );

      await chatRepository.saveOutgoingMessage(
        accountId: accountId,
        senderKey: myKey,
        receiverKey: contactKey,
        content: 'Second message in progress',
        status: 'sending',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationScreen(
            chatRepository: chatRepository,
            accountId: accountId,
            myIdentityKey: myKey,
            myName: 'Bob in India',
            contact: contact,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check messages text
      expect(find.text('First message'), findsOneWidget);
      expect(find.text('Second message in progress'), findsOneWidget);

      // Check status texts
      expect(find.text('sending'), findsOneWidget);
      expect(find.text('sent'), findsOneWidget);

      // Check double check icon for sent message
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);

      // Check redesigned modern input field & buttons
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type a message...'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });
  });
}

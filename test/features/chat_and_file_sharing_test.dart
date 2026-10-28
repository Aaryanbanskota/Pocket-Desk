import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/database/myday_database.dart';
import 'package:pocketdesk/core/design_system/widgets/app_scaffold.dart';
import 'package:pocketdesk/features/auth/data/auth_repository.dart';
import 'package:pocketdesk/features/chat/data/chat_repository.dart';
import 'package:pocketdesk/features/files/data/files_repository.dart';
import 'package:pocketdesk/features/home/presentation/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MyDayDatabase db;
  late ChatRepository chatRepo;
  late FilesRepository filesRepo;

  setUp(() async {
    db = MyDayDatabase(NativeDatabase.memory());
    await db.initDatabase();
    chatRepo = ChatRepository(db);
    filesRepo = FilesRepository(db);
  });

  tearDown(() async {
    chatRepo.dispose();
    await db.close();
  });

  group('User Identity Key & Session', () {
    test('Generates unique stable identity key in format desk-key-XXXX', () {
      const localSession = UserSession(
        accountId: 'local_a1b2c3d4',
        name: 'Alice',
        handle: 'alice',
        bio: '',
        isCloud: false,
        isBioEnabled: false,
      );
      expect(localSession.identityKey.startsWith('desk-key-'), isTrue);
      expect(localSession.identityKey, equals('desk-key-A1B2C3'));

      const cloudSession = UserSession(
        accountId: '8f4c2e11-9a3b',
        name: 'Bob',
        handle: 'bob',
        bio: '',
        isCloud: true,
        isBioEnabled: false,
      );
      expect(cloudSession.identityKey.startsWith('desk-key-'), isTrue);
      expect(cloudSession.identityKey, equals('desk-key-8F4C2E'));
    });

    test('Custom identity key overrides automatic key if present', () {
      const customSession = UserSession(
        accountId: 'local_9999',
        name: 'Custom',
        handle: 'custom',
        bio: '',
        isCloud: false,
        isBioEnabled: false,
        customIdentityKey: 'desk-key-SUPERUSER',
      );
      expect(customSession.identityKey, equals('desk-key-SUPERUSER'));
    });
  });

  group('Local Database Chat & Messaging', () {
    test('Adds contact and normalizes desk-key format', () async {
      final contact = await chatRepo.addOrUpdateContact(
        accountId: 'test_account_1',
        contactKey: 'DESK-KEY-XYZ123',
        nickname: 'Charlie',
      );

      expect(contact.nickname, equals('Charlie'));
      expect(contact.contactKey, equals('desk-key-xyz123'));

      final list = await chatRepo.getContacts('test_account_1');
      expect(list.length, equals(1));
      expect(list.first.nickname, equals('Charlie'));
    });

    test('Saves outgoing and incoming messages strictly on local database', () async {
      final contactKey = 'desk-key-peer1';

      // Outgoing
      final outgoing = await chatRepo.saveOutgoingMessage(
        accountId: 'acc1',
        senderKey: 'desk-key-me',
        receiverKey: contactKey,
        content: 'Hello over local Wi-Fi!',
      );
      expect(outgoing.isOutgoing, isTrue);
      expect(outgoing.content, equals('Hello over local Wi-Fi!'));

      // Incoming
      final incoming = await chatRepo.saveIncomingMessage(
        accountId: 'acc1',
        senderKey: contactKey,
        receiverKey: 'desk-key-me',
        content: 'Hey Alice, received loud and clear!',
      );
      expect(incoming.isOutgoing, isFalse);

      final messages = await chatRepo.getMessages('acc1', contactKey);
      expect(messages.length, equals(2));
      expect(messages[0].content, equals('Hello over local Wi-Fi!'));
      expect(messages[1].content, equals('Hey Alice, received loud and clear!'));
    });
  });

  group('Three File Sharing Modes', () {
    test('File sharing supports Private with password verification, Friends, and Public', () {
      // 1. Private file with password
      final privateFile = MyDayFile(
        id: 'f1',
        accountId: 'acc1',
        name: 'secret.pdf',
        sizeBytes: 1024,
        localPath: '/files/f1.pdf',
        shareType: 'private',
        sharePassword: FilesRepository.hashPassword('1234'),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(privateFile.isPrivate, isTrue);
      expect(privateFile.hasPassword, isTrue);
      expect(filesRepo.verifyFilePassword(privateFile, '1234'), isTrue);
      expect(filesRepo.verifyFilePassword(privateFile, 'wrong'), isFalse);

      // 2. Friends only file
      final friendsFile = MyDayFile(
        id: 'f2',
        accountId: 'acc1',
        name: 'family_photo.jpg',
        sizeBytes: 2048,
        localPath: '/files/f2.jpg',
        shareType: 'friends',
        sharedWith: ['desk-key-friend1', 'desk-key-friend2'],
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(friendsFile.isFriends, isTrue);
      expect(friendsFile.sharedWith.length, equals(2));

      // 3. Public file (displays explicit warning)
      final publicFile = MyDayFile(
        id: 'f3',
        accountId: 'acc1',
        name: 'handout.txt',
        sizeBytes: 512,
        localPath: '/files/f3.txt',
        shareType: 'public',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(publicFile.isPublic, isTrue);
    });

    test('Cloud Bucket File Sharing: Everyone, Private with PIN, and Friends Share by Phone', () async {
      // 1. Insert Everyone File
      await db.customInsert(
        '''
        INSERT INTO stored_files (
          id, account_id, name, size_bytes, local_path, file_url,
          share_type, pin, friend_phone_number, uploader_name, uploader_phone,
          is_deleted, sync_status, created_at
        ) VALUES ('pub_1', 'acc1', 'public_guide.pdf', 2048, '', 'https://supabase.co/pub.pdf',
          'everyone', '', '', 'Aaryan', '9841928374', 0, 'synced', 1700000000000)
        ''',
      );

      // 2. Insert Private PIN-locked File
      await db.customInsert(
        '''
        INSERT INTO stored_files (
          id, account_id, name, size_bytes, local_path, file_url,
          share_type, pin, friend_phone_number, uploader_name, uploader_phone,
          is_deleted, sync_status, created_at
        ) VALUES ('priv_1', 'acc1', 'secret_notes.txt', 1024, '', 'https://supabase.co/priv.txt',
          'private', '4829', '', 'Aaryan', '9841928374', 0, 'synced', 1700000001000)
        ''',
      );

      // 3. Insert Friends Share File (Target phone: 9860124892)
      await db.customInsert(
        '''
        INSERT INTO stored_files (
          id, account_id, name, size_bytes, local_path, file_url,
          share_type, pin, friend_phone_number, uploader_name, uploader_phone,
          is_deleted, sync_status, created_at
        ) VALUES ('friend_1', 'acc1', 'exam_notes.pdf', 4096, '', 'https://supabase.co/friend.pdf',
          'friends', '', '9860124892', 'Aaryan', '9841928374', 0, 'synced', 1700000002000)
        ''',
      );

      // Verify Everyone query
      final everyone = await filesRepo.getEveryoneFiles();
      expect(everyone.any((f) => f.name == 'public_guide.pdf'), isTrue);

      // Verify Private query by PIN
      final foundByPin = await filesRepo.getFileByPin('4829');
      expect(foundByPin, isNotNull);
      expect(foundByPin!.name, equals('secret_notes.txt'));
      expect(foundByPin.pin, equals('4829'));

      // Incorrect PIN returns null
      final notFound = await filesRepo.getFileByPin('0000');
      expect(notFound, isNull);

      // Verify Friends Share query by recipient phone number
      final friendsFiles = await filesRepo.getFriendsFiles('9860124892');
      expect(friendsFiles.length, equals(1));
      expect(friendsFiles.first.name, equals('exam_notes.pdf'));
      expect(friendsFiles.first.friendPhoneNumber, equals('9860124892'));
    });
  });

  group('UI Drawer & Local Account Access Control', () {
    testWidgets('AppScaffold drawer removes Profile, adds Chat, and hides Files for local account', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppScaffold(
            currentTab: MyDayNavTab.home,
            onTabSelected: (_) {},
            onQuickAction: () {},
            userName: 'Local Tester',
            accountType: 'Local account',
            isDarkMode: true,
            onToggleTheme: () {},
            onLogout: () {},
            child: const Center(child: Text('Main Content')),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Verify Call tile is present in drawer
      expect(find.widgetWithText(ListTile, 'Call'), findsOneWidget);

      // Verify Profile tile is REMOVED from drawer menu list
      expect(find.widgetWithText(ListTile, 'Profile'), findsNothing);

      // Verify Files tile is HIDDEN for Local account
      expect(find.widgetWithText(ListTile, 'Files'), findsNothing);
    });

    testWidgets('AppScaffold drawer shows Files for Cloud account', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppScaffold(
            currentTab: MyDayNavTab.home,
            onTabSelected: (_) {},
            onQuickAction: () {},
            userName: 'Cloud Tester',
            accountType: 'tester@pocketdesk.io',
            isDarkMode: true,
            onToggleTheme: () {},
            onLogout: () {},
            child: const Center(child: Text('Main Content')),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Scroll drawer to reveal lower items
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Files tile is present for cloud account
      expect(find.widgetWithText(ListTile, 'Files'), findsOneWidget);
    });

    testWidgets('HomeScreen displays Chat shortcut for local account and File share for cloud account', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const localSession = UserSession(
        accountId: 'local_1',
        name: 'Alice',
        handle: 'alice',
        bio: '',
        isCloud: false,
        isBioEnabled: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              session: localSession,
              tasks: const [],
              notes: const [],
              wallets: const [],
              budgets: const [],
              datesWithTasks: const {},
              onNavigate: (_) {},
              onToggleTask: (_) {},
              onEditTask: (_) {},
              onDeleteTask: (_) {},
              onRunTask: (_) {},
              runningTimers: const {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Local account has Call shortcut instead of File share
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('File share'), findsNothing);

      const cloudSession = UserSession(
        accountId: 'cloud_1',
        name: 'Bob',
        handle: 'bob',
        bio: '',
        isCloud: true,
        isBioEnabled: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              session: cloudSession,
              tasks: const [],
              notes: const [],
              wallets: const [],
              budgets: const [],
              datesWithTasks: const {},
              onNavigate: (_) {},
              onToggleTask: (_) {},
              onEditTask: (_) {},
              onDeleteTask: (_) {},
              onRunTask: (_) {},
              runningTimers: const {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Cloud account has File share shortcut
      expect(find.text('File share'), findsOneWidget);
    });
  });
}

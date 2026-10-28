import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/database/myday_database.dart';
import 'package:pocketdesk/core/security/secure_pin_service.dart';
import 'package:pocketdesk/features/settings/data/legacy_pocketdesk_importer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LegacyPocketdeskImporter Unit Tests', () {
    late MyDayDatabase db;
    late LegacyPocketdeskImporter importer;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'last_username': 'akash',
      });
      db = MyDayDatabase.create(inMemory: true);
      await db.initDatabase();
      importer = LegacyPocketdeskImporter(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('detectOldPocketdeskUsername returns saved username from preferences', () async {
      final username = await importer.detectOldPocketdeskUsername();
      expect(username, 'akash');
    });

    test('verifyCredentials validates PIN against local account pin hash', () async {
      final pinHash = SecurePinService.hashPin('2222');
      await db.customInsert(
        '''
        INSERT INTO local_accounts (id, name, handle, pin_hash, bio_enabled, is_cloud, created_at)
        VALUES ('acc_1', 'Akash Test', 'akash', ?, 1, 0, ?)
        ''',
        variables: [Variable(pinHash), Variable(DateTime.now().millisecondsSinceEpoch)],
      );

      final valid = await importer.verifyCredentials(
        username: 'akash',
        passwordOrPin: '2222',
      );
      expect(valid, isTrue);

      final invalid = await importer.verifyCredentials(
        username: 'akash',
        passwordOrPin: 'wrong',
      );
      expect(invalid, isFalse);
    });

    test('pullOldPocketdeskData imports tasks, wallets, and notes into active account', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      // Seed source account
      await db.customInsert(
        '''
        INSERT INTO local_accounts (id, name, handle, pin_hash, bio_enabled, is_cloud, created_at)
        VALUES ('src_acc', 'Source User', 'akash_src', 'hash', 1, 0, ?)
        ''',
        variables: [Variable(now)],
      );

      // Seed task in source account
      await db.customInsert(
        '''
        INSERT INTO tasks (
          id, account_id, kind, title, min_duration, duration_left_ms, due_date,
          is_important, is_done, repeat_interval, spawned, tags_json, note,
          is_deleted, sync_status, created_at, updated_at
        ) VALUES ('t_1', 'src_acc', 'todo', 'Migrated Task 1', 15, 0, '2026-10-20',
          1, 0, 'none', 0, '["work"]', 'Test note', 0, 'synced', ?, ?)
        ''',
        variables: [Variable(now), Variable(now)],
      );

      // Seed wallet in source account
      await db.customInsert(
        '''
        INSERT INTO wallets (
          id, account_id, name, currency, initial_balance, is_archived, is_deleted, sync_status, created_at, updated_at
        ) VALUES ('w_1', 'src_acc', 'Savings', 'NPR', 500000, 0, 0, 'synced', ?, ?)
        ''',
        variables: [Variable(now), Variable(now)],
      );

      // Run pull for target account
      final summary = await importer.pullOldPocketdeskData(
        targetAccountId: 'dest_acc',
        username: 'akash_src',
      );

      expect(summary.tasksCount, greaterThanOrEqualTo(1));
      expect(summary.walletsCount, greaterThanOrEqualTo(1));

      // Verify that tasks exist in dest_acc
      final destTasks = await db.customSelect(
        'SELECT * FROM tasks WHERE account_id = ?',
        variables: [Variable('dest_acc')],
      ).get();
      expect(destTasks.length, 1);
      expect(destTasks.first.read<String>('title'), 'Migrated Task 1');

      // Verify that wallet exists in dest_acc
      final destWallets = await db.customSelect(
        'SELECT * FROM wallets WHERE account_id = ?',
        variables: [Variable('dest_acc')],
      ).get();
      expect(destWallets.length, 1);
      expect(destWallets.first.read<String>('name'), 'Savings');
    });
  });
}

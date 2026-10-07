import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

/// MyDay Drift Database with SQLite engine
class MyDayDatabase extends GeneratedDatabase {
  MyDayDatabase(super.executor);

  factory MyDayDatabase.create({bool inMemory = false}) {
    if (inMemory) {
      return MyDayDatabase(NativeDatabase.memory());
    }
    return MyDayDatabase(LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File('${dbFolder.path}/myday_production.sqlite');
      return NativeDatabase(file);
    }));
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => [];

  @override
  int get schemaVersion => 1;

  Future<void> initDatabase() async {
    await customStatement('PRAGMA foreign_keys = ON;');

    // 1. Accounts
    await customStatement('''
      CREATE TABLE IF NOT EXISTS local_accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        pin_hash TEXT NOT NULL,
        bio_enabled INTEGER NOT NULL DEFAULT 1,
        is_cloud INTEGER NOT NULL DEFAULT 0,
        handle TEXT NOT NULL DEFAULT 'me',
        bio TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL
      );
    ''');

    // 2. Tasks
    await customStatement('''
      CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        kind TEXT NOT NULL DEFAULT 'todo',
        title TEXT NOT NULL,
        min_duration INTEGER NOT NULL DEFAULT 0,
        duration_left_ms INTEGER NOT NULL DEFAULT 0,
        due_date TEXT NOT NULL,
        is_important INTEGER NOT NULL DEFAULT 0,
        is_done INTEGER NOT NULL DEFAULT 0,
        done_at INTEGER,
        repeat_interval TEXT NOT NULL DEFAULT 'none',
        spawned INTEGER NOT NULL DEFAULT 0,
        tags_json TEXT NOT NULL DEFAULT '[]',
        note TEXT NOT NULL DEFAULT '',
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    // 3. Notes
    await customStatement('''
      CREATE TABLE IF NOT EXISTS notes (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        body TEXT NOT NULL DEFAULT '',
        is_pinned INTEGER NOT NULL DEFAULT 0,
        color_index INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    // 4. Wallets
    await customStatement('''
      CREATE TABLE IF NOT EXISTS wallets (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        name TEXT NOT NULL,
        currency TEXT NOT NULL DEFAULT 'Rs',
        initial_balance INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    // 5. Transactions
    await customStatement('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        wallet_id TEXT NOT NULL,
        to_wallet_id TEXT,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        amount INTEGER NOT NULL,
        transaction_time INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    // 6. Budgets
    await customStatement('''
      CREATE TABLE IF NOT EXISTS budgets (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        category TEXT NOT NULL,
        monthly_limit INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    // 7. Feed Posts
    await customStatement('''
      CREATE TABLE IF NOT EXISTS feed_posts (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        text TEXT NOT NULL DEFAULT '',
        image_path TEXT NOT NULL DEFAULT '',
        is_liked INTEGER NOT NULL DEFAULT 0,
        is_saved INTEGER NOT NULL DEFAULT 0,
        comments_json TEXT NOT NULL DEFAULT '[]',
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    // 8. Stories
    await customStatement('''
      CREATE TABLE IF NOT EXISTS stories (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        image_path TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER
      );
    ''');

    // 9. Stored Files
    await customStatement('''
      CREATE TABLE IF NOT EXISTS stored_files (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        name TEXT NOT NULL,
        size_bytes INTEGER NOT NULL,
        local_path TEXT NOT NULL,
        share_type TEXT NOT NULL DEFAULT 'private',
        share_password TEXT,
        shared_with_json TEXT NOT NULL DEFAULT '[]',
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at INTEGER NOT NULL
      );
    ''');

    // Migration for stored_files sharing columns if already created
    try {
      await customStatement("ALTER TABLE stored_files ADD COLUMN share_type TEXT NOT NULL DEFAULT 'everyone'");
    } catch (_) {}
    try {
      await customStatement('ALTER TABLE stored_files ADD COLUMN share_password TEXT');
    } catch (_) {}
    try {
      await customStatement("ALTER TABLE stored_files ADD COLUMN shared_with_json TEXT NOT NULL DEFAULT '[]'");
    } catch (_) {}
    try {
      await customStatement("ALTER TABLE stored_files ADD COLUMN file_url TEXT NOT NULL DEFAULT ''");
    } catch (_) {}
    try {
      await customStatement("ALTER TABLE stored_files ADD COLUMN uploader_name TEXT NOT NULL DEFAULT ''");
    } catch (_) {}
    try {
      await customStatement("ALTER TABLE stored_files ADD COLUMN uploader_phone TEXT NOT NULL DEFAULT ''");
    } catch (_) {}

    // Migration for stories sync support
    try {
      await customStatement("ALTER TABLE stories ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'");
    } catch (_) {}
    try {
      await customStatement('ALTER TABLE stories ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0');
    } catch (_) {}
    try {
      await customStatement("ALTER TABLE stored_files ADD COLUMN pin TEXT NOT NULL DEFAULT ''");
    } catch (_) {}
    try {
      await customStatement("ALTER TABLE stored_files ADD COLUMN friend_phone_number TEXT NOT NULL DEFAULT ''");
    } catch (_) {}

    // 10. Chat Contacts (Stored strictly locally on user device)
    await customStatement('''
      CREATE TABLE IF NOT EXISTS chat_contacts (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        contact_key TEXT NOT NULL,
        nickname TEXT NOT NULL,
        avatar_color INTEGER NOT NULL DEFAULT 0,
        last_message TEXT NOT NULL DEFAULT '',
        last_message_time INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      );
    ''');

    // 11. Chat Messages (Stored strictly locally on user device, zero server retention)
    await customStatement('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        contact_key TEXT NOT NULL,
        sender_key TEXT NOT NULL,
        receiver_key TEXT NOT NULL,
        content TEXT NOT NULL DEFAULT '',
        media_path TEXT,
        media_type TEXT,
        is_outgoing INTEGER NOT NULL DEFAULT 1,
        status TEXT NOT NULL DEFAULT 'sent',
        timestamp INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // Perform 30-day retention cleanup on startup
    await cleanExpiredTrash();
  }

  /// 30-Day Retention Automatic Trash Purge
  /// Deletes records where is_deleted = 1 and deleted_at is older than 30 days,
  /// permanently removes files from disk, and reclaims space via SQLite VACUUM.
  Future<int> cleanExpiredTrash() async {
    final thirtyDaysAgoMs = DateTime.now()
        .subtract(const Duration(days: 30))
        .millisecondsSinceEpoch;

    // 1. Physically delete expired files and photos from disk
    try {
      final fileRows = await customSelect(
        'SELECT local_path FROM stored_files WHERE is_deleted = 1 AND deleted_at < ?',
        variables: [Variable(thirtyDaysAgoMs)],
      ).get();
      for (final r in fileRows) {
        final path = r.read<String?>('local_path');
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (f.existsSync()) await f.delete();
        }
      }

      final postRows = await customSelect(
        'SELECT image_path FROM feed_posts WHERE is_deleted = 1 AND deleted_at < ?',
        variables: [Variable(thirtyDaysAgoMs)],
      ).get();
      for (final r in postRows) {
        final path = r.read<String?>('image_path');
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (f.existsSync()) await f.delete();
        }
      }

      final storyRows = await customSelect(
        'SELECT image_path FROM stories WHERE is_deleted = 1 AND deleted_at < ?',
        variables: [Variable(thirtyDaysAgoMs)],
      ).get();
      for (final r in storyRows) {
        final path = r.read<String?>('image_path');
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (f.existsSync()) await f.delete();
        }
      }
    } catch (_) {}

    int purgedCount = 0;
    final tables = [
      'tasks',
      'notes',
      'wallets',
      'transactions',
      'budgets',
      'feed_posts',
      'stories',
      'stored_files',
    ];

    for (final table in tables) {
      final count = await customUpdate(
        'DELETE FROM $table WHERE is_deleted = 1 AND deleted_at < ?',
        variables: [Variable(thirtyDaysAgoMs)],
      );
      purgedCount += count;
    }

    if (purgedCount > 0) {
      try {
        await customStatement('VACUUM;');
      } catch (_) {}
    }

    return purgedCount;
  }

  /// Pure clean initialization for a new account without any hardcoded data
  Future<void> seedAccountData(String accountId) async {
    // Completely empty clean slate: no hardcoded wallets, tasks, notes, or transactions
  }

  /// Clears all user data for the account, wipes files on disk, and reclaims space
  Future<void> clearAllUserData(String accountId) async {
    try {
      final fileRows = await customSelect(
        'SELECT local_path FROM stored_files WHERE account_id = ?',
        variables: [Variable(accountId)],
      ).get();
      for (final r in fileRows) {
        final path = r.read<String?>('local_path');
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (f.existsSync()) await f.delete();
        }
      }

      final postRows = await customSelect(
        'SELECT image_path FROM feed_posts WHERE account_id = ?',
        variables: [Variable(accountId)],
      ).get();
      for (final r in postRows) {
        final path = r.read<String?>('image_path');
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (f.existsSync()) await f.delete();
        }
      }

      final storyRows = await customSelect(
        'SELECT image_path FROM stories WHERE account_id = ?',
        variables: [Variable(accountId)],
      ).get();
      for (final r in storyRows) {
        final path = r.read<String?>('image_path');
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (f.existsSync()) await f.delete();
        }
      }
    } catch (_) {}

    await customStatement('DELETE FROM tasks WHERE account_id = ?', [accountId]);
    await customStatement('DELETE FROM notes WHERE account_id = ?', [accountId]);
    await customStatement('DELETE FROM transactions WHERE account_id = ?', [accountId]);
    await customStatement('DELETE FROM budgets WHERE account_id = ?', [accountId]);
    await customStatement('DELETE FROM feed_posts WHERE account_id = ?', [accountId]);
    await customStatement('DELETE FROM stories WHERE account_id = ?', [accountId]);
    await customStatement('DELETE FROM stored_files WHERE account_id = ?', [accountId]);
    await customStatement('DELETE FROM wallets WHERE account_id = ?', [accountId]);
    await customStatement('DELETE FROM chat_contacts WHERE account_id = ?', [accountId]);
    await customStatement('DELETE FROM chat_messages WHERE account_id = ?', [accountId]);

    try {
      await customStatement('VACUUM;');
    } catch (_) {}
  }
}

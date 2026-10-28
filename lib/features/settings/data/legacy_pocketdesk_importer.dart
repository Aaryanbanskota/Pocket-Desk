import 'dart:io';
import 'package:drift/drift.dart' show Variable;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/myday_database.dart';
import '../../../core/security/secure_pin_service.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/data/services/password_hasher.dart';
import '../../calendar/data/models/calendar_event_model.dart';
import '../../calendar/data/models/calendar_model.dart';
import '../../feed/data/feed_repository.dart';
import '../../money_tracker/data/models/expense_model.dart';
import '../../money_tracker/data/models/wallet_model.dart';
import '../../notes/data/models/note_model.dart';
import '../../posts/data/models/instant_model.dart';
import '../../posts/data/models/post_model.dart';
import '../../settings/data/models/ai_settings_model.dart';
import '../../tasks/data/models/task_model.dart';
import '../../trash/data/models/trash_item_model.dart';

class LegacyImportSummary {
  final int tasksCount;
  final int notesCount;
  final int walletsCount;
  final int transactionsCount;
  final int postsCount;
  final int eventsCount;
  final String detectedUsername;

  const LegacyImportSummary({
    this.tasksCount = 0,
    this.notesCount = 0,
    this.walletsCount = 0,
    this.transactionsCount = 0,
    this.postsCount = 0,
    this.eventsCount = 0,
    this.detectedUsername = '',
  });

  int get totalItems =>
      tasksCount + notesCount + walletsCount + transactionsCount + postsCount + eventsCount;
}

/// Service to detect, verify credentials, and pull legacy Pocketdesk data
/// from both local Isar storage and SQLite production database.
class LegacyPocketdeskImporter {
  final MyDayDatabase db;
  static const _uuid = Uuid();

  LegacyPocketdeskImporter(this.db);

  /// Discovers all saved usernames strictly from old Pocketdesk storage
  Future<List<String>> detectOldPocketdeskUsernames({List<String> excludeNames = const []}) async {
    final Set<String> discovered = {};

    // 1. Check Isar database (The true offline storage of old Pocketdesk)
    try {
      final isar = await _openIsarSafely().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      if (isar != null) {
        final users = await isar.userModels.where().findAll();
        // Reverse to prioritize newer accounts first
        for (final u in users.reversed) {
          final uname = u.username.trim();
          if (uname.isNotEmpty && uname.toLowerCase() != 'me') {
            discovered.add(uname);
          }
        }
      }
    } catch (_) {}

    // 2. Check legacy preference keys strictly associated with old Pocketdesk
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        'legacy_pocketdesk_username',
        'old_pocketdesk_username',
        'pocket_desk_username',
        'last_username',
      ]) {
        final val = prefs.getString(key);
        if (val != null && val.trim().isNotEmpty && val.trim().toLowerCase() != 'me') {
          discovered.add(val.trim());
        }
      }
    } catch (_) {}

    // 3. Exclude any current MyDay local or cloud accounts to avoid false positives!
    final Set<String> toExclude = excludeNames.map((e) => e.trim().toLowerCase()).toSet();
    try {
      final currentAccounts = await db.customSelect('SELECT name, handle, email FROM local_accounts').get();
      for (final row in currentAccounts) {
        final n = row.read<String?>('name')?.trim().toLowerCase();
        final h = row.read<String?>('handle')?.trim().toLowerCase();
        final em = row.read<String?>('email')?.trim().toLowerCase();
        if (n != null && n.isNotEmpty) toExclude.add(n);
        if (h != null && h.isNotEmpty) toExclude.add(h);
        if (em != null && em.isNotEmpty) toExclude.add(em);
      }
    } catch (_) {}

    discovered.removeWhere((u) => toExclude.contains(u.toLowerCase()));

    return discovered.toList();
  }

  /// Automatically discovers saved username strictly from old Pocketdesk storage.
  /// If [excludeUsername] is provided (e.g. current active account), it prioritizes
  /// other legacy accounts found in the old database.
  Future<String?> detectOldPocketdeskUsername({String? excludeUsername}) async {
    final all = await detectOldPocketdeskUsernames(
      excludeNames: excludeUsername != null ? [excludeUsername] : const [],
    );
    if (all.isEmpty) return null;
    return all.first;
  }

  /// Verifies entered password or PIN against saved credentials
  Future<bool> verifyCredentials({
    required String username,
    required String passwordOrPin,
  }) async {
    final cleanUser = username.trim();
    final cleanSecret = passwordOrPin.trim();

    // 1. Check Isar UserModel first (Argon2id + Salt for alphanumeric password)
    try {
      final isar = await _openIsarSafely();
      if (isar != null) {
        final user = await isar.userModels
            .where()
            .usernameEqualTo(cleanUser)
            .findFirst();
        if (user != null) {
          final isValid = await PasswordHasher.verify(
            cleanSecret,
            user.passwordHash,
            user.passwordSalt,
          );
          if (isValid) return true;
        }
      }
    } catch (_) {}

    // 2. Check SQLite local_accounts (4-digit PIN)
    try {
      final rows = await db.customSelect(
        'SELECT pin_hash FROM local_accounts WHERE name = ? OR handle = ? LIMIT 1',
        variables: [Variable(cleanUser), Variable(cleanUser)],
      ).get();

      if (rows.isNotEmpty) {
        final storedHash = rows.first.read<String>('pin_hash');
        if (SecurePinService.verifyPin(cleanSecret, storedHash)) {
          return true;
        }
      }
    } catch (_) {}

    // 3. Fallback: Check if PIN matches default/active PIN
    try {
      final testHash = SecurePinService.hashPin(cleanSecret);
      final rows = await db.customSelect(
        'SELECT id FROM local_accounts WHERE pin_hash = ? LIMIT 1',
        variables: [Variable(testHash)],
      ).get();
      if (rows.isNotEmpty) return true;
    } catch (_) {}

    return false;
  }

  /// Fetches all old Pocketdesk data and integrates it into the target account
  Future<LegacyImportSummary> pullOldPocketdeskData({
    required String targetAccountId,
    required String username,
  }) async {
    int tasksCount = 0;
    int notesCount = 0;
    int walletsCount = 0;
    int transactionsCount = 0;
    int postsCount = 0;
    int eventsCount = 0;

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // 1. Pull data from SQLite (other local accounts or existing records)
    try {
      // Find other accounts if any
      final otherAccounts = await db.customSelect(
        'SELECT id FROM local_accounts WHERE id != ?',
        variables: [Variable(targetAccountId)],
      ).get();

      for (final accRow in otherAccounts) {
        final oldAccId = accRow.read<String>('id');

        // Migrate Tasks
        final tasks = await db.customSelect(
          'SELECT * FROM tasks WHERE account_id = ? AND is_deleted = 0',
          variables: [Variable(oldAccId)],
        ).get();
        for (final t in tasks) {
          final newId = _uuid.v4().substring(0, 8);
          await db.customInsert(
            '''
            INSERT INTO tasks (
              id, account_id, kind, title, min_duration, duration_left_ms, due_date,
              is_important, is_done, done_at, repeat_interval, spawned, tags_json,
              note, is_deleted, sync_status, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 'pending', ?, ?)
            ''',
            variables: [
              Variable(newId),
              Variable(targetAccountId),
              Variable(t.read<String>('kind')),
              Variable(t.read<String>('title')),
              Variable(t.read<int>('min_duration')),
              Variable(t.read<int>('duration_left_ms')),
              Variable(t.read<String>('due_date')),
              Variable(t.read<int>('is_important')),
              Variable(t.read<int>('is_done')),
              Variable(t.read<int?>('done_at')),
              Variable(t.read<String>('repeat_interval')),
              Variable(t.read<int>('spawned')),
              Variable(t.read<String>('tags_json')),
              Variable(t.read<String>('note')),
              Variable(nowMs),
              Variable(nowMs),
            ],
          );
          tasksCount++;
        }

        // Migrate Notes
        final notes = await db.customSelect(
          'SELECT * FROM notes WHERE account_id = ? AND is_deleted = 0',
          variables: [Variable(oldAccId)],
        ).get();
        for (final n in notes) {
          final newId = _uuid.v4().substring(0, 8);
          await db.customInsert(
            '''
            INSERT INTO notes (
              id, account_id, title, body, is_pinned, color_index, is_deleted,
              sync_status, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, 0, 'pending', ?, ?)
            ''',
            variables: [
              Variable(newId),
              Variable(targetAccountId),
              Variable(n.read<String>('title')),
              Variable(n.read<String>('body')),
              Variable(n.read<int>('is_pinned')),
              Variable(n.read<int>('color_index')),
              Variable(nowMs),
              Variable(nowMs),
            ],
          );
          notesCount++;
        }

        // Migrate Wallets
        final wallets = await db.customSelect(
          'SELECT * FROM wallets WHERE account_id = ? AND is_deleted = 0',
          variables: [Variable(oldAccId)],
        ).get();
        for (final w in wallets) {
          final newId = _uuid.v4().substring(0, 8);
          await db.customInsert(
            '''
            INSERT INTO wallets (
              id, account_id, name, currency, initial_balance, is_archived,
              is_deleted, sync_status, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, 0, 'pending', ?, ?)
            ''',
            variables: [
              Variable(newId),
              Variable(targetAccountId),
              Variable(w.read<String>('name')),
              Variable(w.read<String>('currency')),
              Variable(w.read<int>('initial_balance')),
              Variable(w.read<int>('is_archived')),
              Variable(nowMs),
              Variable(nowMs),
            ],
          );
          walletsCount++;
        }

        // Migrate Feed Posts
        final posts = await db.customSelect(
          'SELECT * FROM feed_posts WHERE account_id = ? AND is_deleted = 0',
          variables: [Variable(oldAccId)],
        ).get();
        for (final p in posts) {
          final newId = _uuid.v4().substring(0, 8);
          await db.customInsert(
            '''
            INSERT INTO feed_posts (
              id, account_id, text, image_path, is_liked, is_saved, comments_json,
              is_deleted, sync_status, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 'pending', ?, ?)
            ''',
            variables: [
              Variable(newId),
              Variable(targetAccountId),
              Variable(p.read<String>('text')),
              Variable(p.read<String>('image_path')),
              Variable(p.read<int>('is_liked')),
              Variable(p.read<int>('is_saved')),
              Variable(p.read<String>('comments_json')),
              Variable(nowMs),
              Variable(nowMs),
            ],
          );
          postsCount++;
        }
      }
    } catch (_) {}

    // 2. Pull data from Isar database (pocketdesk.isar)
    try {
      final isar = await _openIsarSafely();
      if (isar != null) {
        final allUsers = await isar.userModels.where().findAll();
        UserModel? matchingUser;
        for (final u in allUsers) {
          if (u.username.trim().toLowerCase() == username.trim().toLowerCase()) {
            matchingUser = u;
            break;
          }
        }
        final targetUserId = matchingUser?.id;
        final hasUserFilter = targetUserId != null && allUsers.length > 1;
        bool matchesUser(int? itemUserId) {
          if (!hasUserFilter) return true;
          if (itemUserId == null || itemUserId == 0) return true;
          return itemUserId == targetUserId;
        }

        // A. Isar Tasks
        final isarTasks = await isar.taskModels.where().findAll();
        for (final it in isarTasks) {
          if (!matchesUser(it.userId)) continue;
          final newId = _uuid.v4().substring(0, 8);
          final dueDateStr = it.dueDate != null
              ? '${it.dueDate!.year}-${it.dueDate!.month.toString().padLeft(2, '0')}-${it.dueDate!.day.toString().padLeft(2, '0')}'
              : '2026-10-19';
          final isDone = it.status == TaskStatus.done;

          await db.customInsert(
            '''
            INSERT INTO tasks (
              id, account_id, kind, title, min_duration, duration_left_ms, due_date,
              is_important, is_done, repeat_interval, spawned, tags_json, note,
              is_deleted, sync_status, created_at, updated_at
            ) VALUES (?, ?, 'todo', ?, 0, 0, ?, ?, ?, 'none', 0, '[]', ?, 0, 'pending', ?, ?)
            ''',
            variables: [
              Variable(newId),
              Variable(targetAccountId),
              Variable(it.title),
              Variable(dueDateStr),
              Variable(it.priority == TaskPriority.high || it.priority == TaskPriority.urgent ? 1 : 0),
              Variable(isDone ? 1 : 0),
              Variable(it.description ?? ''),
              Variable(nowMs),
              Variable(nowMs),
            ],
          );
          tasksCount++;
        }

        // B. Isar Notes
        final isarNotes = await isar.noteModels.where().findAll();
        for (final inote in isarNotes) {
          if (!matchesUser(inote.userId)) continue;
          final newId = _uuid.v4().substring(0, 8);
          await db.customInsert(
            '''
            INSERT INTO notes (
              id, account_id, title, body, is_pinned, color_index, is_deleted,
              sync_status, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, 0, 0, 'pending', ?, ?)
            ''',
            variables: [
              Variable(newId),
              Variable(targetAccountId),
              Variable(inote.title),
              Variable(inote.content),
              Variable(inote.isPinned ? 1 : 0),
              Variable(nowMs),
              Variable(nowMs),
            ],
          );
          notesCount++;
        }

        // C. Isar Wallets
        final isarWallets = await isar.walletModels.where().findAll();
        for (final iw in isarWallets) {
          if (!matchesUser(iw.userId)) continue;
          final newId = _uuid.v4().substring(0, 8);
          await db.customInsert(
            '''
            INSERT INTO wallets (
              id, account_id, name, currency, initial_balance, is_archived,
              is_deleted, sync_status, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, 0, 0, 'pending', ?, ?)
            ''',
            variables: [
              Variable(newId),
              Variable(targetAccountId),
              Variable(iw.name),
              Variable(iw.currency),
              Variable((iw.balance * 100).round()),
              Variable(nowMs),
              Variable(nowMs),
            ],
          );
          walletsCount++;
        }

        // D. Isar Expenses
        final isarExpenses = await isar.expenseModels.where().findAll();
        for (final ie in isarExpenses) {
          if (!matchesUser(ie.userId)) continue;
          final newId = _uuid.v4().substring(0, 8);
          await db.customInsert(
            '''
            INSERT INTO transactions (
              id, account_id, wallet_id, type, category, amount, transaction_time,
              note, is_deleted, sync_status, created_at, updated_at
            ) VALUES (?, ?, '', 'Expense', ?, ?, ?, ?, 0, 'pending', ?, ?)
            ''',
            variables: [
              Variable(newId),
              Variable(targetAccountId),
              Variable(ie.category),
              Variable((ie.amount * 100).round()),
              Variable(ie.createdAt.millisecondsSinceEpoch),
              Variable(ie.title),
              Variable(nowMs),
              Variable(nowMs),
            ],
          );
          transactionsCount++;
        }

        // E. Isar Calendar Events -> Integrated as Event Tasks
        final isarEvents = await isar.calendarEventModels.where().findAll();
        for (final ev in isarEvents) {
          if (!matchesUser(ev.userId)) continue;
          final newId = _uuid.v4().substring(0, 8);
          final dueDateStr =
              '${ev.startTime.year}-${ev.startTime.month.toString().padLeft(2, '0')}-${ev.startTime.day.toString().padLeft(2, '0')}';
          await db.customInsert(
            '''
            INSERT INTO tasks (
              id, account_id, kind, title, min_duration, duration_left_ms, due_date,
              is_important, is_done, repeat_interval, spawned, tags_json, note,
              is_deleted, sync_status, created_at, updated_at
            ) VALUES (?, ?, 'event', ?, 0, 0, ?, 0, 0, 'none', 0, '["event"]', ?, 0, 'pending', ?, ?)
            ''',
            variables: [
              Variable(newId),
              Variable(targetAccountId),
              Variable(ev.title),
              Variable(dueDateStr),
              Variable(ev.description ?? ''),
              Variable(nowMs),
              Variable(nowMs),
            ],
          );
          eventsCount++;
        }

        // F. Isar Posts
        final isarPosts = await isar.postModels.where().findAll();
        for (final ip in isarPosts) {
          if (!matchesUser(ip.userId)) continue;
          final newId = _uuid.v4().substring(0, 8);
          var imgPath = ip.imagePaths.isNotEmpty ? ip.imagePaths.first : '';
          if (imgPath.isNotEmpty) {
            imgPath = await FeedRepository.persistMediaFile(imgPath);
          }
          await db.customInsert(
            '''
            INSERT INTO feed_posts (
              id, account_id, text, image_path, is_liked, is_saved, comments_json,
              is_deleted, sync_status, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, '[]', 0, 'pending', ?, ?)
            ''',
            variables: [
              Variable(newId),
              Variable(targetAccountId),
              Variable(ip.content),
              Variable(imgPath),
              Variable(ip.isLiked ? 1 : 0),
              Variable(ip.isSaved ? 1 : 0),
              Variable(nowMs),
              Variable(nowMs),
            ],
          );
          postsCount++;
        }
      }
    } catch (_) {}

    return LegacyImportSummary(
      tasksCount: tasksCount,
      notesCount: notesCount,
      walletsCount: walletsCount,
      transactionsCount: transactionsCount,
      postsCount: postsCount,
      eventsCount: eventsCount,
      detectedUsername: username,
    );
  }

  /// Opens Isar safely, checking active instances, documents dir, support dir and local directory
  Future<Isar?> _openIsarSafely() async {
    try {
      for (final instanceName in ['pocketdesk', 'default', 'phone_pocketdesk']) {
        final existing = Isar.getInstance(instanceName);
        if (existing != null && existing.isOpen) {
          return existing;
        }
      }

      String? docDirPath;
      String? supportDirPath;
      try {
        final docDir = await getApplicationDocumentsDirectory();
        docDirPath = docDir.path;
      } catch (_) {}
      try {
        final supportDir = await getApplicationSupportDirectory();
        supportDirPath = supportDir.path;
      } catch (_) {}

      final candidateDirs = [
        if (docDirPath != null) docDirPath,
        if (supportDirPath != null) supportDirPath,
        '/data/user/0/com.pocketdesk.pocketdesk/app_flutter',
        '/data/user/0/com.pocketdesk.pocketdesk/files',
        '/data/user/0/com.pocketdesk.pocketdesk/databases',
        Directory.current.path,
      ];

      try {
        await Isar.initializeIsarCore(download: false);
      } catch (_) {}

      for (final dir in candidateDirs) {
        for (final isarName in ['pocketdesk', 'default']) {
          final isarFile = File('$dir/$isarName.isar');
          if (isarFile.existsSync()) {
            try {
              return await Isar.open(
                [
                  UserModelSchema,
                  CalendarEventModelSchema,
                  CalendarModelSchema,
                  TaskModelSchema,
                  NoteModelSchema,
                  WalletModelSchema,
                  ExpenseModelSchema,
                  PostModelSchema,
                  InstantModelSchema,
                  AISettingsModelSchema,
                  TrashItemModelSchema,
                ],
                directory: dir,
                name: isarName,
                inspector: false,
              ).timeout(const Duration(seconds: 2));
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return null;
  }
}

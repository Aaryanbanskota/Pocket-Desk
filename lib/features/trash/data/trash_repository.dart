import 'dart:io';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/myday_database.dart';

enum TrashItemType {
  task,
  note,
  transaction,
  feed,
  file,
}

class MyDayTrashItem {
  final String id;
  final TrashItemType type;
  final String title;
  final int deletedAt; // milliseconds since epoch
  final String subtitle;

  const MyDayTrashItem({
    required this.id,
    required this.type,
    required this.title,
    required this.deletedAt,
    required this.subtitle,
  });

  int get daysRemaining {
    final deletedDate = DateTime.fromMillisecondsSinceEpoch(deletedAt);
    final expiryDate = deletedDate.add(const Duration(days: 30));
    final diff = expiryDate.difference(DateTime.now()).inDays;
    return diff.clamp(0, 30);
  }
}

class TrashRepository {
  final MyDayDatabase db;

  TrashRepository(this.db);

  /// Retrieves all soft-deleted records across all entity types for the account
  Future<List<MyDayTrashItem>> getTrashItems(String accountId) async {
    // 0. Auto-clean expired trash (>30 days old) physically from local DB & cloud
    await db.cleanExpiredTrash();

    final List<MyDayTrashItem> items = [];

    // 1. Tasks
    final tasks = await db.customSelect(
      'SELECT id, title, kind, deleted_at FROM tasks WHERE account_id = ? AND is_deleted = 1 ORDER BY deleted_at DESC',
      variables: [Variable(accountId)],
    ).get();

    for (final t in tasks) {
      items.add(
        MyDayTrashItem(
          id: t.read<String>('id'),
          type: TrashItemType.task,
          title: t.read<String>('title'),
          deletedAt: t.read<int?>('deleted_at') ?? DateTime.now().millisecondsSinceEpoch,
          subtitle: 'Task · ${t.read<String>('kind')}',
        ),
      );
    }

    // 2. Notes
    final notes = await db.customSelect(
      'SELECT id, title, body, deleted_at FROM notes WHERE account_id = ? AND is_deleted = 1 ORDER BY deleted_at DESC',
      variables: [Variable(accountId)],
    ).get();

    for (final n in notes) {
      final title = n.read<String>('title');
      final body = n.read<String>('body');
      items.add(
        MyDayTrashItem(
          id: n.read<String>('id'),
          type: TrashItemType.note,
          title: title.isNotEmpty ? title : (body.isNotEmpty ? body.split('\n').first : 'Untitled Note'),
          deletedAt: n.read<int?>('deleted_at') ?? DateTime.now().millisecondsSinceEpoch,
          subtitle: 'Note',
        ),
      );
    }

    // 3. Transactions
    final txs = await db.customSelect(
      'SELECT id, note, category, type, amount, deleted_at FROM transactions WHERE account_id = ? AND is_deleted = 1 ORDER BY deleted_at DESC',
      variables: [Variable(accountId)],
    ).get();

    for (final tx in txs) {
      final note = tx.read<String>('note');
      final cat = tx.read<String>('category');
      items.add(
        MyDayTrashItem(
          id: tx.read<String>('id'),
          type: TrashItemType.transaction,
          title: note.isNotEmpty ? note : cat,
          deletedAt: tx.read<int?>('deleted_at') ?? DateTime.now().millisecondsSinceEpoch,
          subtitle: '${tx.read<String>('type')} · $cat',
        ),
      );
    }

    // 4. Feed Posts
    final posts = await db.customSelect(
      'SELECT id, text, deleted_at FROM feed_posts WHERE account_id = ? AND is_deleted = 1 ORDER BY deleted_at DESC',
      variables: [Variable(accountId)],
    ).get();

    for (final p in posts) {
      items.add(
        MyDayTrashItem(
          id: p.read<String>('id'),
          type: TrashItemType.feed,
          title: p.read<String>('text').isNotEmpty ? p.read<String>('text') : 'Photo post',
          deletedAt: p.read<int?>('deleted_at') ?? DateTime.now().millisecondsSinceEpoch,
          subtitle: 'Post',
        ),
      );
    }

    // Sort all trash items by deletion date descending
    items.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return items;
  }

  /// Restores a soft-deleted item back to active state
  Future<void> restoreItem(MyDayTrashItem item) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    String table;

    switch (item.type) {
      case TrashItemType.task:
        table = 'tasks';
        break;
      case TrashItemType.note:
        table = 'notes';
        break;
      case TrashItemType.transaction:
        table = 'transactions';
        break;
      case TrashItemType.feed:
        table = 'feed_posts';
        break;
      case TrashItemType.file:
        table = 'stored_files';
        break;
    }

    if (item.type == TrashItemType.file) {
      await db.customUpdate(
        "UPDATE stored_files SET is_deleted = 0, deleted_at = NULL, sync_status = 'pending' WHERE id = ?",
        variables: [Variable(item.id)],
      );
    } else {
      await db.customUpdate(
        "UPDATE $table SET is_deleted = 0, deleted_at = NULL, sync_status = 'pending', updated_at = ? WHERE id = ?",
        variables: [Variable(nowMs), Variable(item.id)],
      );
    }
  }

  /// Soft deletes an item back into trash (used for Undo)
  Future<void> reTrashItem(MyDayTrashItem item) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    String table;
    switch (item.type) {
      case TrashItemType.task:
        table = 'tasks';
        break;
      case TrashItemType.note:
        table = 'notes';
        break;
      case TrashItemType.transaction:
        table = 'transactions';
        break;
      case TrashItemType.feed:
        table = 'feed_posts';
        break;
      case TrashItemType.file:
        table = 'stored_files';
        break;
    }

    await db.customUpdate(
      "UPDATE $table SET is_deleted = 1, deleted_at = ?, sync_status = 'pending' WHERE id = ?",
      variables: [Variable(nowMs), Variable(item.id)],
    );
  }

  /// Permanently purges an item, physical files on device disk, and reclaims storage via SQLite VACUUM
  Future<void> permanentlyDeleteItem(MyDayTrashItem item) async {
    String table;
    switch (item.type) {
      case TrashItemType.task:
        table = 'tasks';
        break;
      case TrashItemType.note:
        table = 'notes';
        break;
      case TrashItemType.transaction:
        table = 'transactions';
        break;
      case TrashItemType.feed:
        table = 'feed_posts';
        break;
      case TrashItemType.file:
        table = 'stored_files';
        break;
    }

    // 1. Physically delete file attachments from the device filesystem to reclaim storage space
    if (item.type == TrashItemType.file) {
      try {
        final rows = await db.customSelect(
          'SELECT local_path FROM stored_files WHERE id = ?',
          variables: [Variable(item.id)],
        ).get();
        for (final r in rows) {
          final path = r.read<String?>('local_path');
          if (path != null && path.isNotEmpty) {
            final f = File(path);
            if (f.existsSync()) {
              await f.delete();
            }
          }
        }
      } catch (_) {}
    } else if (item.type == TrashItemType.feed) {
      try {
        final rows = await db.customSelect(
          'SELECT image_path FROM feed_posts WHERE id = ?',
          variables: [Variable(item.id)],
        ).get();
        for (final r in rows) {
          final path = r.read<String?>('image_path');
          if (path != null && path.isNotEmpty) {
            final f = File(path);
            if (f.existsSync()) {
              await f.delete();
            }
          }
        }
      } catch (_) {}
    }

    // 2. Delete permanently from local SQLite database
    await db.customUpdate(
      'DELETE FROM $table WHERE id = ?',
      variables: [Variable(item.id)],
    );

    // 3. Immediately reclaim SQLite allocated disk space so DB file shrinks
    try {
      await db.customStatement('VACUUM;');
    } catch (_) {}

    // 4. Delete permanently from Supabase cloud if user is authenticated
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession != null) {
        await client.from(table).delete().eq('id', item.id);
      }
    } catch (_) {}
  }

  /// Empties all items currently in trash, physically deletes stored files on disk, and reclaims space
  Future<void> emptyAllTrash(String accountId) async {
    // 1. Physically delete all stored files from the device filesystem
    try {
      final fileRows = await db.customSelect(
        'SELECT local_path FROM stored_files WHERE account_id = ? AND is_deleted = 1',
        variables: [Variable(accountId)],
      ).get();
      for (final r in fileRows) {
        final path = r.read<String?>('local_path');
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (f.existsSync()) {
            await f.delete();
          }
        }
      }
    } catch (_) {}

    // 2. Physically delete all feed post photos & story images from disk
    try {
      final postRows = await db.customSelect(
        'SELECT image_path FROM feed_posts WHERE account_id = ? AND is_deleted = 1',
        variables: [Variable(accountId)],
      ).get();
      for (final r in postRows) {
        final path = r.read<String?>('image_path');
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (f.existsSync()) {
            await f.delete();
          }
        }
      }

      final storyRows = await db.customSelect(
        'SELECT image_path FROM stories WHERE account_id = ? AND is_deleted = 1',
        variables: [Variable(accountId)],
      ).get();
      for (final r in storyRows) {
        final path = r.read<String?>('image_path');
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (f.existsSync()) {
            await f.delete();
          }
        }
      }
    } catch (_) {}

    // 3. Delete from SQLite tables
    final tables = ['tasks', 'notes', 'transactions', 'budgets', 'feed_posts', 'stories', 'stored_files'];
    for (final table in tables) {
      await db.customUpdate(
        'DELETE FROM $table WHERE account_id = ? AND is_deleted = 1',
        variables: [Variable(accountId)],
      );
    }

    // 4. Run SQLite VACUUM to physically shrink database file and reclaim device storage
    try {
      await db.customStatement('VACUUM;');
    } catch (_) {}

    // 5. Permanently purge soft-deleted records from Supabase cloud as well
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession != null) {
        for (final table in ['tasks', 'notes', 'wallets', 'transactions', 'feed_posts', 'stories', 'stored_files']) {
          await client.from(table).delete().eq('is_deleted', true);
        }
      }
    } catch (_) {}
  }
}

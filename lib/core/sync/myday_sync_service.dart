import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/myday_database.dart';
import '../logging/app_logger.dart';
import '../services/supabase_auth_service.dart';

enum SyncStatus {
  idle,
  syncing,
  offline,
  error,
}

class MyDaySyncService {
  final MyDayDatabase db;
  SyncStatus _status = SyncStatus.idle;
  String? _lastError;
  bool _isSyncing = false;

  Timer? _debounceTimer;
  DateTime? _lastSyncTimestamp;
  static const Duration _debounceDuration = Duration(seconds: 2);
  static const Duration _minCooldown = Duration(seconds: 2);

  MyDaySyncService(this.db);

  SyncStatus get status => _status;
  String? get lastError => _lastError;

  bool get isSupabaseConfigured {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
  }

  /// Schedule a debounced sync when changes happen locally.
  /// Never calls Supabase on every keystroke or rapid event.
  void scheduleDebouncedSync(String accountId) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      syncPendingRecords(accountId);
    });
  }

  /// Upgrades a local account to a Cloud Supabase account
  Future<bool> upgradeLocalToCloud({
    required String localAccountId,
    required String cloudUserId,
    required String cloudEmail,
  }) async {
    _status = SyncStatus.syncing;

    try {
      await db.customUpdate(
        '''
        UPDATE local_accounts
        SET is_cloud = 1, email = ?, id = ?
        WHERE id = ?
        ''',
        variables: [
          Variable(cloudEmail),
          Variable(cloudUserId),
          Variable(localAccountId),
        ],
      );

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
        await db.customUpdate(
          "UPDATE $table SET account_id = ?, sync_status = 'pending' WHERE account_id = ?",
          variables: [
            Variable(cloudUserId),
            Variable(localAccountId),
          ],
        );
      }

      _status = SyncStatus.idle;
      scheduleDebouncedSync(cloudUserId);
      return true;
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      return false;
    }
  }

  /// Synchronize pending changes to Supabase in bulk batches.
  /// Saves quota by sending one single batch per entity rather than separate HTTP calls.
  Future<void> syncPendingRecords(String accountId, {bool force = false}) async {
    if (!isSupabaseConfigured) {
      _status = SyncStatus.offline;
      return;
    }

    if (_isSyncing) return;

    // Rate-limit cooldown to preserve database quota
    if (!force && _lastSyncTimestamp != null) {
      if (DateTime.now().difference(_lastSyncTimestamp!) < _minCooldown) {
        return;
      }
    }

    _isSyncing = true;
    _status = SyncStatus.syncing;
    _debounceTimer?.cancel();

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id ?? accountId;

      // 1. Sync tasks (Batched in bulk)
      final pendingTasks = await db.customSelect(
        "SELECT * FROM tasks WHERE account_id = ? AND sync_status = 'pending'",
        variables: [Variable(accountId)],
      ).get();

      if (pendingTasks.isNotEmpty) {
        final taskBatch = pendingTasks.map((task) {
          return {
            'id': task.read<String>('id'),
            'user_id': userId,
            'title': task.read<String>('title'),
            'kind': task.read<String>('kind'),
            'min_duration': task.read<int>('min_duration'),
            'duration_left_ms': task.read<int>('duration_left_ms'),
            'due_date': task.read<String>('due_date'),
            'is_done': task.read<int>('is_done') == 1,
            'is_important': task.read<int>('is_important') == 1,
            'tags': task.read<String>('tags_json'),
            'note': task.read<String>('note'),
            'is_deleted': task.read<int>('is_deleted') == 1,
            'updated_at': DateTime.fromMillisecondsSinceEpoch(
              task.read<int>('updated_at'),
            ).toIso8601String(),
          };
        }).toList();

        await client.from('tasks').upsert(taskBatch);

        // Mark as synced locally
        for (final task in pendingTasks) {
          await db.customUpdate(
            "UPDATE tasks SET sync_status = 'synced' WHERE id = ?",
            variables: [Variable(task.read<String>('id'))],
          );
        }
      }

      // 2. Sync notes (Batched in bulk)
      final pendingNotes = await db.customSelect(
        "SELECT * FROM notes WHERE account_id = ? AND sync_status = 'pending'",
        variables: [Variable(accountId)],
      ).get();

      if (pendingNotes.isNotEmpty) {
        final noteBatch = pendingNotes.map((note) {
          return {
            'id': note.read<String>('id'),
            'user_id': userId,
            'title': note.read<String>('title'),
            'body': note.read<String>('body'),
            'is_pinned': note.read<int>('is_pinned') == 1,
            'color_index': note.read<int>('color_index'),
            'is_deleted': note.read<int>('is_deleted') == 1,
            'updated_at': DateTime.fromMillisecondsSinceEpoch(
              note.read<int>('updated_at'),
            ).toIso8601String(),
          };
        }).toList();

        await client.from('notes').upsert(noteBatch);

        for (final note in pendingNotes) {
          await db.customUpdate(
            "UPDATE notes SET sync_status = 'synced' WHERE id = ?",
            variables: [Variable(note.read<String>('id'))],
          );
        }
      }

      // 3. Sync wallets (Batched in bulk)
      final pendingWallets = await db.customSelect(
        "SELECT * FROM wallets WHERE account_id = ? AND sync_status = 'pending'",
        variables: [Variable(accountId)],
      ).get();

      if (pendingWallets.isNotEmpty) {
        final walletBatch = pendingWallets.map((w) {
          return {
            'id': w.read<String>('id'),
            'user_id': userId,
            'name': w.read<String>('name'),
            'currency': w.read<String>('currency'),
            'initial_balance': w.read<int>('initial_balance'),
            'is_archived': w.read<int>('is_archived') == 1,
            'is_deleted': w.read<int>('is_deleted') == 1,
          };
        }).toList();

        await client.from('wallets').upsert(walletBatch);

        for (final w in pendingWallets) {
          await db.customUpdate(
            "UPDATE wallets SET sync_status = 'synced' WHERE id = ?",
            variables: [Variable(w.read<String>('id'))],
          );
        }
      }

      // 4. Sync transactions (Batched in bulk)
      final pendingTx = await db.customSelect(
        "SELECT * FROM transactions WHERE account_id = ? AND sync_status = 'pending'",
        variables: [Variable(accountId)],
      ).get();

      if (pendingTx.isNotEmpty) {
        final txBatch = pendingTx.map((tx) {
          return {
            'id': tx.read<String>('id'),
            'user_id': userId,
            'wallet_id': tx.read<String>('wallet_id'),
            'type': tx.read<String>('type'),
            'category': tx.read<String>('category'),
            'amount': tx.read<int>('amount'),
            'transaction_time': tx.read<int>('transaction_time'),
            'note': tx.read<String>('note'),
            'is_deleted': tx.read<int>('is_deleted') == 1,
          };
        }).toList();

        await client.from('transactions').upsert(txBatch);

        for (final tx in pendingTx) {
          await db.customUpdate(
            "UPDATE transactions SET sync_status = 'synced' WHERE id = ?",
            variables: [Variable(tx.read<String>('id'))],
          );
        }
      }

      // 5. Sync Budgets (Batched in bulk)
      final pendingBudgets = await db.customSelect(
        "SELECT * FROM budgets WHERE account_id = ? AND sync_status = 'pending'",
        variables: [Variable(accountId)],
      ).get();

      if (pendingBudgets.isNotEmpty) {
        final budgetBatch = pendingBudgets.map((b) {
          return {
            'id': b.read<String>('id'),
            'user_id': userId,
            'category': b.read<String>('category'),
            'monthly_limit': b.read<int>('monthly_limit'),
            'is_deleted': (b.read<int?>('is_deleted') ?? 0) == 1,
            'deleted_at': b.read<int?>('deleted_at'),
            'created_at': DateTime.fromMillisecondsSinceEpoch(
              b.read<int?>('created_at') ?? DateTime.now().millisecondsSinceEpoch,
            ).toIso8601String(),
            'updated_at': DateTime.fromMillisecondsSinceEpoch(
              b.read<int?>('updated_at') ?? DateTime.now().millisecondsSinceEpoch,
            ).toIso8601String(),
          };
        }).toList();

        await client.from('budgets').upsert(budgetBatch);

        for (final b in pendingBudgets) {
          await db.customUpdate(
            "UPDATE budgets SET sync_status = 'synced' WHERE id = ?",
            variables: [Variable(b.read<String>('id'))],
          );
        }
      }

      // 6. Sync Feed Posts (Batched with dedicated post_images bucket upload & cascade deletion)
      final pendingPosts = await db.customSelect(
        "SELECT * FROM feed_posts WHERE account_id = ? AND sync_status = 'pending'",
        variables: [Variable(accountId)],
      ).get();

      if (pendingPosts.isNotEmpty) {
        final activePosts = <QueryRow>[];
        final deletedPosts = <QueryRow>[];
        for (final p in pendingPosts) {
          if ((p.read<int?>('is_deleted') ?? 0) == 1) {
            deletedPosts.add(p);
          } else {
            activePosts.add(p);
          }
        }

        // 5a. Cascade Delete Removed Posts (Supabase database, post_images bucket, and local SQLite)
        for (final p in deletedPosts) {
          final postId = p.read<String>('id');
          final imgPath = p.read<String?>('image_path') ?? '';

          // 1. Delete from Supabase Database
          try {
            await client.from('feed_posts').delete().eq('id', postId);
          } catch (err) {
            AppLogger.w('Failed deleting remote feed_post $postId: $err');
          }

          // 2. Delete image from Storage buckets
          final candidateKeys = <String>[
            '$userId/feed/$postId.jpg',
            '$userId/feed/$postId.jpeg',
            '$userId/feed/$postId.png',
            '$userId/feed/$postId.webp',
          ];
          if (imgPath.contains('/post_images/')) {
            candidateKeys.add(imgPath.split('/post_images/').last);
          }
          if (imgPath.contains('/images_bucket/')) {
            candidateKeys.add(imgPath.split('/images_bucket/').last);
          }

          try {
            await client.storage.from('post_images').remove(candidateKeys);
          } catch (_) {}
          try {
            await client.storage.from('images_bucket').remove(candidateKeys);
          } catch (_) {}

          // 3. Delete local media file
          if (imgPath.isNotEmpty && !imgPath.startsWith('http')) {
            try {
              final localFile = File(imgPath);
              if (localFile.existsSync()) {
                localFile.deleteSync();
              }
            } catch (_) {}
          }

          // 4. Delete locally from SQLite
          await db.customStatement('DELETE FROM feed_posts WHERE id = ?', [postId]);
        }

        // 5b. Upsert Active Posts
        if (activePosts.isNotEmpty) {
          final postBatch = <Map<String, dynamic>>[];
          for (final p in activePosts) {
            final postId = p.read<String>('id');
            var imgPath = p.read<String?>('image_path') ?? '';
            var remoteUrl = imgPath;

            // Deterministic single upload to post_images bucket (prevents duplicate files)
            if (imgPath.isNotEmpty && !imgPath.startsWith('http') && File(imgPath).existsSync()) {
              try {
                final file = File(imgPath);
                final ext = imgPath.contains('.') ? imgPath.split('.').last : 'jpg';
                final storageKey = '$userId/feed/$postId.$ext';
                await client.storage.from('post_images').upload(
                  storageKey,
                  file,
                  fileOptions: const FileOptions(upsert: true),
                );
                remoteUrl = client.storage.from('post_images').getPublicUrl(storageKey);
              } catch (err) {
                AppLogger.w('Feed image upload non-fatal: $err');
              }
            }

            postBatch.add({
              'id': postId,
              'user_id': userId,
              'text': p.read<String?>('text') ?? '',
              'image_path': remoteUrl,
              'is_liked': (p.read<int?>('is_liked') ?? 0) == 1,
              'is_saved': (p.read<int?>('is_saved') ?? 0) == 1,
              'comments_json': p.read<String?>('comments_json') ?? '[]',
              'is_deleted': false,
              'deleted_at': null,
              'created_at': DateTime.fromMillisecondsSinceEpoch(
                p.read<int?>('created_at') ?? DateTime.now().millisecondsSinceEpoch,
              ).toIso8601String(),
              'updated_at': DateTime.fromMillisecondsSinceEpoch(
                p.read<int?>('updated_at') ?? DateTime.now().millisecondsSinceEpoch,
              ).toIso8601String(),
            });
          }

          if (postBatch.isNotEmpty) {
            await client.from('feed_posts').upsert(postBatch);
            for (final p in activePosts) {
              await db.customUpdate(
                "UPDATE feed_posts SET sync_status = 'synced' WHERE id = ?",
                variables: [Variable(p.read<String>('id'))],
              );
            }
          }
        }
      }

      // 6. Sync Stories / Instants (Batched with dedicated instance_images bucket upload & cascade deletion)
      final pendingStories = await db.customSelect(
        "SELECT * FROM stories WHERE account_id = ? AND (sync_status = 'pending' OR sync_status IS NULL)",
        variables: [Variable(accountId)],
      ).get();

      if (pendingStories.isNotEmpty) {
        final activeStories = <QueryRow>[];
        final deletedStories = <QueryRow>[];
        for (final s in pendingStories) {
          if ((s.read<int?>('is_deleted') ?? 0) == 1) {
            deletedStories.add(s);
          } else {
            activeStories.add(s);
          }
        }

        // 6a. Cascade Delete Removed Stories (Supabase database, instance_images bucket, and local SQLite)
        for (final s in deletedStories) {
          final storyId = s.read<String>('id');
          final imgPath = s.read<String?>('image_path') ?? '';

          try {
            await client.from('stories').delete().eq('id', storyId);
          } catch (err) {
            AppLogger.w('Failed deleting remote story $storyId: $err');
          }

          final candidateKeys = <String>[
            '$userId/stories/$storyId.jpg',
            '$userId/stories/$storyId.jpeg',
            '$userId/stories/$storyId.png',
            '$userId/stories/$storyId.webp',
          ];
          if (imgPath.contains('/instance_images/')) {
            candidateKeys.add(imgPath.split('/instance_images/').last);
          }
          if (imgPath.contains('/images_bucket/')) {
            candidateKeys.add(imgPath.split('/images_bucket/').last);
          }

          try {
            await client.storage.from('instance_images').remove(candidateKeys);
          } catch (_) {}
          try {
            await client.storage.from('images_bucket').remove(candidateKeys);
          } catch (_) {}

          if (imgPath.isNotEmpty && !imgPath.startsWith('http')) {
            try {
              final localFile = File(imgPath);
              if (localFile.existsSync()) {
                localFile.deleteSync();
              }
            } catch (_) {}
          }

          await db.customStatement('DELETE FROM stories WHERE id = ?', [storyId]);
        }

        // 6b. Upsert Active Stories
        if (activeStories.isNotEmpty) {
          final storyBatch = <Map<String, dynamic>>[];
          for (final s in activeStories) {
            final storyId = s.read<String>('id');
            var imgPath = s.read<String?>('image_path') ?? '';
            var remoteUrl = imgPath;

            // Deterministic single upload to instance_images bucket
            if (imgPath.isNotEmpty && !imgPath.startsWith('http') && File(imgPath).existsSync()) {
              try {
                final file = File(imgPath);
                final ext = imgPath.contains('.') ? imgPath.split('.').last : 'jpg';
                final storageKey = '$userId/stories/$storyId.$ext';
                await client.storage.from('instance_images').upload(
                  storageKey,
                  file,
                  fileOptions: const FileOptions(upsert: true),
                );
                remoteUrl = client.storage.from('instance_images').getPublicUrl(storageKey);
              } catch (err) {
                AppLogger.w('Story image upload non-fatal: $err');
              }
            }

            storyBatch.add({
              'id': storyId,
              'user_id': userId,
              'image_path': remoteUrl,
              'is_deleted': false,
              'deleted_at': null,
              'created_at': DateTime.fromMillisecondsSinceEpoch(
                s.read<int?>('created_at') ?? DateTime.now().millisecondsSinceEpoch,
              ).toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }

          if (storyBatch.isNotEmpty) {
            await client.from('stories').upsert(storyBatch);
            for (final s in activeStories) {
              await db.customUpdate(
                "UPDATE stories SET sync_status = 'synced' WHERE id = ?",
                variables: [Variable(s.read<String>('id'))],
              );
            }
          }
        }
      }

      _lastSyncTimestamp = DateTime.now();
      _status = SyncStatus.idle;
    } catch (e, st) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      AppLogger.w('Cloud batched sync error: $e', error: e, st: st);
    } finally {
      _isSyncing = false;
    }
  }

  /// Pulls remote cloud feed posts down to the local SQLite database
  Future<void> pullRemoteFeedPosts(String userId) async {
    if (!isSupabaseConfigured) return;
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('feed_posts')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(50);

      final list = response as List;
      if (list.isEmpty) return;

      final docsDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${docsDir.path}/media/feed');
      if (!mediaDir.existsSync()) await mediaDir.create(recursive: true);

      for (final raw in list) {
        final p = raw as Map<String, dynamic>;
        final id = p['id']?.toString() ?? '';
        final text = p['text']?.toString() ?? '';
        var imgPath = p['image_path']?.toString() ?? '';
        final isLiked = p['is_liked'] == true ? 1 : 0;
        final isSaved = p['is_saved'] == true ? 1 : 0;
        final comments = p['comments_json']?.toString() ?? '[]';

        int createdAt = DateTime.now().millisecondsSinceEpoch;
        if (p['created_at'] != null) {
          try {
            createdAt = DateTime.parse(p['created_at'].toString()).millisecondsSinceEpoch;
          } catch (_) {}
        }

        // Cache remote image locally if not cached yet
        if (imgPath.startsWith('http')) {
          final localCached = File('${mediaDir.path}/$id.jpg');
          if (!localCached.existsSync()) {
            try {
              Uint8List? bytes;
              if (imgPath.contains('/post_images/')) {
                final storageKey = imgPath.split('/post_images/').last;
                bytes = await client.storage.from('post_images').download(storageKey);
              } else if (imgPath.contains('/images_bucket/')) {
                final storageKey = imgPath.split('/images_bucket/').last;
                bytes = await client.storage.from('images_bucket').download(storageKey);
              } else {
                final token = client.auth.currentSession?.accessToken;
                final headers = <String, String>{
                  if (token != null) 'Authorization': 'Bearer $token',
                  'apikey': SupabaseAuthService.anonKey,
                };
                final resp = await http.get(Uri.parse(imgPath), headers: headers).timeout(const Duration(seconds: 6));
                if (resp.statusCode == 200) bytes = resp.bodyBytes;
              }

              if (bytes != null && bytes.isNotEmpty) {
                await localCached.writeAsBytes(bytes);
                imgPath = localCached.path;
              }
            } catch (e) {
              AppLogger.w('Failed caching remote image for post $id: $e');
            }
          } else {
            imgPath = localCached.path;
          }
        }

        await db.customInsert(
          '''
          INSERT INTO feed_posts (
            id, account_id, text, image_path, is_liked, is_saved, comments_json,
            is_deleted, sync_status, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 'synced', ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            text = EXCLUDED.text,
            image_path = CASE WHEN EXCLUDED.image_path != '' THEN EXCLUDED.image_path ELSE feed_posts.image_path END,
            is_liked = EXCLUDED.is_liked,
            is_saved = EXCLUDED.is_saved,
            comments_json = EXCLUDED.comments_json,
            updated_at = EXCLUDED.updated_at;
          ''',
          variables: [
            Variable(id),
            Variable(userId),
            Variable(text),
            Variable(imgPath),
            Variable(isLiked),
            Variable(isSaved),
            Variable(comments),
            Variable(createdAt),
            Variable(createdAt),
          ],
        );
      }
    } catch (e) {
      AppLogger.w('Failed to pull remote feed posts: $e');
    }
  }

  /// Pulls remote cloud stories down to the local SQLite database
  Future<void> pullRemoteStories(String userId) async {
    if (!isSupabaseConfigured) return;
    try {
      final client = Supabase.instance.client;
      final twentyFourHoursAgoIso = DateTime.now()
          .subtract(const Duration(hours: 24))
          .toIso8601String();
      final response = await client
          .from('stories')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .gte('created_at', twentyFourHoursAgoIso)
          .order('created_at', ascending: false)
          .limit(30);

      final list = response as List;
      if (list.isEmpty) return;

      final docsDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${docsDir.path}/media/stories');
      if (!mediaDir.existsSync()) await mediaDir.create(recursive: true);

      for (final raw in list) {
        final row = Map<String, dynamic>.from(raw as Map);
        final id = row['id'] as String;
        var imgPath = (row['image_path'] as String?) ?? '';
        final createdAtStr = row['created_at'] as String?;
        final createdAtMs = createdAtStr != null
            ? DateTime.tryParse(createdAtStr)?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch
            : DateTime.now().millisecondsSinceEpoch;

        if (imgPath.startsWith('http')) {
          final localFilename = 'story_$id.jpg';
          final localCached = File('${mediaDir.path}/$localFilename');
          if (!localCached.existsSync()) {
            try {
              Uint8List? bytes;
              if (imgPath.contains('/instance_images/')) {
                final storageKey = imgPath.split('/instance_images/').last;
                bytes = await client.storage.from('instance_images').download(storageKey);
              } else if (imgPath.contains('/images_bucket/')) {
                final storageKey = imgPath.split('/images_bucket/').last;
                bytes = await client.storage.from('images_bucket').download(storageKey);
              } else {
                final token = client.auth.currentSession?.accessToken;
                final headers = <String, String>{
                  if (token != null) 'Authorization': 'Bearer $token',
                  'apikey': SupabaseAuthService.anonKey,
                };
                final resp = await http.get(Uri.parse(imgPath), headers: headers).timeout(const Duration(seconds: 6));
                if (resp.statusCode == 200) bytes = resp.bodyBytes;
              }

              if (bytes != null && bytes.isNotEmpty) {
                await localCached.writeAsBytes(bytes);
                imgPath = localCached.path;
              }
            } catch (e) {
              AppLogger.w('Failed caching remote story $id: $e');
            }
          } else {
            imgPath = localCached.path;
          }
        }

        await db.customInsert(
          '''
          INSERT INTO stories (
            id, account_id, image_path, is_deleted, sync_status, created_at, updated_at
          ) VALUES (?, ?, ?, 0, 'synced', ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            image_path = CASE WHEN EXCLUDED.image_path != '' THEN EXCLUDED.image_path ELSE stories.image_path END,
            updated_at = EXCLUDED.updated_at;
          ''',
          variables: [
            Variable(id),
            Variable(userId),
            Variable(imgPath),
            Variable(createdAtMs),
            Variable(createdAtMs),
          ],
        );
      }
    } catch (e) {
      AppLogger.w('Failed pulling remote stories: $e');
    }
  }

  /// Pulls remote tasks down to local SQLite database
  Future<void> pullRemoteTasks(String userId) async {
    if (!isSupabaseConfigured) return;
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(200);

      final list = response as List;
      if (list.isEmpty) return;

      for (final raw in list) {
        final t = raw as Map<String, dynamic>;
        final id = t['id']?.toString() ?? '';
        final title = t['title']?.toString() ?? '';
        final kind = t['kind']?.toString() ?? 'todo';
        final minDuration = (t['min_duration'] as num?)?.toInt() ?? 0;
        final durationLeftMs = (t['duration_left_ms'] as num?)?.toInt() ?? 0;

        var dueDateStr = t['due_date']?.toString() ?? '';
        if (dueDateStr.isNotEmpty) {
          try {
            final parsed = DateTime.parse(dueDateStr);
            dueDateStr =
                '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
          } catch (_) {
            if (dueDateStr.length >= 10) {
              dueDateStr = dueDateStr.substring(0, 10);
            }
          }
        }
        if (dueDateStr.isEmpty) {
          final now = DateTime.now();
          dueDateStr =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        }

        final isImportant = t['is_important'] == true ? 1 : 0;
        final isDone = t['is_done'] == true ? 1 : 0;
        final doneAt = (t['done_at'] as num?)?.toInt();
        final repeatInterval = t['repeat_interval']?.toString() ?? 'none';
        final tagsJson = t['tags']?.toString() ?? '[]';
        final note = t['note']?.toString() ?? '';

        int createdAt = DateTime.now().millisecondsSinceEpoch;
        if (t['created_at'] != null) {
          try {
            createdAt =
                DateTime.parse(t['created_at'].toString()).millisecondsSinceEpoch;
          } catch (_) {}
        }

        int updatedAt = createdAt;
        if (t['updated_at'] != null) {
          try {
            updatedAt =
                DateTime.parse(t['updated_at'].toString()).millisecondsSinceEpoch;
          } catch (_) {}
        }

        await db.customInsert(
          '''
          INSERT INTO tasks (
            id, account_id, kind, title, min_duration, duration_left_ms, due_date,
            is_important, is_done, done_at, repeat_interval, spawned, tags_json,
            note, is_deleted, sync_status, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, 0, 'synced', ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            title = EXCLUDED.title,
            kind = EXCLUDED.kind,
            min_duration = EXCLUDED.min_duration,
            duration_left_ms = EXCLUDED.duration_left_ms,
            due_date = EXCLUDED.due_date,
            is_important = EXCLUDED.is_important,
            is_done = EXCLUDED.is_done,
            done_at = EXCLUDED.done_at,
            repeat_interval = EXCLUDED.repeat_interval,
            tags_json = EXCLUDED.tags_json,
            note = EXCLUDED.note,
            updated_at = EXCLUDED.updated_at
          WHERE tasks.sync_status != 'pending';
          ''',
          variables: [
            Variable(id),
            Variable(userId),
            Variable(kind),
            Variable(title),
            Variable(minDuration),
            Variable(durationLeftMs),
            Variable(dueDateStr),
            Variable(isImportant),
            Variable(isDone),
            Variable(doneAt),
            Variable(repeatInterval),
            Variable(tagsJson),
            Variable(note),
            Variable(createdAt),
            Variable(updatedAt),
          ],
        );
      }
    } catch (e) {
      AppLogger.w('Failed to pull remote tasks: $e');
    }
  }

  /// Pulls remote wallets down to local SQLite database
  Future<void> pullRemoteWallets(String userId) async {
    if (!isSupabaseConfigured) return;
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      final list = response as List;
      if (list.isEmpty) return;

      for (final raw in list) {
        final w = raw as Map<String, dynamic>;
        final id = w['id']?.toString() ?? '';
        final name = w['name']?.toString() ?? 'Main';
        final currency = w['currency']?.toString() ?? 'Rs';
        final initBal = (w['initial_balance'] as num?)?.toInt() ?? 0;
        final isArchived = w['is_archived'] == true ? 1 : 0;

        int createdAt = DateTime.now().millisecondsSinceEpoch;
        if (w['created_at'] != null) {
          try {
            createdAt =
                DateTime.parse(w['created_at'].toString()).millisecondsSinceEpoch;
          } catch (_) {}
        }

        int updatedAt = createdAt;
        if (w['updated_at'] != null) {
          try {
            updatedAt =
                DateTime.parse(w['updated_at'].toString()).millisecondsSinceEpoch;
          } catch (_) {}
        }

        await db.customInsert(
          '''
          INSERT INTO wallets (
            id, account_id, name, currency, initial_balance, is_archived,
            is_deleted, sync_status, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, 0, 'synced', ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            name = EXCLUDED.name,
            currency = EXCLUDED.currency,
            initial_balance = EXCLUDED.initial_balance,
            is_archived = EXCLUDED.is_archived,
            updated_at = EXCLUDED.updated_at
          WHERE wallets.sync_status != 'pending';
          ''',
          variables: [
            Variable(id),
            Variable(userId),
            Variable(name),
            Variable(currency),
            Variable(initBal),
            Variable(isArchived),
            Variable(createdAt),
            Variable(updatedAt),
          ],
        );
      }
    } catch (e) {
      AppLogger.w('Failed to pull remote wallets: $e');
    }
  }

  /// Pulls remote transactions down to local SQLite database
  Future<void> pullRemoteTransactions(String userId) async {
    if (!isSupabaseConfigured) return;
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('transaction_time', ascending: false)
          .limit(500);

      final list = response as List;
      if (list.isEmpty) return;

      for (final raw in list) {
        final tx = raw as Map<String, dynamic>;
        final id = tx['id']?.toString() ?? '';
        final walletId = tx['wallet_id']?.toString() ?? '';
        final toWalletId = tx['to_wallet_id']?.toString();
        final type = tx['type']?.toString() ?? 'Expense';
        final category = tx['category']?.toString() ?? 'General';
        final amount = (tx['amount'] as num?)?.toInt() ?? 0;
        final txTime = (tx['transaction_time'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch;
        final note = tx['note']?.toString() ?? '';

        int createdAt = txTime;
        if (tx['created_at'] != null) {
          try {
            createdAt =
                DateTime.parse(tx['created_at'].toString()).millisecondsSinceEpoch;
          } catch (_) {}
        }

        int updatedAt = createdAt;
        if (tx['updated_at'] != null) {
          try {
            updatedAt =
                DateTime.parse(tx['updated_at'].toString()).millisecondsSinceEpoch;
          } catch (_) {}
        }

        await db.customInsert(
          '''
          INSERT INTO transactions (
            id, account_id, wallet_id, to_wallet_id, type, category,
            amount, transaction_time, note, is_deleted, sync_status, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 'synced', ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            wallet_id = EXCLUDED.wallet_id,
            to_wallet_id = EXCLUDED.to_wallet_id,
            type = EXCLUDED.type,
            category = EXCLUDED.category,
            amount = EXCLUDED.amount,
            transaction_time = EXCLUDED.transaction_time,
            note = EXCLUDED.note,
            updated_at = EXCLUDED.updated_at
          WHERE transactions.sync_status != 'pending';
          ''',
          variables: [
            Variable(id),
            Variable(userId),
            Variable(walletId),
            Variable(toWalletId),
            Variable(type),
            Variable(category),
            Variable(amount),
            Variable(txTime),
            Variable(note),
            Variable(createdAt),
            Variable(updatedAt),
          ],
        );
      }
    } catch (e) {
      AppLogger.w('Failed to pull remote transactions: $e');
    }
  }

  /// Pulls remote monthly budgets down to local SQLite database
  Future<void> pullRemoteBudgets(String userId) async {
    if (!isSupabaseConfigured) return;
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false);

      final list = response as List;
      if (list.isEmpty) return;

      for (final raw in list) {
        final b = raw as Map<String, dynamic>;
        final id = b['id']?.toString() ?? '';
        final category = b['category']?.toString() ?? 'General';
        final monthlyLimit = (b['monthly_limit'] as num?)?.toInt() ?? 0;

        int createdAt = DateTime.now().millisecondsSinceEpoch;
        if (b['created_at'] != null) {
          try {
            createdAt =
                DateTime.parse(b['created_at'].toString()).millisecondsSinceEpoch;
          } catch (_) {}
        }

        int updatedAt = createdAt;
        if (b['updated_at'] != null) {
          try {
            updatedAt =
                DateTime.parse(b['updated_at'].toString()).millisecondsSinceEpoch;
          } catch (_) {}
        }

        await db.customInsert(
          '''
          INSERT INTO budgets (
            id, account_id, category, monthly_limit, is_deleted, sync_status, created_at, updated_at
          ) VALUES (?, ?, ?, ?, 0, 'synced', ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            category = EXCLUDED.category,
            monthly_limit = EXCLUDED.monthly_limit,
            updated_at = EXCLUDED.updated_at
          WHERE budgets.sync_status != 'pending';
          ''',
          variables: [
            Variable(id),
            Variable(userId),
            Variable(category),
            Variable(monthlyLimit),
            Variable(createdAt),
            Variable(updatedAt),
          ],
        );
      }
    } catch (e) {
      AppLogger.w('Failed to pull remote budgets: $e');
    }
  }

  /// Pulls remote notes down to local SQLite database
  Future<void> pullRemoteNotes(String userId) async {
    if (!isSupabaseConfigured) return;
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('notes')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('updated_at', ascending: false)
          .limit(200);

      final list = response as List;
      if (list.isEmpty) return;

      for (final raw in list) {
        final n = raw as Map<String, dynamic>;
        final id = n['id']?.toString() ?? '';
        final title = n['title']?.toString() ?? '';
        final body = n['body']?.toString() ?? n['content']?.toString() ?? '';
        final isPinned = n['is_pinned'] == true ? 1 : 0;
        final colorIndex = (n['color_index'] as num?)?.toInt() ?? 0;

        int createdAt = DateTime.now().millisecondsSinceEpoch;
        if (n['created_at'] != null) {
          try {
            createdAt =
                DateTime.parse(n['created_at'].toString()).millisecondsSinceEpoch;
          } catch (_) {}
        }

        int updatedAt = createdAt;
        if (n['updated_at'] != null) {
          try {
            updatedAt =
                DateTime.parse(n['updated_at'].toString()).millisecondsSinceEpoch;
          } catch (_) {}
        }

        await db.customInsert(
          '''
          INSERT INTO notes (
            id, account_id, title, body, is_pinned, color_index, is_deleted,
            sync_status, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, 0, 'synced', ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            title = EXCLUDED.title,
            body = EXCLUDED.body,
            is_pinned = EXCLUDED.is_pinned,
            color_index = EXCLUDED.color_index,
            updated_at = EXCLUDED.updated_at
          WHERE notes.sync_status != 'pending';
          ''',
          variables: [
            Variable(id),
            Variable(userId),
            Variable(title),
            Variable(body),
            Variable(isPinned),
            Variable(colorIndex),
            Variable(createdAt),
            Variable(updatedAt),
          ],
        );
      }
    } catch (e) {
      AppLogger.w('Failed to pull remote notes: $e');
    }
  }

  /// Pulls remote calendar events down to local tasks table
  Future<void> pullRemoteCalendarEvents(String userId) async {
    if (!isSupabaseConfigured) return;
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('calendar_events')
          .select()
          .eq('user_id', userId);

      final list = response as List;
      if (list.isEmpty) return;

      for (final raw in list) {
        final ev = raw as Map<String, dynamic>;
        final id = ev['id']?.toString() ?? '';
        final title = ev['title']?.toString() ?? '';
        final note = ev['description']?.toString() ?? '';
        var startTimeStr = ev['start_time']?.toString() ?? '';
        var dueDateStr = '';
        if (startTimeStr.isNotEmpty) {
          try {
            final parsed = DateTime.parse(startTimeStr);
            dueDateStr =
                '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
          } catch (_) {
            if (startTimeStr.length >= 10) {
              dueDateStr = startTimeStr.substring(0, 10);
            }
          }
        }
        if (dueDateStr.isEmpty) {
          final now = DateTime.now();
          dueDateStr =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        }

        int createdAt = DateTime.now().millisecondsSinceEpoch;
        if (ev['created_at'] != null) {
          try {
            createdAt =
                DateTime.parse(ev['created_at'].toString()).millisecondsSinceEpoch;
          } catch (_) {}
        }

        await db.customInsert(
          '''
          INSERT INTO tasks (
            id, account_id, kind, title, min_duration, duration_left_ms, due_date,
            is_important, is_done, repeat_interval, spawned, tags_json, note,
            is_deleted, sync_status, created_at, updated_at
          ) VALUES (?, ?, 'event', ?, 0, 0, ?, 0, 0, 'none', 0, '["event"]', ?, 0, 'synced', ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            title = EXCLUDED.title,
            due_date = EXCLUDED.due_date,
            note = EXCLUDED.note,
            updated_at = EXCLUDED.updated_at
          WHERE tasks.sync_status != 'pending';
          ''',
          variables: [
            Variable(id),
            Variable(userId),
            Variable(title),
            Variable(dueDateStr),
            Variable(note),
            Variable(createdAt),
            Variable(createdAt),
          ],
        );
      }
    } catch (e) {
      AppLogger.w('Failed to pull remote calendar events: $e');
    }
  }

  /// Pulls ALL cloud data down into the local SQLite database in one call
  Future<void> pullAllRemoteData(String userId) async {
    if (!isSupabaseConfigured) return;
    try {
      await Future.wait([
        pullRemoteTasks(userId),
        pullRemoteWallets(userId),
        pullRemoteTransactions(userId),
        pullRemoteBudgets(userId),
        pullRemoteNotes(userId),
        pullRemoteCalendarEvents(userId),
        pullRemoteFeedPosts(userId),
        pullRemoteStories(userId),
      ]);
    } catch (e) {
      AppLogger.w('pullAllRemoteData non-fatal error: $e');
    }
  }

  /// Flushes pending changes immediately (e.g. when user exits screen or leaves app)
  Future<void> flushOnExit(String accountId) async {
    _debounceTimer?.cancel();
    await syncPendingRecords(accountId, force: true);
  }
}

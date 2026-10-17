import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/myday_database.dart';

class MyDayFeedPost {
  final String id;
  final String accountId;
  final String text;
  final String imagePath;
  final bool isLiked;
  final bool isSaved;
  final List<String> comments;
  final int createdAt;
  final bool isDeleted;

  const MyDayFeedPost({
    required this.id,
    required this.accountId,
    required this.text,
    this.imagePath = '',
    this.isLiked = false,
    this.isSaved = false,
    this.comments = const [],
    required this.createdAt,
    this.isDeleted = false,
  });

  String? get imageUrl => imagePath.isNotEmpty ? imagePath : null;

  factory MyDayFeedPost.fromRow(QueryRow row) {
    List<String> parsedComments = [];
    try {
      final jsonStr = row.read<String>('comments_json');
      parsedComments = List<String>.from(jsonDecode(jsonStr) as List);
    } catch (_) {}

    return MyDayFeedPost(
      id: row.read<String>('id'),
      accountId: row.read<String>('account_id'),
      text: row.read<String>('text'),
      imagePath: row.read<String>('image_path'),
      isLiked: row.read<int>('is_liked') == 1,
      isSaved: row.read<int>('is_saved') == 1,
      comments: parsedComments,
      createdAt: row.read<int>('created_at'),
      isDeleted: row.read<int>('is_deleted') == 1,
    );
  }
}

class MyDayStory {
  final String id;
  final String accountId;
  final String imagePath;
  final int createdAt;

  const MyDayStory({
    required this.id,
    required this.accountId,
    required this.imagePath,
    required this.createdAt,
  });

  factory MyDayStory.fromRow(QueryRow row) {
    return MyDayStory(
      id: row.read<String>('id'),
      accountId: row.read<String>('account_id'),
      imagePath: row.read<String>('image_path'),
      createdAt: row.read<int>('created_at'),
    );
  }
}

class FeedRepository {
  final MyDayDatabase db;
  static const _uuid = Uuid();

  FeedRepository(this.db);

  /// Retrieves feed posts filtered by tab ('all', 'media', 'saved')
  Future<List<MyDayFeedPost>> getPosts(String accountId, {String tab = 'all'}) async {
    String where = 'account_id = ? AND is_deleted = 0';
    List<Variable> vars = [Variable(accountId)];

    if (tab == 'media') {
      where += " AND image_path != ''";
    } else if (tab == 'saved') {
      where += ' AND is_saved = 1';
    }

    final rows = await db.customSelect(
      'SELECT * FROM feed_posts WHERE $where ORDER BY created_at DESC',
      variables: vars,
    ).get();

    return rows.map(MyDayFeedPost.fromRow).toList();
  }

  /// Persists a media file from temporary/cache location to app document storage
  static Future<String> persistMediaFile(String sourcePath, {String subDir = 'feed'}) async {
    if (sourcePath.isEmpty) return '';
    if (sourcePath.startsWith('http://') || sourcePath.startsWith('https://')) {
      return sourcePath;
    }
    try {
      final file = File(sourcePath);
      if (!file.existsSync()) return sourcePath;

      final docsDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${docsDir.path}/media/$subDir');
      if (!mediaDir.existsSync()) {
        await mediaDir.create(recursive: true);
      }

      if (sourcePath.startsWith(mediaDir.path)) {
        return sourcePath;
      }

      final ext = sourcePath.contains('.') ? '.${sourcePath.split('.').last}' : '.jpg';
      final targetPath = '${mediaDir.path}/${_uuid.v4()}$ext';
      await file.copy(targetPath);
      return targetPath;
    } catch (_) {
      return sourcePath;
    }
  }

  /// Creates a new post
  Future<MyDayFeedPost> createPost({
    required String accountId,
    required String text,
    String imagePath = '',
  }) async {
    final id = _uuid.v4().substring(0, 8);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final savedImagePath = await persistMediaFile(imagePath, subDir: 'feed');

    await db.customInsert(
      '''
      INSERT INTO feed_posts (id, account_id, text, image_path, is_liked, is_saved, comments_json, is_deleted, sync_status, created_at, updated_at)
      VALUES (?, ?, ?, ?, 0, 0, '[]', 0, 'pending', ?, ?)
      ''',
      variables: [
        Variable(id),
        Variable(accountId),
        Variable(text),
        Variable(savedImagePath),
        Variable(nowMs),
        Variable(nowMs),
      ],
    );

    return MyDayFeedPost(
      id: id,
      accountId: accountId,
      text: text,
      imagePath: savedImagePath,
      createdAt: nowMs,
    );
  }

  /// Toggles post like status
  Future<void> toggleLike(String postId, bool currentLiked) async {
    await db.customUpdate(
      'UPDATE feed_posts SET is_liked = ? WHERE id = ?',
      variables: [Variable(currentLiked ? 0 : 1), Variable(postId)],
    );
  }

  /// Toggles post saved status
  Future<void> toggleSave(String postId, bool currentSaved) async {
    await db.customUpdate(
      'UPDATE feed_posts SET is_saved = ? WHERE id = ?',
      variables: [Variable(currentSaved ? 0 : 1), Variable(postId)],
    );
  }

  /// Adds a comment to a post
  Future<void> addComment(String postId, List<String> currentComments, String newComment) async {
    final updatedList = [...currentComments, newComment];
    await db.customUpdate(
      'UPDATE feed_posts SET comments_json = ? WHERE id = ?',
      variables: [Variable(jsonEncode(updatedList)), Variable(postId)],
    );
  }

  Future<void> addCommentSimple(String postId, String newComment) async {
    final row = await db.customSelect(
      'SELECT comments_json FROM feed_posts WHERE id = ?',
      variables: [Variable(postId)],
    ).getSingleOrNull();

    List<String> comments = [];
    if (row != null) {
      try {
        final jsonStr = row.read<String>('comments_json');
        comments = List<String>.from(jsonDecode(jsonStr) as List);
      } catch (_) {}
    }
    await addComment(postId, comments, newComment);
  }

  /// Soft deletes a post
  Future<void> deletePost(String postId) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customUpdate(
      "UPDATE feed_posts SET is_deleted = 1, deleted_at = ?, sync_status = 'pending' WHERE id = ?",
      variables: [Variable(nowMs), Variable(postId)],
    );
  }

  /// Restores a soft-deleted post
  Future<void> restorePost(String postId) async {
    await db.customUpdate(
      "UPDATE feed_posts SET is_deleted = 0, deleted_at = NULL, sync_status = 'pending' WHERE id = ?",
      variables: [Variable(postId)],
    );
  }

  /// Retrieves active stories (created within last 24 hours)
  Future<List<MyDayStory>> getStories(String accountId) async {
    final twentyFourHoursAgoMs = DateTime.now()
        .subtract(const Duration(hours: 24))
        .millisecondsSinceEpoch;

    final rows = await db.customSelect(
      'SELECT * FROM stories WHERE account_id = ? AND is_deleted = 0 AND created_at >= ? ORDER BY created_at DESC',
      variables: [Variable(accountId), Variable(twentyFourHoursAgoMs)],
    ).get();

    return rows.map(MyDayStory.fromRow).toList();
  }

  /// Adds a story
  Future<MyDayStory> addStory({
    required String accountId,
    required String imagePath,
  }) async {
    final id = _uuid.v4().substring(0, 8);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final savedImagePath = await persistMediaFile(imagePath, subDir: 'stories');

    await db.customInsert(
      '''
      INSERT INTO stories (id, account_id, image_path, is_deleted, sync_status, created_at, updated_at)
      VALUES (?, ?, ?, 0, 'pending', ?, ?)
      ''',
      variables: [
        Variable(id),
        Variable(accountId),
        Variable(savedImagePath),
        Variable(nowMs),
        Variable(nowMs),
      ],
    );

    return MyDayStory(
      id: id,
      accountId: accountId,
      imagePath: savedImagePath,
      createdAt: nowMs,
    );
  }

  Future<MyDayStory> createStory({
    required String accountId,
    required String imageUrl,
  }) => addStory(accountId: accountId, imagePath: imageUrl);

  /// Deletes a story
  Future<void> deleteStory(String storyId) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customUpdate(
      "UPDATE stories SET is_deleted = 1, deleted_at = ?, sync_status = 'pending', updated_at = ? WHERE id = ?",
      variables: [Variable(nowMs), Variable(nowMs), Variable(storyId)],
    );
  }
}

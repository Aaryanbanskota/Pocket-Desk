import 'package:isar/isar.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/instant_model.dart';
import '../models/post_model.dart';

class PostsRepository {
  PostsRepository({required Isar isar}) : _isar = isar;
  final Isar _isar;

  Future<List<PostModel>> getPosts(int userId) async {
    try {
      final list = await _isar.postModels
          .where()
          .userIdEqualTo(userId)
          .findAll();
      list.sort((a, b) {
        if (a.isPinned != b.isPinned) return b.isPinned ? 1 : -1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    } catch (e, st) {
      AppLogger.e('Failed to fetch posts', tag: 'PostsRepo', error: e, st: st);
      return [];
    }
  }

  Future<PostModel> savePost(PostModel post) async {
    final now = DateTime.now();
    post.updatedAt = now;
    if (post.id == Isar.autoIncrement) post.createdAt = now;

    await _isar.writeTxn(() => _isar.postModels.put(post));
    return post;
  }

  Future<PostModel?> getPostById(int postId) async {
    try {
      return await _isar.postModels.get(postId);
    } catch (e, st) {
      AppLogger.e('Failed to fetch post by ID', tag: 'PostsRepo', error: e, st: st);
      return null;
    }
  }

  Future<void> deletePost(int postId) async {
    await _isar.writeTxn(() => _isar.postModels.delete(postId));
  }

  Future<InstantModel> saveInstant(InstantModel instant) async {
    final now = DateTime.now();
    instant.createdAt = now;
    instant.expiresAt = now.add(const Duration(hours: 24));
    await _isar.writeTxn(() => _isar.instantModels.put(instant));
    return instant;
  }

  Future<List<InstantModel>> getInstantsForUser(int userId) async {
    try {
      final now = DateTime.now();
      return await _isar.instantModels
          .where()
          .userIdEqualTo(userId)
          .filter()
          .expiresAtGreaterThan(now)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e, st) {
      AppLogger.e('Failed to fetch instants', tag: 'PostsRepo', error: e, st: st);
      return [];
    }
  }

  Future<void> deleteInstant(int id) async {
    await _isar.writeTxn(() => _isar.instantModels.delete(id));
  }
}

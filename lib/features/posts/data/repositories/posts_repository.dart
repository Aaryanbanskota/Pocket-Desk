import 'package:isar/isar.dart';
import '../../../../core/logging/app_logger.dart';
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

  Future<void> deletePost(int postId) async {
    await _isar.writeTxn(() => _isar.postModels.delete(postId));
  }
}

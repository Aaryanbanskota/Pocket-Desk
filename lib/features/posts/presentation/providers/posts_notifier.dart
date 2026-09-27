import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketdesk/core/database/isar_provider.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pocketdesk/features/settings/presentation/providers/ai_settings_notifier.dart';
import 'package:pocketdesk/features/posts/data/models/post_model.dart';
import 'package:pocketdesk/features/posts/data/repositories/posts_repository.dart';

final postsRepositoryProvider = FutureProvider<PostsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return PostsRepository(isar: isar);
});

class PostsNotifier extends AutoDisposeAsyncNotifier<List<PostModel>> {
  @override
  Future<List<PostModel>> build() async {
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return [];
    final repo = await ref.watch(postsRepositoryProvider.future);
    return repo.getPosts(auth.user.id);
  }

  Future<void> createPost({
    required String content,
    String? title,
    List<String> imagePaths = const [],
    List<String> tags = const [],
  }) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;
    final repo = await ref.read(postsRepositoryProvider.future);

    final post = PostModel()
      ..userId = auth.user.id
      ..title = title
      ..content = content
      ..imagePaths = imagePaths
      ..tags = tags;

    final saved = await repo.savePost(post);
    ref.invalidateSelf();

    // Trigger AI Reaction asynchronously if enabled
    _triggerAIReaction(saved);
  }

  Future<void> _triggerAIReaction(PostModel post) async {
    final aiSettings = await ref.read(aiSettingsRepositoryProvider.future).then((r) => r.getOrCreateSettings(post.userId));
    if (!aiSettings.isEnabled || !aiSettings.allowPostsAccess || !aiSettings.postReactionsEnabled || aiSettings.apiKey.trim().isEmpty) {
      return;
    }

    final prompt = 'User posted text on their private personal feed: "${post.content}"';
    const systemPrompt = 'You are Pocketdesk AI replying warmly to a user post in their offline personal feed. Respond naturally as a helpful friend in 1-2 friendly sentences. Do not mention that you are an AI model.';

    final reactionText = await ref.read(aiSettingsProvider.notifier).generateCompletion(
      prompt: prompt,
      systemPrompt: systemPrompt,
    );

    if (reactionText != null && reactionText.isNotEmpty) {
      post.comments.add(reactionText);
      post.commentAuthors.add('Pocketdesk AI 🤖');
      post.commentDates.add(DateTime.now());

      final repo = await ref.read(postsRepositoryProvider.future);
      await repo.savePost(post);
      ref.invalidateSelf();
    }
  }

  Future<void> toggleLike(PostModel post) async {
    post.isLiked = !post.isLiked;
    post.likesCount += post.isLiked ? 1 : -1;
    final repo = await ref.read(postsRepositoryProvider.future);
    await repo.savePost(post);
    ref.invalidateSelf();
  }

  Future<void> toggleSave(PostModel post) async {
    post.isSaved = !post.isSaved;
    final repo = await ref.read(postsRepositoryProvider.future);
    await repo.savePost(post);
    ref.invalidateSelf();
  }

  Future<void> togglePin(PostModel post) async {
    post.isPinned = !post.isPinned;
    final repo = await ref.read(postsRepositoryProvider.future);
    await repo.savePost(post);
    ref.invalidateSelf();
  }

  Future<void> addComment(PostModel post, String commentText) async {
    if (commentText.trim().isEmpty) return;
    final auth = ref.read(authNotifierProvider).valueOrNull;
    final author = auth is AuthAuthenticated ? (auth.user.displayName ?? auth.user.username) : 'You';

    post.comments.add(commentText.trim());
    post.commentAuthors.add(author);
    post.commentDates.add(DateTime.now());

    final repo = await ref.read(postsRepositoryProvider.future);
    await repo.savePost(post);
    ref.invalidateSelf();
  }

  Future<void> deletePost(int postId) async {
    final repo = await ref.read(postsRepositoryProvider.future);
    await repo.deletePost(postId);
    ref.invalidateSelf();
  }
}

final postsNotifierProvider = AutoDisposeAsyncNotifierProvider<PostsNotifier, List<PostModel>>(
  PostsNotifier.new,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketdesk/core/database/isar_provider.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pocketdesk/features/settings/presentation/providers/ai_settings_notifier.dart';
import 'package:pocketdesk/features/posts/data/models/instant_model.dart';
import 'package:pocketdesk/features/posts/data/models/post_model.dart';
import 'package:pocketdesk/features/posts/data/repositories/posts_repository.dart';
import 'package:pocketdesk/features/trash/data/models/trash_item_model.dart';
import 'package:pocketdesk/features/trash/presentation/providers/trash_notifier.dart';

final postsRepositoryProvider = FutureProvider<PostsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return PostsRepository(isar: isar);
});

// ---------------------------------------------------------------------------
// Instants Notifier & Provider
// ---------------------------------------------------------------------------

final instantsProvider = AutoDisposeAsyncNotifierProvider<InstantsNotifier, List<InstantModel>>(
  InstantsNotifier.new,
);

class InstantsNotifier extends AutoDisposeAsyncNotifier<List<InstantModel>> {
  @override
  Future<List<InstantModel>> build() async {
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return [];
    final repo = await ref.watch(postsRepositoryProvider.future);
    return repo.getInstantsForUser(auth.user.id);
  }

  Future<void> createInstant({
    required String imagePath,
    String? textOverlay,
    double textX = 0.5,
    double textY = 0.5,
  }) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;
    final repo = await ref.read(postsRepositoryProvider.future);

    final instant = InstantModel()
      ..userId = auth.user.id
      ..imagePath = imagePath
      ..textOverlay = textOverlay
      ..textX = textX
      ..textY = textY;

    await repo.saveInstant(instant);
    ref.invalidateSelf();
  }

  Future<void> deleteInstant(int id) async {
    final repo = await ref.read(postsRepositoryProvider.future);
    await repo.deleteInstant(id);
    ref.invalidateSelf();
  }
}

// ---------------------------------------------------------------------------
// Posts Notifier & Provider
// ---------------------------------------------------------------------------

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

    // Trigger AI Reaction and like asynchronously if enabled
    _triggerAIReaction(saved);
  }

  Future<void> _triggerAIReaction(PostModel post) async {
    final aiSettings = await ref.read(aiSettingsRepositoryProvider.future).then((r) => r.getOrCreateSettings(post.userId));
    if (!aiSettings.isEnabled || !aiSettings.allowPostsAccess || !aiSettings.postReactionsEnabled || aiSettings.apiKey.trim().isEmpty) {
      return;
    }

    // AI randomly likes the post if it finds it engaging
    final repo = await ref.read(postsRepositoryProvider.future);
    if (!post.isLiked) {
      post.isLiked = true;
      post.likesCount += 1;
      await repo.savePost(post);
      ref.invalidateSelf();
    }

    // AI evaluates only text content (ignoring images/videos)
    final prompt = 'User posted text on their private personal feed: "${post.content}"';
    const systemPrompt = 'You are Pocketdesk AI replying warmly to a user post in their offline personal feed. You evaluate only the text content provided. Respond naturally as a helpful friend in 1-2 friendly sentences. Do not mention that you are an AI model.';

    final reactionText = await ref.read(aiSettingsProvider.notifier).generateCompletion(
      prompt: prompt,
      systemPrompt: systemPrompt,
    );

    if (reactionText != null && reactionText.isNotEmpty) {
      post.comments.add(reactionText);
      post.commentAuthors.add('Pocketdesk AI 🤖');
      post.commentDates.add(DateTime.now());

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

    final repo = await ref.read(postsRepositoryProvider.future);
    final freshPost = await repo.getPostById(post.id) ?? post;

    freshPost.comments = List.from(freshPost.comments)..add(commentText.trim());
    freshPost.commentAuthors = List.from(freshPost.commentAuthors)..add(author);
    freshPost.commentDates = List.from(freshPost.commentDates)..add(DateTime.now());

    await repo.savePost(freshPost);
    ref.invalidateSelf();

    // Trigger AI response in thread if cap of 5 AI replies hasn't been reached
    _triggerAIThreadReply(freshPost);
  }

  Future<void> _triggerAIThreadReply(PostModel post) async {
    final aiCount = post.commentAuthors.where((a) => a.contains('AI')).length;
    if (aiCount >= 5) return; // Cap AI replies to 5 per post

    final aiSettings = await ref.read(aiSettingsRepositoryProvider.future).then((r) => r.getOrCreateSettings(post.userId));
    if (!aiSettings.isEnabled || !aiSettings.allowPostsAccess || !aiSettings.postReactionsEnabled || aiSettings.apiKey.trim().isEmpty) {
      return;
    }

    final prompt = 'User commented in post thread: "${post.comments.last}". Context post: "${post.content}"';
    const systemPrompt = 'You are Pocketdesk AI chatting warmly in the comments section of a user post. Keep responses short, friendly (1-2 sentences), and casual like a real friend on Instagram.';

    final reply = await ref.read(aiSettingsProvider.notifier).generateCompletion(
      prompt: prompt,
      systemPrompt: systemPrompt,
    );

    if (reply != null && reply.isNotEmpty) {
      final freshRepo = await ref.read(postsRepositoryProvider.future);
      final currentPost = await freshRepo.getPostById(post.id) ?? post;

      currentPost.comments = List.from(currentPost.comments)..add(reply);
      currentPost.commentAuthors = List.from(currentPost.commentAuthors)..add('Pocketdesk AI 🤖');
      currentPost.commentDates = List.from(currentPost.commentDates)..add(DateTime.now());

      await freshRepo.savePost(currentPost);
      ref.invalidateSelf();
    }
  }

  Future<void> deletePost(int postId) async {
    final repo = await ref.read(postsRepositoryProvider.future);
    final post = await repo.getPostById(postId);
    if (post != null) {
      await ref.read(trashNotifierProvider.notifier).moveToTrash(
            itemType: TrashItemType.post,
            originalId: post.id,
            title: post.title ?? 'Post',
            snippet: post.content.length > 100 ? '${post.content.substring(0, 100)}...' : post.content,
          );
    }
    await repo.deletePost(postId);
    ref.invalidateSelf();
  }
}

final postsNotifierProvider = AutoDisposeAsyncNotifierProvider<PostsNotifier, List<PostModel>>(
  PostsNotifier.new,
);

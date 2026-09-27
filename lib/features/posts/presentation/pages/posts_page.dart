import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketdesk/core/theme/app_spacing.dart';
import 'package:pocketdesk/features/dashboard/presentation/widgets/app_hamburger_drawer.dart';
import 'package:pocketdesk/features/posts/data/models/post_model.dart';
import 'package:pocketdesk/features/posts/presentation/providers/posts_notifier.dart';

class PostsPage extends ConsumerStatefulWidget {
  const PostsPage({super.key});

  @override
  ConsumerState<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends ConsumerState<PostsPage> {
  final _contentCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _contentCtrl.dispose();
    _titleCtrl.dispose();
    _tagsCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _showCreatePostModal() {
    _contentCtrl.clear();
    _titleCtrl.clear();
    _tagsCtrl.clear();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Create Personal Post', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _contentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'What is on your mind?',
                  hintText: 'Share a moment, goal, or daily thought…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _tagsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  hintText: 'e.g. study, win, daily',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 16, color: Theme.of(ctx).colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '🔒 Private — only you and Pocketdesk AI can access this text.',
                      style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () {
                  final text = _contentCtrl.text.trim();
                  if (text.isEmpty) return;
                  final tags = _tagsCtrl.text
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();

                  ref.read(postsNotifierProvider.notifier).createPost(
                    content: text,
                    title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
                    tags: tags,
                  );

                  Navigator.pop(ctx);
                },
                child: const Text('Post to Personal Feed'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommentDialog(PostModel post) {
    _commentCtrl.clear();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Comment / Reply'),
        content: TextField(
          controller: _commentCtrl,
          decoration: const InputDecoration(hintText: 'Write a reply…', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (_commentCtrl.text.trim().isNotEmpty) {
                ref.read(postsNotifierProvider.notifier).addComment(post, _commentCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final postsAsync = ref.watch(postsNotifierProvider);

    return Scaffold(
      drawer: const AppHamburgerDrawer(),
      appBar: AppBar(
        title: const Text('Personal Feed'),
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dynamic_feed_rounded, size: 64, color: cs.onSurfaceVariant.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Your personal feed is empty.', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Capture daily thoughts, wins, or moments offline!', style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _showCreatePostModal,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create First Post'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: post.isPinned ? cs.primary : cs.outlineVariant.withOpacity(0.4),
                    width: post.isPinned ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header User Row
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Icon(Icons.person_rounded, color: cs.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('My Day', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                    if (post.isPinned) ...[
                                      const SizedBox(width: 6),
                                      Icon(Icons.push_pin, size: 14, color: cs.primary),
                                    ],
                                  ],
                                ),
                                Text(
                                  '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year} • ${post.createdAt.hour}:${post.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              final notifier = ref.read(postsNotifierProvider.notifier);
                              if (val == 'pin') notifier.togglePin(post);
                              if (val == 'delete') notifier.deletePost(post.id);
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'pin',
                                child: Text(post.isPinned ? 'Unpin Post' : 'Pin Post'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete Post'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (post.title != null && post.title!.isNotEmpty) ...[
                        Text(post.title!, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                      ],

                      Text(post.content, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),

                      if (post.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: post.tags.map((t) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('#$t', style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.bold)),
                              )).toList(),
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(height: 16),

                      // Social Interaction Bar (Like, Comment, Save)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: post.isLiked ? Colors.red : cs.onSurfaceVariant,
                            ),
                            onPressed: () => ref.read(postsNotifierProvider.notifier).toggleLike(post),
                          ),
                          Text('${post.likesCount}', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Icon(Icons.chat_bubble_outline_rounded, color: cs.onSurfaceVariant),
                            onPressed: () => _showCommentDialog(post),
                          ),
                          Text('${post.comments.length}', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: post.isSaved ? cs.primary : cs.onSurfaceVariant,
                            ),
                            onPressed: () => ref.read(postsNotifierProvider.notifier).toggleSave(post),
                          ),
                        ],
                      ),

                      // Comments / AI Reactions Section
                      if (post.comments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(post.comments.length, (i) {
                              final isAI = post.commentAuthors[i].contains('AI');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: RichText(
                                  text: TextSpan(
                                    style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                                    children: [
                                      TextSpan(
                                        text: '${post.commentAuthors[i]}: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isAI ? cs.primary : cs.onSurface,
                                        ),
                                      ),
                                      TextSpan(
                                        text: post.comments[i],
                                        style: TextStyle(color: cs.onSurface),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostModal,
        child: const Icon(Icons.add_comment_rounded),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';

class LocalPost {
  LocalPost({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.authorName = 'You',
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String authorName;
}

class PostsPage extends ConsumerStatefulWidget {
  const PostsPage({super.key});

  @override
  ConsumerState<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends ConsumerState<PostsPage> {
  final List<LocalPost> _posts = [
    LocalPost(
      id: '1',
      title: 'Welcome to PocketDesk Feed!',
      content: 'Capture your thoughts, ideas, and daily moments right here in your local personal feed.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  void _createPost() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create Personal Post', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _contentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'What is on your mind?'),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () {
                if (_titleCtrl.text.trim().isEmpty) return;
                setState(() {
                  _posts.insert(
                    0,
                    LocalPost(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _titleCtrl.text.trim(),
                      content: _contentCtrl.text.trim(),
                      createdAt: DateTime.now(),
                    ),
                  );
                });
                _titleCtrl.clear();
                _contentCtrl.clear();
                Navigator.pop(context);
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Posts'),
      ),
      body: _posts.isEmpty
          ? Center(
              child: Text(
                'No posts yet. Tap + to share your first post!',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(Icons.person_rounded, color: colorScheme.primary),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post.authorName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(
                                    '${post.createdAt.hour}:${post.createdAt.minute.toString().padLeft(2, '0')}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              onPressed: () {
                                setState(() {
                                  _posts.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(post.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(post.content, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPost,
        child: const Icon(Icons.add_comment_rounded),
      ),
    );
  }
}

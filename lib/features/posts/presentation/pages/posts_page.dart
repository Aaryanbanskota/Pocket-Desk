import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketdesk/core/theme/app_spacing.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pocketdesk/features/dashboard/presentation/widgets/app_hamburger_drawer.dart';
import 'package:pocketdesk/features/posts/data/models/instant_model.dart';
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
  final List<String> _selectedImagePaths = [];

  @override
  void dispose() {
    _contentCtrl.dispose();
    _titleCtrl.dispose();
    _tagsCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi'],
      allowMultiple: true,
    );

    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        for (final p in result.paths) {
          if (p != null && !_selectedImagePaths.contains(p)) {
            _selectedImagePaths.add(p);
          }
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Profile Editor Modal
  // ---------------------------------------------------------------------------

  void _showEditProfileModal() {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;

    final nameCtrl = TextEditingController(text: auth.user.displayName ?? auth.user.username);
    String? currentAvatar = auth.user.avatarBase64;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit Profile', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null && result.files.single.path != null) {
                    final bytes = await File(result.files.single.path!).readAsBytes();
                    final b64 = base64Encode(bytes);
                    setModalState(() => currentAvatar = b64);
                  }
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: currentAvatar != null ? MemoryImage(base64Decode(currentAvatar!)) : null,
                      child: currentAvatar == null ? Icon(Icons.person_rounded, size: 40, color: Theme.of(context).colorScheme.primary) : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).updateProfile(
                    displayName: nameCtrl.text.trim(),
                    avatarBase64: currentAvatar,
                  );
                  if (context.mounted) Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Instagram-style Instants Feature
  // ---------------------------------------------------------------------------

  void _openInstantsDashboard(List<InstantModel> instants) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('My Instants', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openCreateInstantCamera();
                    },
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            Expanded(
              child: instants.isEmpty
                  ? const Center(child: Text('No Instants yet. Tap camera to create!', style: TextStyle(color: Colors.white70)))
                  : PageView.builder(
                      itemCount: instants.length,
                      itemBuilder: (context, i) {
                        final inst = instants[i];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(File(inst.imagePath), fit: BoxFit.cover),
                            ),
                            if (inst.textOverlay != null && inst.textOverlay!.isNotEmpty)
                              Positioned(
                                left: inst.textX * MediaQuery.of(context).size.width * 0.8,
                                top: inst.textY * MediaQuery.of(context).size.height * 0.6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                                  child: Text(inst.textOverlay!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateInstantCamera() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return;
    final imagePath = result.files.single.path!;

    final textCtrl = TextEditingController();
    Offset textOffset = const Offset(80, 250);

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setCameraState) => Container(
          height: MediaQuery.of(context).size.height * 0.96,
          color: Colors.black,
          child: Column(
            children: [
              // Top Header Bar matching screenshot
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    const Text(
                      'New Instant',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 22),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 22),
                          onPressed: () async {
                            final pickerResult = await FilePicker.platform.pickFiles(type: FileType.image);
                            if (pickerResult != null && pickerResult.files.single.path != null) {
                              setCameraState(() {
                                textOffset = const Offset(80, 250);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Squircle Camera Viewport matching uploaded image
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(44),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(imagePath), fit: BoxFit.cover),
                        Positioned(
                          left: textOffset.dx,
                          top: textOffset.dy,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setCameraState(() {
                                textOffset += details.delta;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                textCtrl.text.isEmpty ? 'Tap top bar to type text' : textCtrl.text,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: TextField(
                            controller: textCtrl,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'Type overlay text…',
                              hintStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.black45,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onChanged: (_) => setCameraState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Camera Capture Shutter Controls matching uploaded screenshot
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Flash / Off toggle
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
                      child: const Icon(Icons.flash_off_rounded, color: Colors.white, size: 22),
                    ),

                    // Big White Camera Shutter Button (Submits / Captures Instant)
                    GestureDetector(
                      onTap: () async {
                        final normX = (textOffset.dx / MediaQuery.of(context).size.width).clamp(0.0, 1.0);
                        final normY = (textOffset.dy / MediaQuery.of(context).size.height).clamp(0.0, 1.0);

                        await ref.read(instantsProvider.notifier).createInstant(
                          imagePath: imagePath,
                          textOverlay: textCtrl.text.trim().isEmpty ? null : textCtrl.text.trim(),
                          textX: normX,
                          textY: normY,
                        );

                        if (context.mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 5),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),

                    // Camera Flip icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
                      child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Instagram-style Post Form Sheet
  // ---------------------------------------------------------------------------

  void _showCreatePostModal() {
    _contentCtrl.clear();
    _titleCtrl.clear();
    _tagsCtrl.clear();
    _selectedImagePaths.clear();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Post', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                  labelText: 'Write a caption…',
                  hintText: 'Share a moment, thoughts, or story…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _tagsCtrl,
                decoration: const InputDecoration(labelText: 'Tags (comma separated)', hintText: 'e.g. daily, win, fun', border: OutlineInputBorder()),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () async {
                  await _pickMedia();
                  (ctx as Element).markNeedsBuild();
                },
                icon: const Icon(Icons.perm_media_rounded),
                label: Text(_selectedImagePaths.isEmpty ? 'Attach Photos / Videos / GIFs' : '${_selectedImagePaths.length} Media Selected'),
              ),
              if (_selectedImagePaths.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImagePaths.length,
                    itemBuilder: (c, i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImagePaths[i]),
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.movie_rounded, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () {
                  final text = _contentCtrl.text.trim();
                  if (text.isEmpty && _selectedImagePaths.isEmpty) return;
                  final tags = _tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

                  ref.read(postsNotifierProvider.notifier).createPost(
                    content: text,
                    title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
                    imagePaths: List.from(_selectedImagePaths),
                    tags: tags,
                  );

                  Navigator.pop(ctx);
                },
                child: const Text('Share Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Instagram-style Comment Bottom Sheet with AI thread replies (capped at 5)
  // ---------------------------------------------------------------------------

  void _showInstagramCommentsSheet(PostModel post) {
    _commentCtrl.clear();
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Center(
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 12),
              Text('Comments', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              Expanded(
                child: post.comments.isEmpty
                    ? Center(child: Text('No comments yet. Be the first to comment!', style: TextStyle(color: cs.onSurfaceVariant)))
                    : ListView.builder(
                        itemCount: post.comments.length,
                        itemBuilder: (context, i) {
                          final author = post.commentAuthors[i];
                          final comment = post.comments[i];
                          final isAI = author.contains('AI');

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isAI ? cs.primaryContainer : cs.surfaceContainerHighest,
                                  child: isAI
                                      ? const Icon(Icons.smart_toy_rounded, size: 16, color: Colors.blue)
                                      : const Icon(Icons.person_rounded, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(author, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isAI ? cs.primary : cs.onSurface)),
                                      const SizedBox(height: 2),
                                      Text(comment, style: TextStyle(fontSize: 14, color: cs.onSurface)),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () {
                                          _commentCtrl.text = '@$author ';
                                          _commentCtrl.selection = TextSelection.fromPosition(
                                            TextPosition(offset: _commentCtrl.text.length),
                                          );
                                        },
                                        child: Text(
                                          'Reply',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: const InputDecoration(hintText: 'Add a comment…', border: InputBorder.none),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final text = _commentCtrl.text.trim();
                      if (text.isNotEmpty) {
                        await ref.read(postsNotifierProvider.notifier).addComment(post, text);
                        _commentCtrl.clear();
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Full-screen Zoomable Image Viewer
  void _openFullImageViewer(List<String> imagePaths, int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: imagePaths.length,
              itemBuilder: (context, index) => InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.file(File(imagePaths[index]), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    final currentUser = auth is AuthAuthenticated ? auth.user : null;

    final postsAsync = ref.watch(postsNotifierProvider);
    final instantsAsync = ref.watch(instantsProvider);

    return Scaffold(
      drawer: const AppHamburgerDrawer(),
      appBar: AppBar(
        title: const Text('Personal Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: _showEditProfileModal,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Instants Header Row
          SliverToBoxAdapter(
            child: Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: instantsAsync.when(
                data: (instants) => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Create Instant Box
                    GestureDetector(
                      onTap: _openCreateInstantCamera,
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.primary, width: 2),
                              color: cs.primaryContainer,
                            ),
                            child: Icon(Icons.add_a_photo_rounded, color: cs.primary),
                          ),
                          const SizedBox(height: 4),
                          const Text('Instant', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    if (instants.isNotEmpty)
                      GestureDetector(
                        onTap: () => _openInstantsDashboard(instants),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.pink, width: 2.5),
                                image: DecorationImage(image: FileImage(File(instants.first.imagePath)), fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('Your Instants', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: Divider(height: 1)),

          // Feed Posts
          postsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (posts) {
              if (posts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dynamic_feed_rounded, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('Your feed is empty.', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _showCreatePostModal,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create First Post'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    final avatarB64 = currentUser?.avatarBase64;
                    final displayName = currentUser?.displayName ?? currentUser?.username ?? 'Me';

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: cs.surfaceContainerLow,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header User Row
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              backgroundImage: avatarB64 != null ? MemoryImage(base64Decode(avatarB64)) : null,
                              child: avatarB64 == null ? Icon(Icons.person_rounded, color: cs.primary) : null,
                            ),
                            title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (val) {
                                final notifier = ref.read(postsNotifierProvider.notifier);
                                if (val == 'pin') notifier.togglePin(post);
                                if (val == 'delete') notifier.deletePost(post.id);
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(value: 'pin', child: Text(post.isPinned ? 'Unpin' : 'Pin')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ),

                          if (post.title != null && post.title!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(post.title!, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ),

                          if (post.content.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(post.content, style: theme.textTheme.bodyMedium),
                            ),

                          // Carousel Media Gallery with Tap to Zoom
                          if (post.imagePaths.isNotEmpty)
                            SizedBox(
                              height: 280,
                              child: PageView.builder(
                                itemCount: post.imagePaths.length,
                                itemBuilder: (context, i) {
                                  final path = post.imagePaths[i];
                                  return GestureDetector(
                                    onTap: () => _openFullImageViewer(post.imagePaths, i),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(File(path), fit: BoxFit.cover),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          // Interaction Bar (Instagram style like, comment, bookmark)
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: post.isLiked ? Colors.red : cs.onSurfaceVariant),
                                onPressed: () => ref.read(postsNotifierProvider.notifier).toggleLike(post),
                              ),
                              Text('${post.likesCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline_rounded),
                                onPressed: () => _showInstagramCommentsSheet(post),
                              ),
                              Text('${post.comments.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              IconButton(
                                icon: Icon(post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: post.isSaved ? cs.primary : cs.onSurfaceVariant),
                                onPressed: () => ref.read(postsNotifierProvider.notifier).toggleSave(post),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: posts.length,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostModal,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

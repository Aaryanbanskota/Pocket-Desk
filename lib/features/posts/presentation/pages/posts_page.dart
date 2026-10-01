import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() => _isFabVisible = false);
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible) {
        setState(() => _isFabVisible = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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

    final nameCtrl = TextEditingController(
        text: auth.user.displayName ?? auth.user.username);
    String? currentAvatar = auth.user.avatarBase64;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit Profile',
                  style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final result =
                      await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null && result.files.single.path != null) {
                    final bytes =
                        await File(result.files.single.path!).readAsBytes();
                    final b64 = base64Encode(bytes);
                    setModalState(() => currentAvatar = b64);
                  }
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      backgroundImage: currentAvatar != null
                          ? MemoryImage(base64Decode(currentAvatar!))
                          : null,
                      child: currentAvatar == null
                          ? Icon(Icons.person_rounded,
                              size: 40, color: colorScheme.onSurfaceVariant)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: Color(0xFF6C5CE7), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.outline)),
                ),
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
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    minimumSize: const Size.fromHeight(48)),
                child: const Text('Save Profile', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Instants Dashboard
  // ---------------------------------------------------------------------------

  void _openInstantsDashboard(List<InstantModel> instants) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('My Instants',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_a_photo_rounded,
                        color: Colors.white),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openCreateInstantCamera();
                    },
                  ),
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            Expanded(
              child: instants.isEmpty
                  ? const Center(
                      child: Text('No Instants yet. Tap camera to create!',
                          style: TextStyle(color: Colors.white70)))
                  : PageView.builder(
                      itemCount: instants.length,
                      itemBuilder: (context, i) {
                        final inst = instants[i];
                        final hasFile = inst.imagePath.isNotEmpty &&
                            File(inst.imagePath).existsSync();
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: hasFile
                                  ? Image.file(File(inst.imagePath),
                                      fit: BoxFit.cover)
                                  : Container(
                                      color: const Color(0xFF1E293B),
                                      child: const Center(
                                        child: Icon(Icons.broken_image_rounded,
                                            color: Colors.white54, size: 48),
                                      ),
                                    ),
                            ),
                            if (inst.textOverlay != null &&
                                inst.textOverlay!.isNotEmpty)
                              Positioned(
                                left: inst.textX *
                                    MediaQuery.of(context).size.width *
                                    0.8,
                                top: inst.textY *
                                    MediaQuery.of(context).size.height *
                                    0.6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Text(inst.textOverlay!,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle),
                                child: IconButton(
                                  icon: const Icon(Icons.delete_forever_rounded,
                                      color: Colors.redAccent),
                                  tooltip: 'Delete Instant',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogCtx) => AlertDialog(
                                        title: const Text('Delete Instant?'),
                                        content: const Text(
                                            'Are you sure you want to permanently delete this Instant?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () => Navigator.pop(
                                                  dialogCtx, false),
                                              child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dialogCtx, true),
                                            child: const Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.redAccent)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref
                                          .read(instantsProvider.notifier)
                                          .deleteInstant(inst.id);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                    }
                                  },
                                ),
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

  void _openCreateInstantCamera({String? initialPath}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) => _InstantCameraModal(
        initialPath: initialPath,
        onInstantCreated: (imagePath, textOverlay, textX, textY) async {
          await ref.read(instantsProvider.notifier).createInstant(
                imagePath: imagePath,
                textOverlay: textOverlay,
                textX: textX,
                textY: textY,
              );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NEW POST SHEET
  // ---------------------------------------------------------------------------

  void _showCreatePostModal() {
    _contentCtrl.clear();
    _titleCtrl.clear();
    _tagsCtrl.clear();
    _selectedImagePaths.clear();

    final auth = ref.read(authNotifierProvider).valueOrNull;
    final currentUser = auth is AuthAuthenticated ? auth.user : null;
    final avatarB64 = currentUser?.avatarBase64;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final bottomInsets = MediaQuery.of(modalContext).viewInsets.bottom;
          return Container(
            height: MediaQuery.of(modalContext).size.height * 0.90,
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInsets + 12),
            child: Column(
              children: [
                // Top Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: colorScheme.onSurface, size: 28),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B95F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                      ),
                      onPressed: () {
                        final text = _contentCtrl.text.trim();
                        if (text.isEmpty && _selectedImagePaths.isEmpty) return;
                        final tags = _tagsCtrl.text
                            .split(',')
                            .map((t) => t.trim())
                            .where((t) => t.isNotEmpty)
                            .toList();

                        ref.read(postsNotifierProvider.notifier).createPost(
                              content: text,
                              title: _titleCtrl.text.trim().isEmpty
                                  ? null
                                  : _titleCtrl.text.trim(),
                              imagePaths: List.from(_selectedImagePaths),
                              tags: tags,
                            );

                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'POST',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Content Field Area
                Expanded(
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          backgroundImage: avatarB64 != null
                              ? MemoryImage(base64Decode(avatarB64))
                              : null,
                          child: avatarB64 == null
                              ? Icon(Icons.person_rounded,
                                  color: colorScheme.onSurfaceVariant)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _titleCtrl,
                                style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Title (optional)',
                                  hintStyle: TextStyle(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5)),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                              TextField(
                                controller: _contentCtrl,
                                maxLines: null,
                                style: TextStyle(
                                    color: colorScheme.onSurface, fontSize: 18),
                                decoration: InputDecoration(
                                  hintText: 'What\'s Happening ?',
                                  hintStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                              TextField(
                                controller: _tagsCtrl,
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Tags (e.g. daily, note, fun)',
                                  hintStyle: TextStyle(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5)),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                              if (_selectedImagePaths.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _selectedImagePaths.length,
                                    itemBuilder: (c, i) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.file(
                                              File(_selectedImagePaths[i]),
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) =>
                                                      Container(
                                                width: 120,
                                                height: 120,
                                                color: colorScheme
                                                    .surfaceContainerHighest,
                                                child: Icon(
                                                    Icons.broken_image_rounded,
                                                    color: colorScheme
                                                        .onSurfaceVariant),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () {
                                                setModalState(() {
                                                  _selectedImagePaths
                                                      .removeAt(i);
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.8),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                    Icons.close_rounded,
                                                    size: 14,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer Bar (Privacy Badge + Attachment Toolbar)
                Column(
                  children: [
                    Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 1),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.public_rounded,
                              size: 16, color: Color(0xFF8B95F6)),
                          SizedBox(width: 6),
                          Text(
                            'AI can view this post',
                            style: TextStyle(
                              color: Color(0xFF8B95F6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image_outlined,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Add Gallery Photo',
                          onPressed: () async {
                            await _pickMedia();
                            setModalState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Camera Instant',
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openCreateInstantCamera();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.mic_none_rounded,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Record Voice Audio',
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.gif_box_outlined,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Add GIF',
                          onPressed: () async {
                            await _pickMedia();
                            setModalState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.format_list_bulleted_rounded,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Add List / To-Do',
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.location_on_outlined,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Add Location Tag',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMMENT COMPOSITION & REPLY SHEET
  // ---------------------------------------------------------------------------

  void _showCommentComposerSheet(PostModel post) {
    _commentCtrl.clear();
    final auth = ref.read(authNotifierProvider).valueOrNull;
    final currentUser = auth is AuthAuthenticated ? auth.user : null;
    final avatarB64 = currentUser?.avatarBase64;
    final authorName = currentUser?.displayName ?? currentUser?.username ?? 'User';

    final hasImage = post.imagePaths.isNotEmpty && File(post.imagePaths.first).existsSync();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final bottomInsets = MediaQuery.of(modalContext).viewInsets.bottom;
          return Container(
            height: MediaQuery.of(modalContext).size.height * 0.90,
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInsets + 12),
            child: Column(
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: colorScheme.onSurface, size: 28),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B95F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                      ),
                      onPressed: () async {
                        final text = _commentCtrl.text.trim();
                        if (text.isNotEmpty) {
                          await ref
                              .read(postsNotifierProvider.notifier)
                              .addComment(post, text);
                          _commentCtrl.clear();
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      child: const Text(
                        'POST',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Parent Post Snippet & Thread Connector
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: colorScheme.surfaceContainerHighest,
                                    child: Icon(Icons.person_rounded,
                                        color: colorScheme.onSurfaceVariant, size: 20),
                                  ),
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: colorScheme.outline.withValues(alpha: 0.3),
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authorName,
                                      style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    if (post.title != null && post.title!.isNotEmpty)
                                      Text(
                                        post.title!,
                                        style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                      ),
                                    if (post.content.isNotEmpty)
                                      Text(
                                        post.content,
                                        style: TextStyle(
                                            color: colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.8),
                                            fontSize: 12),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (hasImage)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(post.imagePaths.first),
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Commenter Input Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              backgroundImage: avatarB64 != null
                                  ? MemoryImage(base64Decode(avatarB64))
                                  : null,
                              child: avatarB64 == null
                                  ? Icon(Icons.person_rounded,
                                      color: colorScheme.onSurfaceVariant)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _commentCtrl,
                                maxLines: null,
                                style: TextStyle(
                                    color: colorScheme.onSurface, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Comment something |',
                                  hintStyle: TextStyle(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                      fontSize: 16),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Footer Bar with Audio, GIF & List icons
                Column(
                  children: [
                    Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 1),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.public_rounded,
                              size: 16, color: Color(0xFF8B95F6)),
                          SizedBox(width: 6),
                          Text(
                            'AI can view this post',
                            style: TextStyle(
                              color: Color(0xFF8B95F6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.mic_none_rounded,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Record Voice Audio',
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.gif_box_outlined,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Add GIF',
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.format_list_bulleted_rounded,
                              color: Color(0xFF8B95F6), size: 24),
                          tooltip: 'Add To-Do / List',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SINGLE POST DETAILED VIEW
  // ---------------------------------------------------------------------------

  void _openPostDetailView(PostModel post) {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    final currentUser = auth is AuthAuthenticated ? auth.user : null;
    final authorName = currentUser?.displayName ?? currentUser?.username ?? 'User';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final postsState = ref.watch(postsNotifierProvider).valueOrNull ?? [];
          final currentPost =
              postsState.firstWhere((p) => p.id == post.id, orElse: () => post);
          final hasImage = currentPost.imagePaths.isNotEmpty &&
              File(currentPost.imagePaths.first).existsSync();

          return Container(
            height: MediaQuery.of(context).size.height * 0.92,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Close Bar
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: colorScheme.onSurface, size: 28),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    const SizedBox(width: 8),
                    Text('Post Detail',
                        style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: ListView(
                    children: [
                      // Author Row
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.person_rounded,
                              color: colorScheme.onSurfaceVariant),
                        ),
                        title: Text(authorName,
                            style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold)),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              color: colorScheme.onSurfaceVariant),
                          onSelected: (val) {
                            final notifier =
                                ref.read(postsNotifierProvider.notifier);
                            if (val == 'pin') {
                              notifier.togglePin(currentPost);
                            }
                            if (val == 'delete') {
                              notifier.deletePost(currentPost.id);
                              Navigator.pop(ctx);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'pin',
                              child: Text(currentPost.isPinned ? 'Unpin' : 'Pin'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),

                      // Title & Content
                      if (currentPost.title != null && currentPost.title!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            currentPost.title!,
                            style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (currentPost.content.isNotEmpty)
                        Text(
                          currentPost.content,
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant, fontSize: 14),
                        ),
                      const SizedBox(height: 12),

                      // Attached Media Container
                      if (hasImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            File(currentPost.imagePaths.first),
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Date & Total Comment Timestamp Bar
                      Text(
                        '${currentPost.createdAt.hour}:${currentPost.createdAt.minute.toString().padLeft(2, '0')} • ${currentPost.comments.length} comments',
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                            fontSize: 12),
                      ),
                      Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 20),

                      // Action Bar (Like, Comment, Bookmark)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              currentPost.isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: currentPost.isLiked
                                  ? Colors.red
                                  : colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => ref
                                .read(postsNotifierProvider.notifier)
                                .toggleLike(currentPost),
                          ),
                          IconButton(
                            icon: Icon(Icons.chat_bubble_outline_rounded,
                                color: colorScheme.onSurfaceVariant),
                            onPressed: () => _showCommentComposerSheet(currentPost),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              currentPost.isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: currentPost.isSaved
                                  ? const Color(0xFF8B95F6)
                                  : colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => ref
                                .read(postsNotifierProvider.notifier)
                                .toggleSave(currentPost),
                          ),
                        ],
                      ),
                      Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 20),

                      Text(
                        'Comments',
                        style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // List of Comments
                      if (currentPost.comments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No comments yet.',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.6)),
                            ),
                          ),
                        )
                      else
                        ...List.generate(currentPost.comments.length, (i) {
                          final author = currentPost.commentAuthors[i];
                          final comment = currentPost.comments[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: colorScheme.surfaceContainerHighest,
                                  child: Icon(Icons.person_rounded,
                                      size: 16, color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(author,
                                          style: TextStyle(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text(comment,
                                          style: TextStyle(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN FEED BUILDER
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    final currentUser = auth is AuthAuthenticated ? auth.user : null;
    final authorName = currentUser?.displayName ?? currentUser?.username ?? 'User';

    final postsAsync = ref.watch(postsNotifierProvider);
    final instantsAsync = ref.watch(instantsProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      drawer: const AppHamburgerDrawer(),
      appBar: AppBar(
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded,
                color: colorScheme.onSurface, size: 26),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Open Menu',
          ),
        ),
        title: Text(
          'Personal Feed',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_a_photo_outlined,
                color: colorScheme.onSurface, size: 22),
            onPressed: () => _openCreateInstantCamera(),
            tooltip: 'Camera / Instant',
          ),
          IconButton(
            icon: Icon(Icons.add_rounded,
                color: colorScheme.onSurface, size: 28),
            onPressed: _showCreatePostModal,
            tooltip: 'Create New Post',
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Instants Header Row
          SliverToBoxAdapter(
            child: Container(
              height: 95,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: instantsAsync.when(
                data: (instants) => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    GestureDetector(
                      onTap: _openCreateInstantCamera,
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF8B95F6), width: 2),
                              color: colorScheme.surfaceContainerHighest,
                            ),
                            child: const Icon(Icons.add_a_photo_rounded,
                                color: Color(0xFF8B95F6), size: 24),
                          ),
                          const SizedBox(height: 4),
                          Text('Insta story',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    if (instants.isNotEmpty)
                      Builder(builder: (context) {
                        final firstPath = instants.first.imagePath;
                        final hasRingFile = firstPath.isNotEmpty &&
                            File(firstPath).existsSync();
                        return GestureDetector(
                          onTap: () => _openInstantsDashboard(instants),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.pinkAccent, width: 2.5),
                                  color: colorScheme.surfaceContainerHighest,
                                  image: hasRingFile
                                      ? DecorationImage(
                                          image: FileImage(File(firstPath)),
                                          fit: BoxFit.cover)
                                      : null,
                                ),
                                child: hasRingFile
                                    ? null
                                    : const Icon(Icons.star_rounded,
                                        color: Colors.pinkAccent),
                              ),
                              const SizedBox(height: 4),
                              Text('Your Instants',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface)),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),

          SliverToBoxAdapter(child: Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 1)),

          // Feed Posts List
          postsAsync.when(
            loading: () => const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B95F6)))),
            error: (e, _) => SliverFillRemaining(
                child: Center(
                    child: Text('Error: $e',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)))),
            data: (posts) {
              if (posts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dynamic_feed_rounded,
                            size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text('Your feed is empty.',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B95F6),
                            foregroundColor: Colors.white,
                          ),
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
                    final hasImage = post.imagePaths.isNotEmpty &&
                        File(post.imagePaths.first).existsSync();

                    return InkWell(
                      onTap: () => _openPostDetailView(post),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header User Row
                            ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                backgroundImage: avatarB64 != null
                                    ? MemoryImage(base64Decode(avatarB64))
                                    : null,
                                child: avatarB64 == null
                                    ? Icon(Icons.person_rounded,
                                        color: colorScheme.onSurfaceVariant)
                                    : null,
                              ),
                              title: Text(authorName,
                                  style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold)),
                              trailing: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded,
                                    color: colorScheme.onSurfaceVariant),
                                onSelected: (val) {
                                  final notifier =
                                      ref.read(postsNotifierProvider.notifier);
                                  if (val == 'pin') {
                                    notifier.togglePin(post);
                                  }
                                  if (val == 'delete') {
                                    notifier.deletePost(post.id);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                      value: 'pin',
                                      child:
                                          Text(post.isPinned ? 'Unpin' : 'Pin')),
                                  const PopupMenuItem(
                                      value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),

                            // Post Title & Content
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (post.title != null && post.title!.isNotEmpty)
                                    Text(
                                      post.title!,
                                      style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  if (post.content.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      post.content,
                                      style: TextStyle(
                                          color: colorScheme.onSurfaceVariant, fontSize: 13),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Media Box Container (Tap image explicitly opens post detail)
                            if (hasImage)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.file(
                                    File(post.imagePaths.first),
                                    height: 240,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                            // Bottom Interaction Icons (Heart, Comment bubble, Bookmark)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      post.isLiked
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: post.isLiked
                                          ? Colors.red
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () => ref
                                        .read(postsNotifierProvider.notifier)
                                        .toggleLike(post),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                        Icons.mode_comment_outlined,
                                        color: colorScheme.onSurfaceVariant),
                                    onPressed: () =>
                                        _showCommentComposerSheet(post),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: Icon(
                                      post.isSaved
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      color: post.isSaved
                                          ? const Color(0xFF8B95F6)
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () => ref
                                        .read(postsNotifierProvider.notifier)
                                        .toggleSave(post),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isFabVisible ? 1.0 : 0.0,
        child: _isFabVisible
            ? FloatingActionButton(
                backgroundColor: const Color(0xFF8B95F6),
                onPressed: _showCreatePostModal,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              )
            : null,
      ),
    );
  }
}

class _InstantCameraModal extends StatefulWidget {
  const _InstantCameraModal({
    required this.onInstantCreated,
    this.initialPath,
  });

  final String? initialPath;
  final Future<void> Function(
          String imagePath, String? textOverlay, double textX, double textY)
      onInstantCreated;

  @override
  State<_InstantCameraModal> createState() => _InstantCameraModalState();
}

class _InstantCameraModalState extends State<_InstantCameraModal> {
  final _textCtrl = TextEditingController();
  Offset _textOffset = const Offset(80, 250);
  String _imagePath = '';
  List<CameraDescription> _availableCameras = [];
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.initialPath ?? '';
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isNotEmpty) {
        await _setupController(_availableCameras[_selectedCameraIndex]);
      } else {
        if (mounted) {
          setState(() {
            _cameraError = Platform.isLinux
                ? 'No webcam detected on Linux.\nPlease connect a USB webcam and try again.'
                : 'No camera hardware detected.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        setState(() {
          if (errStr.contains('No implementation found') ||
              errStr.contains('UnimplementedError')) {
            _cameraError = Platform.isLinux
                ? 'Camera stream plugin is not supported on Linux platform.\nUse gallery picker icon above to select images on desktop.'
                : 'Camera platform plugin missing.';
          } else {
            _cameraError = 'Unable to access camera: ${e.toString()}';
          }
        });
      }
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _cameraError = 'Failed to start camera: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(newMode);
      if (mounted) {
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      }
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (kIsWeb || Platform.isLinux) return;
    if (_availableCameras.length < 2) return;

    _selectedCameraIndex =
        (_selectedCameraIndex + 1) % _availableCameras.length;
    setState(() {
      _isCameraInitialized = false;
    });
    await _setupController(_availableCameras[_selectedCameraIndex]);
  }

  Future<void> _captureOrPost() async {
    if (_isCapturing) return;

    String finalPath = _imagePath;

    final size = MediaQuery.of(context).size;

    if (finalPath.isEmpty &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      setState(() => _isCapturing = true);
      try {
        final XFile photo = await _cameraController!.takePicture();
        finalPath = photo.path;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to capture photo: $e')),
          );
        }
        setState(() => _isCapturing = false);
        return;
      }
      setState(() => _isCapturing = false);
    }

    final normX = (_textOffset.dx / size.width).clamp(0.0, 1.0);
    final normY = (_textOffset.dy / size.height).clamp(0.0, 1.0);

    await widget.onInstantCreated(
      finalPath,
      _textCtrl.text.trim().isEmpty ? null : _textCtrl.text.trim(),
      normX,
      normY,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLinuxOrWeb = kIsWeb || Platform.isLinux;
    final canSwitchCamera = !isLinuxOrWeb && _availableCameras.length > 1;

    return Container(
      height: MediaQuery.of(context).size.height * 0.96,
      color: Colors.black,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'New Instant',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library_rounded,
                      color: Colors.white, size: 24),
                  tooltip: 'Choose from gallery',
                  onPressed: () async {
                    final pickerResult = await FilePicker.platform
                        .pickFiles(type: FileType.image);
                    if (pickerResult != null &&
                        pickerResult.files.single.path != null) {
                      setState(() {
                        _imagePath = pickerResult.files.single.path!;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(44),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_imagePath.isNotEmpty && File(_imagePath).existsSync())
                      Image.file(File(_imagePath), fit: BoxFit.cover)
                    else if (_isCameraInitialized && _cameraController != null)
                      CameraPreview(_cameraController!)
                    else
                      Container(
                        color: const Color(0xFF1E293B),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white70, size: 54),
                              const SizedBox(height: 12),
                              Text(
                                _cameraError ?? 'Initializing Camera Stream…',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      left: _textOffset.dx,
                      top: _textOffset.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _textOffset += details.delta;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _textCtrl.text.isEmpty
                                ? 'Tap top bar to type overlay text'
                                : _textCtrl.text,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: TextField(
                        controller: _textCtrl,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Type overlay text…',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.black54,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: _toggleFlash,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          _isFlashOn ? Colors.amber : const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isFlashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      color: _isFlashOn ? Colors.black : Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _captureOrPost,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.6), width: 5),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _isCapturing ? Colors.amber : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                    strokeWidth: 3, color: Colors.black),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: canSwitchCamera ? _switchCamera : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: canSwitchCamera
                          ? const Color(0xFF1E293B)
                          : Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flip_camera_ios_rounded,
                      color: canSwitchCamera ? Colors.white : Colors.white38,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

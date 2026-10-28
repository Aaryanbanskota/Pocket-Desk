import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/circular_icon_button.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../auth/data/auth_repository.dart';
import '../data/feed_repository.dart';
import 'compose_sheet.dart';
import 'instant_camera_screen.dart';

class FeedScreen extends StatefulWidget {
  final UserSession session;
  final List<MyDayFeedPost> posts;
  final List<MyDayStory> stories;
  final String activeTab; // 'all', 'media', 'saved'
  final ValueChanged<String> onTabChanged;
  final VoidCallback onCompose;
  final void Function(MyDayFeedPost) onToggleLike;
  final void Function(MyDayFeedPost) onToggleSave;
  final void Function(MyDayFeedPost, String) onAddComment;
  final void Function(MyDayFeedPost) onDeletePost;
  final void Function(String imagePath) onAddStory;
  final void Function(MyDayStory)? onDeleteStory;

  const FeedScreen({
    super.key,
    required this.session,
    required this.posts,
    required this.stories,
    required this.activeTab,
    required this.onTabChanged,
    required this.onCompose,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onAddComment,
    required this.onDeletePost,
    required this.onAddStory,
    this.onDeleteStory,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _picker = ImagePicker();

  String _formatTimeAgo(int timestamp) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }

  Future<void> _pickAndAddStory() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add to Your Story',
                style: AppTypography.h3.copyWith(color: ctx.appText),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(LucideIcons.camera, color: AppColors.accent),
                title: Text('Instant Camera', style: TextStyle(color: ctx.appText, fontWeight: FontWeight.w600)),
                subtitle: Text('Take a photo now', style: TextStyle(color: ctx.appMuted)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () => Navigator.of(ctx).pop('camera'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(LucideIcons.image, color: AppColors.accent),
                title: Text('Choose from Gallery', style: TextStyle(color: ctx.appText, fontWeight: FontWeight.w600)),
                subtitle: Text('Pick an existing photo', style: TextStyle(color: ctx.appMuted)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () => Navigator.of(ctx).pop('gallery'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'camera') {
      await InstantCameraScreen.open(
        context,
        title: 'Your Story',
        onInstantCreated: (imagePath, textOverlay) async {
          widget.onAddStory(imagePath);
        },
      );
    } else if (action == 'gallery') {
      try {
        final picked = await _picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          widget.onAddStory(picked.path);
        }
      } catch (_) {}
    }
  }

  void _openCommentSheet(MyDayFeedPost post) {
    final textController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final currentPost = widget.posts.firstWhere(
              (p) => p.id == post.id,
              orElse: () => post,
            );

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: ctx.appSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: ctx.appLine, width: 1.0)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ctx.appMuted.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Header
                      Row(
                        children: [
                          const Icon(AppIcons.messageCircle, size: 20, color: AppColors.accentOrange),
                          const SizedBox(width: 8),
                          Text(
                            'Comments (${currentPost.comments.length})',
                            style: AppTypography.h3.copyWith(color: ctx.appText),
                          ),
                          const Spacer(),
                          CircularIconButton(
                            icon: AppIcons.close,
                            size: 28,
                            iconSize: 14,
                            customColor: Colors.transparent,
                            iconColor: ctx.appMuted,
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Comments list
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.40,
                        ),
                        child: currentPost.comments.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(AppIcons.messageCircle, size: 36, color: ctx.appMuted.withValues(alpha: 0.4)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No comments yet',
                                      style: AppTypography.bodyBold.copyWith(color: ctx.appMuted),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Type below to add the first comment',
                                      style: AppTypography.captionMuted.copyWith(color: ctx.appMuted),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: currentPost.comments.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (cContext, idx) {
                                  final comment = currentPost.comments[idx];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: ctx.appSurface2,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: ctx.appLine.withValues(alpha: 0.5)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: AppColors.accentOrange.withValues(alpha: 0.2),
                                          child: Text(
                                            widget.session.name.isNotEmpty
                                                ? widget.session.name.substring(0, 1).toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.accentOrange,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.session.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: ctx.appText,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                comment,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  color: ctx.appText,
                                                  height: 1.35,
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
                      const SizedBox(height: 12),

                      // Input Bar - auto-focused, right above keyboard
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: textController,
                              autofocus: true,
                              style: TextStyle(color: ctx.appText, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Write a comment…',
                                hintStyle: TextStyle(color: ctx.appMuted),
                                filled: true,
                                fillColor: ctx.appSurface2,
                                prefixIcon: Icon(AppIcons.messageCircle, size: 16, color: ctx.appMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: ctx.appLine),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: ctx.appLine),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(24)),
                                  borderSide: BorderSide(color: AppColors.accentOrange, width: 1.5),
                                ),
                              ),
                              onSubmitted: (val) {
                                final text = val.trim();
                                if (text.isNotEmpty) {
                                  widget.onAddComment(currentPost, text);
                                  textController.clear();
                                  setSheetState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentOrange,
                            ),
                            child: IconButton(
                              icon: const Icon(AppIcons.send, size: 18, color: Colors.white),
                              onPressed: () {
                                final text = textController.text.trim();
                                if (text.isNotEmpty) {
                                  widget.onAddComment(currentPost, text);
                                  textController.clear();
                                  setSheetState(() {});
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = (widget.session.name.isNotEmpty ? widget.session.name[0] : 'U').toUpperCase();

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 26),
      children: [
        // 1. Stories Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: [
              // Add story button (.st.me in prototype)
              GestureDetector(
                onTap: _pickAndAddStory,
                child: SizedBox(
                  width: 68,
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.appSurface,
                          border: Border.all(
                            color: context.appMuted,
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Icon(AppIcons.plus, color: context.appText, size: 24),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your story',
                        style: TextStyle(color: context.appMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Existing stories with gradient rings
              for (final story in widget.stories) ...[
                GestureDetector(
                  onTap: () => _showStoryViewer(story),
                  child: SizedBox(
                    width: 68,
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.storyRingGradient,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.appBg,
                            ),
                            child: ClipOval(
                              child: _buildStoryImage(story.imagePath),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTimeAgo(story.createdAt),
                          style: TextStyle(color: context.appMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Secondary Tabs: [For you | Media | Saved]
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.appLine, width: 1.0)),
          ),
          child: Row(
            children: [
              _buildTab('all', 'For you'),
              _buildTab('media', 'Media'),
              _buildTab('saved', 'Saved'),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. Compose Bar (.cmpb in prototype)
        InkWell(
          onTap: widget.onCompose,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.appLine, width: 1.0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'What’s happening?',
                    style: TextStyle(
                      color: context.appMuted,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(AppIcons.feed, color: context.appMuted, size: 20),
              ],
            ),
          ),
        ),

        // 4. Feed Posts List
        if (widget.posts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                widget.activeTab == 'saved'
                    ? 'Nothing saved yet'
                    : 'No posts yet. Share your first moment.',
                style: AppTypography.body.copyWith(color: context.appMuted),
              ),
            ),
          )
        else
          for (final post in widget.posts) _buildPostItem(context, post, initial),
      ],
    );
  }

  Widget _buildTab(String tabKey, String label) {
    final isSelected = widget.activeTab == tabKey;
    return Expanded(
      child: InkWell(
        onTap: () => widget.onTabChanged(tabKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: isSelected
                ? const Border(bottom: BorderSide(color: AppColors.accent, width: 3.0))
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? context.appText : context.appMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, MyDayFeedPost post, String initial) {
    final isRemoteImage = post.imagePath.startsWith('http://') || post.imagePath.startsWith('https://');
    final hasLocalImage = post.imagePath.isNotEmpty && File(post.imagePath).existsSync();
    final hasImage = isRemoteImage || hasLocalImage;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appLine, width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.name,
                      style: AppTypography.bodyBold.copyWith(color: context.appText),
                    ),
                    Text(
                      '@${widget.session.handle} · ${_formatTimeAgo(post.createdAt)}',
                      style: TextStyle(color: context.appMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              CircularIconButton(
                icon: AppIcons.trash,
                size: 32,
                iconSize: 16,
                iconColor: context.appMuted,
                customColor: Colors.transparent,
                onPressed: () {
                  widget.onDeletePost(post);
                  UndoToast.show(context, message: 'Moved to Trash');
                },
              ),
            ],
          ),

          // Post Text with hashtag highlighting
          if (post.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildPostText(post.text),
          ],

          // Post Photo
          if (hasImage) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 460),
                child: _buildPostImage(post.imagePath),
              ),
            ),
          ],

          // Action Buttons: Heart, Comment, Bookmark, Share
          const SizedBox(height: 8),
          Row(
            children: [
              // Like
              InkWell(
                onTap: () => widget.onToggleLike(post),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.heart,
                        size: 18,
                        color: post.isLiked ? const Color(0xFFFF4D6D) : context.appMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        post.isLiked ? '1' : '0',
                        style: TextStyle(
                          fontSize: 13,
                          color: post.isLiked ? const Color(0xFFFF4D6D) : context.appMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Comment - 1-Click opens bottom comment sheet
              InkWell(
                onTap: () => _openCommentSheet(post),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      Icon(AppIcons.messageCircle, size: 18, color: context.appMuted),
                      const SizedBox(width: 6),
                      Text(
                        post.comments.isNotEmpty ? '${post.comments.length}' : '',
                        style: TextStyle(fontSize: 13, color: context.appMuted),
                      ),
                    ],
                  ),
                ),
              ),

              // Save
              InkWell(
                onTap: () => widget.onToggleSave(post),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Icon(
                    AppIcons.bookmark,
                    size: 18,
                    color: post.isSaved ? context.appText : context.appMuted,
                  ),
                ),
              ),

              const Spacer(),

              // Share
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: post.text));
                  UndoToast.show(context, message: 'Copied to clipboard');
                },
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Icon(AppIcons.share, size: 18, color: context.appMuted),
                ),
              ),
            ],
          ),

          // Comments Preview Bar (1-Click opens modern comment sheet)
          if (post.comments.isNotEmpty) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _openCommentSheet(post),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Latest comment highlight
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.session.name}: ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.appText,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            post.comments.last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.appText.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'View all ${post.comments.length} comment${post.comments.length == 1 ? '' : 's'}',
                          style: AppTypography.captionMuted.copyWith(
                            color: context.appMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(AppIcons.forward, size: 12, color: context.appMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () => _openCommentSheet(post),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(AppIcons.messageCircle, size: 14, color: context.appMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Add a comment…',
                      style: TextStyle(color: context.appMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, String>? get _authHeaders {
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token != null && token.isNotEmpty) {
        return {
          'Authorization': 'Bearer $token',
          'apikey': SupabaseAuthService.anonKey,
        };
      }
    } catch (_) {}
    return {'apikey': SupabaseAuthService.anonKey};
  }

  void _showStoryViewer(MyDayStory story) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: context.appBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.appLine),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: context.appSurface,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Instant Story · ${_formatTimeAgo(story.createdAt)}',
                              style: TextStyle(
                                color: context.appText,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (widget.onDeleteStory != null)
                            IconButton(
                              icon: const Icon(AppIcons.trash, color: Colors.redAccent, size: 20),
                              tooltip: 'Delete Story',
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                widget.onDeleteStory!(story);
                              },
                            ),
                          IconButton(
                            icon: Icon(AppIcons.x, color: context.appMuted, size: 20),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 520),
                      child: _buildStoryImage(story.imagePath),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoryImage(String imagePath) {
    if (imagePath.isNotEmpty && !imagePath.startsWith('http') && File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: context.appSurface2),
      );
    }
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        headers: _authHeaders,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: context.appSurface2,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentOrange,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) {
          return Image.network(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: context.appSurface2),
          );
        },
      );
    }
    return Container(color: context.appSurface2);
  }

  Widget _buildPostImage(String imagePath) {
    if (imagePath.isNotEmpty && !imagePath.startsWith('http') && File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: double.infinity,
        fit: BoxFit.cover,
        headers: _authHeaders,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 220,
            width: double.infinity,
            color: context.appSurface2,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentOrange,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) {
          return Image.network(
            imagePath,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPostText(String text) {
    final words = text.split(' ');
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 15.5,
          color: context.appText,
          height: 1.5,
        ),
        children: words.map((w) {
          if (w.startsWith('#') && w.length > 1) {
            return TextSpan(
              text: '$w ',
              style: const TextStyle(
                color: Color(0xFF4AA3FF),
                fontWeight: FontWeight.w600,
              ),
            );
          }
          return TextSpan(text: '$w ');
        }).toList(),
      ),
    );
  }
}

class FeedPage extends StatefulWidget {
  final FeedRepository feedRepository;
  final UserSession session;
  final VoidCallback onCompose;
  final VoidCallback? onDataChanged;

  const FeedPage({
    super.key,
    required this.feedRepository,
    required this.session,
    required this.onCompose,
    this.onDataChanged,
  });

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<MyDayFeedPost> _posts = [];
  List<MyDayStory> _stories = [];
  String _activeTab = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final posts = await widget.feedRepository
          .getPosts(widget.session.accountId, tab: _activeTab)
          .timeout(const Duration(seconds: 2));
      final stories = await widget.feedRepository
          .getStories(widget.session.accountId)
          .timeout(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _posts = posts;
          _stories = stories;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onTabChanged(String tab) {
    setState(() => _activeTab = tab);
    _loadData();
  }

  Future<void> _onToggleLike(MyDayFeedPost post) async {
    await widget.feedRepository.toggleLike(post.id, post.isLiked);
    _loadData();
    widget.onDataChanged?.call();
  }

  Future<void> _onToggleSave(MyDayFeedPost post) async {
    await widget.feedRepository.toggleSave(post.id, post.isSaved);
    _loadData();
    widget.onDataChanged?.call();
    if (mounted) {
      UndoToast.show(
        context,
        message: post.isSaved ? 'Removed from saved' : 'Saved',
      );
    }
  }

  Future<void> _onAddComment(MyDayFeedPost post, String text) async {
    await widget.feedRepository.addCommentSimple(post.id, text);
    _loadData();
    widget.onDataChanged?.call();
  }

  Future<void> _onDeletePost(MyDayFeedPost post) async {
    await widget.feedRepository.deletePost(post.id);
    _loadData();
    widget.onDataChanged?.call();
    if (mounted) {
      UndoToast.show(
        context,
        message: 'Post deleted',
        actionLabel: 'Undo',
        onUndo: () async {
          await widget.feedRepository.restorePost(post.id);
          _loadData();
          widget.onDataChanged?.call();
        },
      );
    }
  }

  Future<void> _onAddStory(String imagePath) async {
    await widget.feedRepository.createStory(
      accountId: widget.session.accountId,
      imageUrl: imagePath,
    );
    _loadData();
    widget.onDataChanged?.call();
    if (mounted) {
      UndoToast.show(context, message: 'Story added');
    }
  }

  Future<void> _onDeleteStory(MyDayStory story) async {
    await widget.feedRepository.deleteStory(story.id);
    _loadData();
    widget.onDataChanged?.call();
    if (mounted) {
      UndoToast.show(context, message: 'Story deleted');
    }
  }

  void _openCompose() {
    ComposeSheet.showForAccount(
      context: context,
      feedRepository: widget.feedRepository,
      accountId: widget.session.accountId,
      authorName: widget.session.name,
      onPostCreated: () {
        _loadData();
        widget.onDataChanged?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
    }

    return RefreshIndicator(
      color: AppColors.accentOrange,
      backgroundColor: context.appSurface,
      onRefresh: () async {
        widget.onDataChanged?.call();
        await _loadData();
      },
      child: FeedScreen(
        session: widget.session,
        posts: _posts,
        stories: _stories,
        activeTab: _activeTab,
        onTabChanged: _onTabChanged,
        onCompose: _openCompose,
        onToggleLike: _onToggleLike,
        onToggleSave: _onToggleSave,
        onAddComment: _onAddComment,
        onDeletePost: _onDeletePost,
        onAddStory: _onAddStory,
        onDeleteStory: _onDeleteStory,
      ),
    );
  }
}


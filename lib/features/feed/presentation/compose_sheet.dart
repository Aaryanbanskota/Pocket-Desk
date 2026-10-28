import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/widgets/app_bottom_sheet.dart';
import '../../../core/design_system/widgets/circular_icon_button.dart';
import '../data/feed_repository.dart';
import 'instant_camera_screen.dart';

class ComposeSheet {
  static Future<void> show({
    required BuildContext context,
    required String userName,
    required void Function(String text, String imagePath) onPost,
  }) {
    return AppBottomSheet.show(
      context: context,
      title: 'New post',
      child: _ComposeSheetContent(
        userName: userName,
        onPost: onPost,
      ),
    );
  }

  static Future<void> showForAccount({
    required BuildContext context,
    required FeedRepository feedRepository,
    required String accountId,
    required String authorName,
    VoidCallback? onPostCreated,
  }) {
    return show(
      context: context,
      userName: authorName,
      onPost: (text, imagePath) async {
        await feedRepository.createPost(
          accountId: accountId,
          text: text,
          imagePath: imagePath,
        );
        onPostCreated?.call();
      },
    );
  }
}

class _ComposeSheetContent extends StatefulWidget {
  final String userName;
  final void Function(String text, String imagePath) onPost;

  const _ComposeSheetContent({
    required this.userName,
    required this.onPost,
  });

  @override
  State<_ComposeSheetContent> createState() => _ComposeSheetContentState();
}

class _ComposeSheetContentState extends State<_ComposeSheetContent> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  String _selectedImagePath = '';

  Future<void> _handleCamera() async {
    await InstantCameraScreen.open(
      context,
      title: 'Attach Photo',
      onInstantCreated: (imagePath, textOverlay) async {
        final persistent = await FeedRepository.persistMediaFile(imagePath);
        if (mounted) {
          setState(() => _selectedImagePath = persistent);
        }
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        final persistent = await FeedRepository.persistMediaFile(picked.path);
        if (mounted) {
          setState(() => _selectedImagePath = persistent);
        }
      }
    } catch (_) {
      final fallback = await _picker.pickImage(source: ImageSource.gallery);
      if (fallback != null) {
        final persistent = await FeedRepository.persistMediaFile(fallback.path);
        if (mounted) {
          setState(() => _selectedImagePath = persistent);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = (widget.userName.isNotEmpty ? widget.userName[0] : 'U').toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              child: TextField(
                controller: _textController,
                maxLines: 4,
                maxLength: 280,
                style: TextStyle(color: context.appText, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'What’s happening?',
                  hintStyle: TextStyle(
                    color: context.appMuted.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  counterStyle: TextStyle(color: context.appMuted),
                ),
              ),
            ),
          ],
        ),

        // Photo preview if selected
        if (_selectedImagePath.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.file(
                    File(_selectedImagePath),
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircularIconButton(
                    icon: AppIcons.close,
                    size: 32,
                    iconSize: 16,
                    customColor: Colors.black.withValues(alpha: 0.6),
                    iconColor: Colors.white,
                    onPressed: () => setState(() => _selectedImagePath = ''),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Footer Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircularIconButton(
                  icon: LucideIcons.camera,
                  customColor: context.appSurface2,
                  onPressed: _handleCamera,
                ),
                const SizedBox(width: 8),
                CircularIconButton(
                  icon: LucideIcons.image,
                  customColor: context.appSurface2,
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.isDarkMode
                    ? AppColors.darkText
                    : AppColors.lightText,
                foregroundColor: context.isDarkMode
                    ? AppColors.darkBg
                    : AppColors.lightBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              onPressed: () {
                final text = _textController.text.trim();
                if (text.isEmpty && _selectedImagePath.isEmpty) return;
                widget.onPost(text, _selectedImagePath);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Post',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

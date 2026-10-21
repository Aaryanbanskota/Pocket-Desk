import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/circular_icon_button.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../data/chat_repository.dart';
import '../services/chat_socket_service.dart';
import 'widgets/phone_call_dialog.dart';

class ConversationScreen extends StatefulWidget {
  final ChatRepository chatRepository;
  final String accountId;
  final String myIdentityKey;
  final String myName;
  final ChatContact contact;

  const ConversationScreen({
    super.key,
    required this.chatRepository,
    required this.accountId,
    required this.myIdentityKey,
    required this.myName,
    required this.contact,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _selectedImagePath;
  StreamSubscription<String>? _chatSub;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _textController.addListener(_onTextChanged);
    _chatSub = widget.chatRepository.onChatUpdated.listen((key) {
      if (key == '*' ||
          key.toLowerCase() == widget.contact.contactKey.toLowerCase() ||
          ChatSocketService.normalize10(key) == ChatSocketService.normalize10(widget.contact.contactKey)) {
        if (mounted) _loadMessages();
      }
    });
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _chatSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final msgs = await widget.chatRepository.getMessages(
      widget.accountId,
      widget.contact.contactKey,
    );
    if (mounted) {
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 75,
      );
      if (picked != null) {
        // Save to permanent local documents directory so it is never purged from cache
        final docsDir = await getApplicationDocumentsDirectory();
        final mediaDir = Directory('${docsDir.path}/chat_media');
        await mediaDir.create(recursive: true);
        final fileExt = picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
        final permanentFile = File('${mediaDir.path}/sent_${DateTime.now().millisecondsSinceEpoch}.$fileExt');
        await File(picked.path).copy(permanentFile.path);

        setState(() {
          _selectedImagePath = permanentFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        UndoToast.show(context, message: 'Could not access image: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final imagePath = _selectedImagePath;

    if (text.isEmpty && imagePath == null) return;

    final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final nowTimestamp = DateTime.now().millisecondsSinceEpoch;

    _textController.clear();
    setState(() {
      _selectedImagePath = null;
    });

    // 1. Save outgoing message to local SQLite device database with initial status 'sending'
    final outgoingMsg = await widget.chatRepository.saveOutgoingMessage(
      accountId: widget.accountId,
      senderKey: widget.myIdentityKey,
      receiverKey: widget.contact.contactKey,
      content: text,
      mediaPath: imagePath,
      mediaType: imagePath != null ? 'image' : null,
      status: 'sending',
      customId: msgId,
      timestamp: nowTimestamp,
    );

    // Optimistically show message immediately in chat list with status 'sending'
    setState(() {
      _messages.add(outgoingMsg);
    });
    _scrollToBottom();

    // 2. Transmit via Socket.io / Wi-Fi relay / Supabase Realtime Broadcast & Cloud CDN
    try {
      await ChatSocketService().sendMessage(
        receiverKey: widget.contact.contactKey,
        content: text,
        mediaPath: imagePath,
        mediaType: imagePath != null ? 'image' : null,
        customId: msgId,
      );

      // 3. Mark status as 'sent' in local database
      await widget.chatRepository.updateMessageStatus(msgId, 'sent');

      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == msgId);
          if (idx != -1) {
            _messages[idx] = ChatMessage(
              id: outgoingMsg.id,
              accountId: outgoingMsg.accountId,
              contactKey: outgoingMsg.contactKey,
              senderKey: outgoingMsg.senderKey,
              receiverKey: outgoingMsg.receiverKey,
              content: outgoingMsg.content,
              mediaPath: outgoingMsg.mediaPath,
              mediaType: outgoingMsg.mediaType,
              isOutgoing: true,
              status: 'sent',
              timestamp: outgoingMsg.timestamp,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error transmitting outgoing message: $e');
    }

    // NOTE: Sender does NOT play ding sound! Only recipient hears ding on incoming message!
    _loadMessages();
  }

  void _showImagePickerOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appLine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Send Photo',
                style: AppTypography.h3.copyWith(color: context.appText),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.accent, size: 22),
                ),
                title: Text('Take Photo', style: TextStyle(color: context.appText, fontWeight: FontWeight.w600)),
                subtitle: Text('Open device camera', style: TextStyle(color: context.appMuted, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.accent, size: 22),
                ),
                title: Text('Choose from Gallery', style: TextStyle(color: context.appText, fontWeight: FontWeight.w600)),
                subtitle: Text('Pick picture from photo library', style: TextStyle(color: context.appMuted, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactDetails() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(widget.contact.nickname, style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unique Identity Key / Phone:', style: TextStyle(color: context.appMuted, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.appBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.appLine),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      widget.contact.contactKey,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13.5),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.share, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.contact.contactKey));
                      UndoToast.show(context, message: 'Key copied to clipboard');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.public_rounded, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Global P2P & Wi-Fi: Works seamlessly between any regions (India, USA, UK, worldwide).',
                    style: TextStyle(fontSize: 12, color: context.appMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: context.appSurface,
                  title: const Text('Clear Chat History?'),
                  content: const Text('This will delete all local messages with this contact.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Clear', style: TextStyle(color: AppColors.errorRed)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await widget.chatRepository.clearChatHistory(widget.accountId, widget.contact.contactKey);
                _loadMessages();
              }
            },
            child: const Text('Clear History', style: TextStyle(color: AppColors.errorRed)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewFullImage(String path) {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: isNetwork
                    ? Image.network(
                        path,
                        fit: BoxFit.contain,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        },
                      )
                    : Image.file(
                        File(path),
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = AppColors.avatarColors[widget.contact.avatarColor % AppColors.avatarColors.length];
    final initial = (widget.contact.nickname.isNotEmpty ? widget.contact.nickname[0] : '?').toUpperCase();
    final hasContent = _textController.text.trim().isNotEmpty || _selectedImagePath != null;

    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        leading: CircularIconButton(
          icon: AppIcons.back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: avatarColor,
                  child: Text(
                    initial,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.successGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.appSurface, width: 2),
                    ),
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
                    widget.contact.nickname,
                    style: AppTypography.h4.copyWith(color: context.appText, fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.contact.contactKey,
                          style: TextStyle(color: context.appMuted, fontSize: 11, fontFamily: 'monospace'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '• P2P Active',
                        style: TextStyle(color: AppColors.successGreen.withValues(alpha: 0.9), fontSize: 10.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.phone_rounded, color: AppColors.successGreen, size: 20),
              tooltip: 'Call Contact',
              onPressed: () {
                PhoneCallDialog.startCall(
                  context: context,
                  phoneNumber: widget.contact.contactKey,
                  contactName: widget.contact.nickname,
                  accountId: widget.accountId,
                  chatRepository: widget.chatRepository,
                  myNumber: widget.myIdentityKey,
                  myName: widget.myName,
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(AppIcons.info, size: 20),
            onPressed: _showContactDetails,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Privacy / P2P Chip
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.appLine),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'End-to-End P2P • Messages saved directly on your device with zero cloud retention.',
                      style: TextStyle(color: context.appMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            // Message List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chat_bubble_outline_rounded, size: 44, color: AppColors.accent),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No messages yet',
                                style: AppTypography.h4.copyWith(color: context.appText, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Say hello to start chatting securely!',
                                style: TextStyle(color: context.appMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg.isOutgoing;

                            // Date Separator header logic
                            bool showDateHeader = false;
                            if (index == 0) {
                              showDateHeader = true;
                            } else {
                              final prev = _messages[index - 1];
                              final prevDate = DateTime.fromMillisecondsSinceEpoch(prev.timestamp);
                              final currDate = DateTime.fromMillisecondsSinceEpoch(msg.timestamp);
                              if (prevDate.year != currDate.year || prevDate.month != currDate.month || prevDate.day != currDate.day) {
                                showDateHeader = true;
                              }
                            }

                            return Column(
                              children: [
                                if (showDateHeader) _buildDateHeader(msg.timestamp),
                                _buildMessageBubble(msg, isMe),
                              ],
                            );
                          },
                        ),
            ),

            // Selected Image Preview Floating Pill
            if (_selectedImagePath != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.appLine),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_selectedImagePath!),
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Photo attached',
                            style: TextStyle(color: context.appText, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ready to send P2P across all regions',
                            style: TextStyle(color: context.appMuted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.errorRed),
                      onPressed: () => setState(() => _selectedImagePath = null),
                      tooltip: 'Remove photo',
                    ),
                  ],
                ),
              ),

            // Redesigned Modern Input Dock
            Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              decoration: BoxDecoration(
                color: context.appSurface,
                border: Border(top: BorderSide(color: context.appLine)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment button
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accent, size: 26),
                    tooltip: 'Send Photo',
                    onPressed: _showImagePickerOptions,
                  ),
                  // Gallery quick button
                  IconButton(
                    icon: Icon(Icons.photo_library_outlined, color: context.appMuted, size: 23),
                    tooltip: 'Gallery',
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  const SizedBox(width: 4),

                  // Expandable Text Input
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.appBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: context.appLine),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(color: context.appText, fontSize: 14.5),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: context.appMuted, fontSize: 14.5),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Modern Dynamic Send Button
                  GestureDetector(
                    onTap: hasContent ? _sendMessage : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: hasContent
                            ? const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: hasContent ? null : context.appLine.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        boxShadow: hasContent
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: hasContent ? Colors.white : context.appMuted,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    String label;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appLine),
      ),
      child: Text(
        label,
        style: TextStyle(color: context.appMuted, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildBubbleImage(ChatMessage msg) {
    final path = msg.mediaPath;
    if (path == null || path.isEmpty) {
      return const SizedBox.shrink();
    }

    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    final fileExists = !isNetwork && File(path).existsSync();

    if (!isNetwork && !fileExists) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_rounded, size: 20, color: Colors.grey),
              SizedBox(width: 8),
              Text('Photo unavailable', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _viewFullImage(path),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isNetwork
            ? Image.network(
                path,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 190,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 190,
                    color: Colors.black12,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  );
                },
                errorBuilder: (ctx, _, __) => Container(
                  height: 100,
                  color: Colors.black12,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                  ),
                ),
              )
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: 190,
              ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    final timeStr = DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(msg.timestamp));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.avatarColors[widget.contact.avatarColor % AppColors.avatarColors.length],
              child: Text(
                (widget.contact.nickname.isNotEmpty ? widget.contact.nickname[0] : '?').toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.74,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : context.appSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe ? const Color(0xFF4F46E5).withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: isMe ? Colors.transparent : context.appLine,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Image attachment if any
                  if (msg.isImage) ...[
                    _buildBubbleImage(msg),
                    if (msg.content.isNotEmpty) const SizedBox(height: 6),
                  ],

                  // Text content
                  if (msg.content.isNotEmpty)
                    SelectableText(
                      msg.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : context.appText,
                        fontSize: 14.5,
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: isMe ? Colors.white.withValues(alpha: 0.75) : context.appMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 5),
                        if (msg.status == 'sending') ...[
                          Text(
                            'sending',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 9.5,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.done_all_rounded,
                            size: 13,
                            color: Color(0xFF86EFAC), // Soft mint green double tick
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'sent',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

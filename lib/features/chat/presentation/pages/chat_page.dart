import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketdesk/core/services/p2p_sync_service.dart';
import 'package:pocketdesk/core/theme/app_spacing.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pocketdesk/features/settings/presentation/providers/ai_settings_notifier.dart';
import 'package:pocketdesk/features/dashboard/presentation/widgets/app_hamburger_drawer.dart';

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isMe = true,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isMe;
}

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _friendCodeCtrl = TextEditingController();
  final TextEditingController _msgCtrl = TextEditingController();

  String? _myFriendCode;
  String? _activePeerName;
  bool _isAITyping = false;

  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _myFriendCode = P2PSyncService().deviceId ?? 'PD-882190';
  }

  void _addFriend() {
    final code = _friendCodeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _activePeerName = 'Peer ($code)';
    });
    _friendCodeCtrl.clear();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connected to friend $code!')),
    );
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final authState = ref.read(authNotifierProvider).valueOrNull;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final username = user?.displayName ?? user?.username ?? 'User';

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _myFriendCode!,
      senderName: username,
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
    );

    setState(() {
      _messages.add(userMsg);
    });

    _msgCtrl.clear();

    // Broadcast over P2P sync service
    P2PSyncService().queueSyncEvent(
      type: 'chat',
      payload: {
        'id': userMsg.id,
        'sender': userMsg.senderId,
        'text': userMsg.text,
      },
    );

    // If no active peer is connected, Pocketdesk AI acts as a friend!
    if (_activePeerName == null) {
      await _generateAIReply(userMsg, username);
    }
  }

  Future<void> _generateAIReply(ChatMessage userMsg, String username) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    final userId = auth is AuthAuthenticated ? auth.user.id : 0;
    final aiSettings = await ref.read(aiSettingsRepositoryProvider.future).then((r) => r.getOrCreateSettings(userId));

    if (!aiSettings.isEnabled || aiSettings.apiKey.trim().isEmpty) {
      // Fallback friendly message if AI is not enabled or no API key set
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'ai',
          senderName: 'Pocketdesk AI 🤖',
          text: 'yo $username! I am your AI friend. To enable real-time AI replies here, make sure to add your OpenRouter API key in Settings → AI.',
          timestamp: DateTime.now(),
          isMe: false,
        ));
      });
      return;
    }

    setState(() => _isAITyping = true);

    final historyContext = _messages.take(6).map((m) => '${m.senderName}: ${m.text}').join('\n');
    final prompt = 'Chat history:\n$historyContext\n$username: ${userMsg.text}';
    final systemPrompt = 'You are Pocketdesk AI, a close, casual, super friendly companion and buddy to $username. Always start your response or address the user warmly using "yo $username". Be relaxed, supportive, informal, and fun! Keep your replies concise (1-3 casual sentences).';

    final reply = await ref.read(aiSettingsProvider.notifier).generateCompletion(
      prompt: prompt,
      systemPrompt: systemPrompt,
    );

    if (!mounted) return;
    setState(() {
      _isAITyping = false;
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'ai',
        senderName: 'Pocketdesk AI 🤖',
        text: reply ?? 'yo $username! Something went wrong reaching OpenRouter, but I am still right here for you buddy!',
        timestamp: DateTime.now(),
        isMe: false,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final username = user?.displayName ?? user?.username ?? 'User';

    return Scaffold(
      drawer: const AppHamburgerDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_activePeerName ?? 'Chat with Pocketdesk AI 🤖'),
            Text(
              _activePeerName != null ? 'P2P Connected • Code: $_myFriendCode' : 'AI Companion Mode (yo $username)',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add P2P Friend',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Add Friend Code'),
                  content: TextField(
                    controller: _friendCodeCtrl,
                    decoration: const InputDecoration(hintText: 'Enter Friend Code / Device ID'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    FilledButton(onPressed: _addFriend, child: const Text('Connect P2P')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mark_chat_read_rounded, size: 60, color: colorScheme.primary.withOpacity(0.6)),
                          const SizedBox(height: 12),
                          Text(
                            'yo $username!',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No peer connected right now. Say hi to Pocketdesk AI — your 24/7 buddy!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                          decoration: BoxDecoration(
                            color: msg.isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(msg.isMe ? 16 : 2),
                              bottomRight: Radius.circular(msg.isMe ? 2 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!msg.isMe)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    msg.senderName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: msg.isMe ? colorScheme.onPrimary : colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (_isAITyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Text('Pocketdesk AI is typing…', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type a message to $username\'s buddy…',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketdesk/core/services/p2p_sync_service.dart';
import 'package:pocketdesk/core/theme/app_spacing.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pocketdesk/features/settings/presentation/providers/ai_settings_notifier.dart';
import 'package:pocketdesk/features/dashboard/presentation/widgets/app_hamburger_drawer.dart';
import 'package:pocketdesk/features/chat/presentation/widgets/ai_cardano_dots_widget.dart';

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
          senderName: 'Pocketdesk AI',
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
    const systemPrompt = '''
You are Pocketdesk AI, the official built-in companion and assistant for Pocketdesk. Always address the user warmly (e.g. "yo <username>"). Be casual, helpful, clear, and friendly!

You have complete knowledge of Pocketdesk's capabilities:
1. Calendar & Events: View day/week/month/year/agenda layouts, create recurring events, search events, set custom reminders.
2. Clock & Timers: Set custom time alarms, minute/second countdown timers with notifications, world clock, and high-precision stopwatch.
3. Money Tracker: Manage wallet balance, record expenses by category/tags, view Spending Score (out of 100), spending status, and generate AI Money Reports.
4. P2P File Share: Send files directly between paired phones, tablets, and computers over local Wi-Fi or device IDs without cloud limits.
5. Notes & Tasks: Create rich notes, filter by folder/tags, track task deadlines, priority levels, and completion status.
6. Settings & AI Setup: Users can enable AI in Settings → AI, enter their OpenRouter API key, test connectivity, and toggle permissions.

If the user asks how to use any feature, locate a page, or set up AI, guide them step-by-step in 1-3 casual, easy-to-follow sentences.
''';

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
        senderName: 'Pocketdesk AI',
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
        title: Row(
          children: [
            if (_activePeerName == null) ...[
              AiCardanoDotsWidget(size: 28, color: colorScheme.primary, animate: _isAITyping),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _activePeerName ?? 'Pocketdesk AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _activePeerName != null ? 'P2P Connected • Code: $_myFriendCode' : 'AI Matrix Companion Mode (yo $username)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
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
                          AiCardanoDotsWidget(size: 110, color: colorScheme.primary, animate: true),
                          const SizedBox(height: 20),
                          Text(
                            'yo $username!',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                          ),
                          const SizedBox(height: 8),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!msg.isMe) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 4, right: 8),
                                child: AiCardanoDotsWidget(size: 24, color: colorScheme.primary, animate: false),
                              ),
                            ],
                            Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
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
                          ],
                        ),
                      );
                    },
                  ),
          ),

          if (_isAITyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  AiCardanoDotsWidget(size: 22, color: colorScheme.primary, animate: true),
                  const SizedBox(width: 10),
                  Text('Pocketdesk AI is processing…', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
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
                      hintText: 'Type a message to $username\'s AI buddy…',
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


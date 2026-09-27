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

You have full authority to perform actions on behalf of the user across Pocketdesk features (EXCEPT Personal Feed):
1. Tasks: Create or edit tasks.
2. Notes: Create or edit notes.
3. Calendar & Events: Create or edit calendar events.
4. Money Tracker: Log expenses or update wallet.

IF THE USER ASKS YOU TO CREATE, ADD, OR LOG SOMETHING (e.g. "Add a task to buy groceries", "Remind me to call John tomorrow", "Log 50 rs expense for coffee", "Create note about project ideas"):
You MUST return a JSON action block at the END of your response formatted exactly like this:
```json
{
  "action": "create_task" | "create_note" | "create_event" | "add_expense",
  "data": { ... }
}
```

Field details for action data:
- create_task: {"title": "...", "description": "...", "dueDate": "YYYY-MM-DD HH:mm"}
- create_note: {"title": "...", "content": "...", "folder": "..."}
- create_event: {"title": "...", "startTime": "YYYY-MM-DD HH:mm", "endTime": "YYYY-MM-DD HH:mm", "location": "..."}
- add_expense: {"title": "...", "amount": 100.0, "category": "Food/Bills/etc", "date": "YYYY-MM-DD"}

DO NOT outputs malicious code or scripts in data fields. Make sure title/content are clean text.
Always include a friendly confirmation sentence before the JSON block explaining what you did!
''';

    final reply = await ref.read(aiSettingsProvider.notifier).generateCompletion(
      prompt: prompt,
      systemPrompt: systemPrompt,
    );

    if (!mounted) return;

    String cleanText = reply ?? 'yo $username! Something went wrong reaching OpenRouter, but I am still right here for you buddy!';
    
    // Check if reply contains a JSON action block to execute on user's behalf
    if (reply != null && reply.contains('```json')) {
      try {
        final jsonMatch = RegExp(r'```json\s*(\{.*?\})\s*```', dotAll: true).firstMatch(reply);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(1);
          if (jsonStr != null) {
            final Map<String, dynamic> actionMap = jsonDecode(jsonStr);
            final String? action = actionMap['action'];
            final Map<String, dynamic>? data = actionMap['data'];

            if (action != null && data != null) {
              await _executeAIAction(action, data);
            }
          }
        }
      } catch (e) {
        // Safe handling: ignore invalid JSON without crashing
      }
      cleanText = cleanText.replaceAll(RegExp(r'```json\s*\{.*?\}\s*```', dotAll: true), '').trim();
    }

    setState(() {
      _isAITyping = false;
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'ai',
        senderName: 'Pocketdesk AI',
        text: cleanText.isEmpty ? 'Action performed successfully!' : cleanText,
        timestamp: DateTime.now(),
        isMe: false,
      ));
    });
  }

  Future<void> _executeAIAction(String action, Map<String, dynamic> data) async {
    // Sanitize title / string inputs to ensure no unsafe scripts or malformed data
    String sanitize(dynamic val) => (val ?? '').toString().replaceAll(RegExp(r'<script.*?>.*?</script>', caseSensitive: false), '').trim();

    try {
      if (action == 'create_task') {
        final title = sanitize(data['title']);
        if (title.isNotEmpty) {
          final desc = sanitize(data['description']);
          DateTime? dueDate;
          if (data['dueDate'] != null) {
            dueDate = DateTime.tryParse(data['dueDate'].toString());
          }
          await ref.read(tasksNotifierProvider.notifier).addOrUpdateTask(
            title: title,
            description: desc.isEmpty ? null : desc,
            dueDate: dueDate,
          );
        }
      } else if (action == 'create_note') {
        final title = sanitize(data['title']);
        if (title.isNotEmpty) {
          final content = sanitize(data['content']);
          final folder = sanitize(data['folder']);
          await ref.read(notesNotifierProvider.notifier).addOrUpdateNote(
            title: title,
            content: content,
            folder: folder.isEmpty ? null : folder,
          );
        }
      } else if (action == 'create_event') {
        final title = sanitize(data['title']);
        if (title.isNotEmpty) {
          final start = DateTime.tryParse(data['startTime'].toString()) ?? DateTime.now().add(const Duration(hours: 1));
          final end = DateTime.tryParse(data['endTime'].toString()) ?? start.add(const Duration(hours: 1));
          final loc = sanitize(data['location']);
          await ref.read(calendarEventsNotifierProvider.notifier).addOrUpdateEvent(
            title: title,
            startTime: start,
            endTime: end,
            location: loc.isEmpty ? null : loc,
          );
        }
      } else if (action == 'add_expense') {
        final title = sanitize(data['title']);
        final amt = double.tryParse(data['amount'].toString()) ?? 0.0;
        if (title.isNotEmpty && amt > 0) {
          final cat = sanitize(data['category']);
          final date = DateTime.tryParse(data['date'].toString()) ?? DateTime.now();
          await ref.read(moneyNotifierProvider.notifier).addExpense(
            title: title,
            amount: amt,
            category: cat.isEmpty ? 'General' : cat,
            date: date,
          );
        }
      }
    } catch (e) {
      // Safe fallback preventing app crash on malformed AI parameters
    }
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


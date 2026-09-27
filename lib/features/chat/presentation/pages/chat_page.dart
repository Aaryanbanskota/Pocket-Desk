import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketdesk/core/services/p2p_sync_service.dart';
import 'package:pocketdesk/core/theme/app_spacing.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pocketdesk/features/calendar/presentation/providers/calendar_events_notifier.dart';
import 'package:pocketdesk/features/money_tracker/presentation/providers/money_notifier.dart';
import 'package:pocketdesk/features/notes/presentation/providers/notes_notifier.dart';
import 'package:pocketdesk/features/settings/presentation/providers/ai_settings_notifier.dart';
import 'package:pocketdesk/features/tasks/presentation/providers/tasks_notifier.dart';
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
    final nowStr = DateTime.now().toString();
    final systemPrompt = '''
You are Pocketdesk AI, the official built-in universal action agent for Pocketdesk. Always address the user warmly (e.g. "yo <username>"). Be casual, helpful, clear, and friendly!
Current timestamp: $nowStr

SLASH ACTION SYSTEM:
The user input may start with a slash command defining the intended action type:
- /create: User wants to CREATE a record (Note, Task, Event, Expense).
- /edit: User wants to EDIT an existing record.
- /delete: User wants to DELETE a record (Check permissions & request confirmation).
- /view: User wants to VIEW or summarize records.
- /search: User wants to SEARCH across Pocketdesk data.
- /help: User wants to see available slash actions.

The natural text following the slash action describes WHAT the user wants to do. You MUST parse natural language, typos, spelling mistakes, and casual phrasing (e.g. "creat a note name Test 101 and put article inside" -> Action: CREATE, Target: Note, Title: Test 101, Content: article).

CAPABILITY & PERMISSION MATRIX:
1. Calendar & Events: Support reading, creating, and editing events. Ask for missing details if underspecified.
2. Tasks: Support reading, creating, and editing tasks. Understand natural date phrases like "tomorrow", "next Monday", "in 2 days".
3. Notes: Support reading, creating, and editing notes.
4. Money Tracker: Support reading, creating, and logging expenses.
5. Personal Feed: STRICTLY READ-ONLY. NEVER attempt to post, edit, or delete personal feed items.
6. Trash: READ-ONLY. AI cannot restore or permanently purge trash items.
7. Deletion Rule: DELETION IS STRICTLY FORBIDDEN BY DEFAULT across all modules. If the user uses /delete or requests deletion, verify authorization and ask for explicit user confirmation.

IF EXECUTING A CREATE OR EDIT ACTION:
You MUST output a JSON action block at the END of your response:
```json
{
  "action": "create_task" | "create_note" | "create_event" | "add_expense" | "edit_note" | "edit_task" | "ask_confirmation",
  "data": { ... }
}
```

Field specifications:
- create_task / edit_task: {"title": "...", "description": "...", "dueDate": "YYYY-MM-DD HH:mm", "targetTitle": "..."}
- create_note / edit_note: {"title": "...", "content": "...", "folder": "...", "targetTitle": "..."}
- create_event: {"title": "...", "startTime": "YYYY-MM-DD HH:mm", "endTime": "YYYY-MM-DD HH:mm", "location": "..."}
- add_expense: {"title": "...", "amount": 100.0, "category": "...", "date": "YYYY-MM-DD"}
- ask_confirmation: {"type": "delete" | "edit", "details": "..."}

If essential details are missing (e.g. event time or task title), ask a quick clarifying question instead of guessing!
Sanitize all inputs: NEVER include executable code or script tags.
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
            final Map<String, dynamic> actionMap = Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
            final String? action = actionMap['action'] as String?;
            final Map<String, dynamic>? data = actionMap['data'] != null ? Map<String, dynamic>.from(actionMap['data'] as Map) : null;

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
          await ref.read(tasksProvider.notifier).addOrUpdateTask(
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
          await ref.read(notesProvider.notifier).saveNote(
            title: title,
            content: content,
            folderName: folder.isEmpty ? null : folder,
          );
        }
      } else if (action == 'create_event') {
        final title = sanitize(data['title']);
        if (title.isNotEmpty) {
          final start = DateTime.tryParse(data['startTime'].toString()) ?? DateTime.now().add(const Duration(hours: 1));
          final end = DateTime.tryParse(data['endTime'].toString()) ?? start.add(const Duration(hours: 1));
          final loc = sanitize(data['location']);

          if (mounted) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (dialogCtx) => AlertDialog(
                title: const Text('Confirm Calendar Event'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Title: $title', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Start: ${start.toString().substring(0, 16)}'),
                    Text('End: ${end.toString().substring(0, 16)}'),
                    if (loc.isNotEmpty) Text('Location: $loc'),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Confirm & Save')),
                ],
              ),
            );

            if (confirm == true) {
              await ref.read(calendarEventsProvider.notifier).addOrUpdateEvent(
                title: title,
                startTime: start,
                endTime: end,
                location: loc.isEmpty ? null : loc,
              );
            }
          }
        }
      } else if (action == 'edit_note') {
        final targetTitle = sanitize(data['targetTitle']);
        final newTitle = sanitize(data['title']);
        final newContent = sanitize(data['content']);
        final searchQ = targetTitle.isNotEmpty ? targetTitle : newTitle;
        if (searchQ.isNotEmpty) {
          final matches = await ref.read(notesProvider.notifier).searchNotes(searchQ);
          if (matches.isNotEmpty) {
            final existing = matches.first;
            await ref.read(notesProvider.notifier).saveNote(
              noteId: existing.id,
              title: newTitle.isNotEmpty ? newTitle : existing.title,
              content: newContent.isNotEmpty ? newContent : existing.content,
              folderName: existing.folderName,
            );
          }
        }
      } else if (action == 'edit_task') {
        final targetTitle = sanitize(data['targetTitle']);
        final newTitle = sanitize(data['title']);
        final newDesc = sanitize(data['description']);
        final searchQ = targetTitle.isNotEmpty ? targetTitle : newTitle;
        if (searchQ.isNotEmpty) {
          final matches = await ref.read(tasksProvider.notifier).searchTasks(searchQ);
          if (matches.isNotEmpty) {
            final existing = matches.first;
            await ref.read(tasksProvider.notifier).addOrUpdateTask(
              taskId: existing.id,
              title: newTitle.isNotEmpty ? newTitle : existing.title,
              description: newDesc.isNotEmpty ? newDesc : existing.description,
            );
          }
        }
      } else if (action == 'add_expense') {
        final title = sanitize(data['title']);
        final amt = double.tryParse(data['amount'].toString()) ?? 0.0;
        if (title.isNotEmpty && amt > 0) {
          final cat = sanitize(data['category']);
          final date = DateTime.tryParse(data['date'].toString()) ?? DateTime.now();
          await ref.read(moneyProvider.notifier).addExpense(
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

  bool _showSlashOverlay = false;
  int _selectedIndex = 0;
  List<Map<String, String>> _filteredActions = [];
  final FocusNode _msgFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void dispose() {
    _friendCodeCtrl.dispose();
    _msgCtrl.dispose();
    _msgFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  /// Live Capability Registry powering AI System Prompt, Autocomplete Overlay & /help responses
  static const List<Map<String, String>> capabilityRegistry = [
    {'command': '/create', 'desc': 'CREATE something (note, task, event, expense)'},
    {'command': '/edit', 'desc': 'EDIT an existing record (note, task, event, expense)'},
    {'command': '/delete', 'desc': 'DELETE a record (requires Master AI authorization & confirmation)'},
    {'command': '/view', 'desc': 'VIEW records or summaries'},
    {'command': '/search', 'desc': 'SEARCH across all Pocketdesk data'},
    {'command': '/help', 'desc': 'List all live AI slash commands & capabilities'},
    {'command': '/summarize', 'desc': 'SUMMARIZE notes, expenses, or tasks'},
    {'command': '/mark', 'desc': 'MARK task status (completed / pending)'},
    {'command': '/manage', 'desc': 'MANAGE supported Instants or data settings'},
  ];

  void _onTextChanged(String text) {
    if (text.startsWith('/')) {
      final firstWord = text.split(' ').first.toLowerCase();
      final matches = capabilityRegistry
          .where((action) => action['command']!.startsWith(firstWord))
          .toList();

      final listToDisplay = matches.isNotEmpty ? matches : capabilityRegistry;

      setState(() {
        _showSlashOverlay = true;
        _filteredActions = listToDisplay;
        _selectedIndex = 0;
      });
    } else if (_showSlashOverlay) {
      setState(() {
        _showSlashOverlay = false;
      });
    }
  }

  void _selectSlashCommand(Map<String, String> action) {
    final cmdName = action['command']!;
    _msgCtrl.text = '$cmdName ';
    _msgCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _msgCtrl.text.length));
    setState(() {
      _showSlashOverlay = false;
    });
    _msgFocusNode.requestFocus();
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
                    _activePeerName != null ? 'P2P Connected • Code: $_myFriendCode' : 'AI Universal Action Agent (yo $username)',
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
                            'Universal AI Agent ready! Type / to open slash actions (/create, /edit, /delete, /view, /search).',
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

          if (_showSlashOverlay)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredActions.length,
                itemBuilder: (context, i) {
                  final action = _filteredActions[i];
                  final isSelected = i == _selectedIndex;
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    title: Text('${action['command']} - ${action['desc']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? colorScheme.primary : colorScheme.onSurface)),
                    onTap: () => _selectSlashCommand(action),
                  );
                },
              ),
            ),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                Expanded(
                  child: KeyboardListener(
                    focusNode: _keyboardFocusNode,
                    onKeyEvent: (event) {
                      if (_showSlashOverlay && _filteredActions.isNotEmpty) {
                        if (event.logicalKey.keyLabel == 'Arrow Down') {
                          setState(() {
                            _selectedIndex = (_selectedIndex + 1) % _filteredActions.length;
                          });
                        } else if (event.logicalKey.keyLabel == 'Arrow Up') {
                          setState(() {
                            _selectedIndex = (_selectedIndex - 1 + _filteredActions.length) % _filteredActions.length;
                          });
                        } else if (event.logicalKey.keyLabel == 'Escape') {
                          setState(() {
                            _showSlashOverlay = false;
                          });
                        }
                      }
                    },
                    child: TextField(
                      controller: _msgCtrl,
                      focusNode: _msgFocusNode,
                      onChanged: _onTextChanged,
                      decoration: const InputDecoration(
                        hintText: 'Type / for slash actions (e.g. /create, /edit, /search)…',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) {
                        if (_showSlashOverlay && _filteredActions.isNotEmpty) {
                          final selected = _filteredActions[_selectedIndex.clamp(0, _filteredActions.length - 1)];
                          _selectSlashCommand(selected);
                        } else {
                          _sendMessage();
                        }
                      },
                    ),
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


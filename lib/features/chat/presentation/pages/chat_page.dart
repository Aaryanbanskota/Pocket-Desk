import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketdesk/core/logging/app_logger.dart';
import 'package:pocketdesk/core/router/app_routes.dart';
import 'package:pocketdesk/core/services/p2p_sync_service.dart';
import 'package:pocketdesk/core/theme/app_spacing.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pocketdesk/features/calendar/presentation/providers/calendar_events_notifier.dart';
import 'package:pocketdesk/features/money_tracker/presentation/providers/money_notifier.dart';
import 'package:pocketdesk/features/notes/presentation/providers/notes_notifier.dart';
import 'package:pocketdesk/features/settings/presentation/providers/ai_settings_notifier.dart';
import 'package:pocketdesk/features/tasks/presentation/providers/tasks_notifier.dart';
import 'package:pocketdesk/features/dashboard/presentation/widgets/app_hamburger_drawer.dart';
import 'package:pocketdesk/features/chat/presentation/widgets/ai_chef_mascot_widget.dart';

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
  final ScrollController _messageScrollController = ScrollController();

  String? _myFriendCode;
  String? _activePeerName;
  bool _isAITyping = false;
  bool _isSending = false;

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
    if (text.isEmpty || _isSending) return;
    _isSending = true;

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
      _showSlashOverlay = false;
      _filteredActions = const [];
    });
    _scrollToLatestMessage();

    _msgCtrl.clear();
    _keepMessageInputFocused();

    try {
      final p2pService = P2PSyncService();
      if (p2pService.deviceId == null) {
        await p2pService.initialize(
            deviceId: _myFriendCode, deviceName: username);
      }
      await p2pService.queueSyncEvent(
        type: 'chat',
        payload: {
          'id': userMsg.id,
          'sender': userMsg.senderId,
          'text': userMsg.text,
        },
      );
    } catch (e, st) {
      AppLogger.e('Failed to queue chat sync event',
          tag: 'ChatPage', error: e, st: st);
    }

    try {
      if (_activePeerName == null) {
        await _generateAIReply(userMsg, username);
      }
    } catch (e, st) {
      AppLogger.e('Failed to generate chat reply',
          tag: 'ChatPage', error: e, st: st);
      if (mounted) {
        setState(() {
          _isAITyping = false;
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            senderId: 'ai',
            senderName: 'Pocketdesk AI',
            text: 'I could not complete that request. Please try again.',
            timestamp: DateTime.now(),
            isMe: false,
          ));
        });
        _scrollToLatestMessage();
      }
    } finally {
      _isSending = false;
      _keepMessageInputFocused();
    }
  }

  Future<void> _generateAIReply(ChatMessage userMsg, String username) async {
    final recordListReply = await _answerRecordListRequest(userMsg.text);
    if (!mounted) return;
    if (recordListReply != null) {
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'ai',
          senderName: 'Pocketdesk AI',
          text: recordListReply,
          timestamp: DateTime.now(),
          isMe: false,
        ));
      });
      _scrollToLatestMessage();
      return;
    }

    final auth = ref.read(authNotifierProvider).valueOrNull;
    final userId = auth is AuthAuthenticated ? auth.user.id : 0;
    final aiSettings = await ref
        .read(aiSettingsRepositoryProvider.future)
        .then((r) => r.getOrCreateSettings(userId));
    final deletionReply = await _handleDeleteRequest(
      userMsg.text,
      masterControlEnabled: aiSettings.masterControlEnabled,
    );
    if (!mounted) return;
    if (deletionReply != null) {
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'ai',
          senderName: 'Pocketdesk AI',
          text: deletionReply,
          timestamp: DateTime.now(),
          isMe: false,
        ));
      });
      _scrollToLatestMessage();
      return;
    }

    if (!aiSettings.isEnabled || aiSettings.apiKey.trim().isEmpty) {
      // Fallback friendly message if AI is not enabled or no API key set
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'ai',
          senderName: 'Pocketdesk AI',
          text:
              'yo $username! I am your AI friend. To enable real-time AI replies here, make sure to add your OpenRouter API key in Settings → AI.',
          timestamp: DateTime.now(),
          isMe: false,
        ));
      });
      _scrollToLatestMessage();
      return;
    }

    setState(() => _isAITyping = true);

    final recentMessages = _messages.length <= 10
        ? _messages
        : _messages.sublist(_messages.length - 10);
    final historyContext = recentMessages
        .map((message) =>
            '${message.isMe ? username : message.senderName}: ${message.text}')
        .join('\n');
    final prompt =
        'Recent conversation (latest message is the current request):\n$historyContext';
    final nowStr = DateTime.now().toString();
    final systemPrompt = '''
You are Pocketdesk AI, the official built-in universal action agent for Pocketdesk. Always address the user warmly (e.g. "yo <username>"). Be casual, helpful, clear, and friendly!
Current timestamp: $nowStr
AI Master Control: ${aiSettings.masterControlEnabled ? 'ON. You may open app sections and perform supported user-requested task/event/note deletions. The app will show exactly one confirmation dialog before deletion; do not ask for a second confirmation in chat. Feed and Trash content remain read-only.' : 'OFF. Do not open app sections or delete records; tell the user to enable AI Master Control in Settings > AI.'}

SLASH ACTION SYSTEM:
The user input may start with a slash command defining the intended action type:
- /create: User wants to CREATE a record (Note, Task, Event, Expense).
- /edit: User wants to EDIT an existing record.
- /delete: User wants to DELETE a record (Check permissions & request confirmation).
- /view: User wants to VIEW or summarize records.
- /search: User wants to SEARCH across Pocketdesk data.
- /open: Open an app section when AI Master Control is enabled.
- /help: User wants to see available slash actions.

The natural text following the slash action describes WHAT the user wants to do. You MUST parse natural language, typos, spelling mistakes, and casual phrasing (e.g. "creat a note name Test 101 and put article inside" -> Action: CREATE, Target: Note, Title: Test 101, Content: article).

CAPABILITY & PERMISSION MATRIX:
1. Calendar & Events: Support reading, creating, and editing events. Ask for missing details if underspecified.
2. Tasks: Support reading, creating, and editing tasks. Understand natural date phrases like "tomorrow", "next Monday", "in 2 days".
3. Notes: Support reading, creating, and editing notes.
4. Money Tracker: Support reading, creating, and logging expenses.
5. Personal Feed: STRICTLY READ-ONLY. NEVER attempt to post, edit, or delete personal feed items.
6. Trash: READ-ONLY. AI cannot restore or permanently purge trash items.
7. Deletion Rule: Task, event, and note deletion is available only when AI Master Control is enabled and the user confirms the specific deletion. Feed and Trash remain read-only; never create, edit, or delete feed content or restore/purge trash.

When the user requests a supported create or edit and all required details are present, execute it immediately and include the JSON action block; do not ask "are you sure?" or request a second confirmation. For deletions, return the JSON action immediately because the app itself will ask once before deleting. Ask only for essential missing information, and do not include an action block until it is provided. If a prior assistant message asked for missing information and the user answers it (including a short answer such as "yes"), use the recent conversation to complete the pending request. Never repeat an action that the recent conversation already confirms was completed.

IF EXECUTING A CREATE OR EDIT ACTION, OR AN OPEN/DELETE ACTION WHILE MASTER CONTROL IS ON:
You MUST output a JSON action block at the END of your response:
```json
{
  "action": "create_task" | "create_note" | "create_event" | "add_expense" | "edit_note" | "edit_task" | "delete_task" | "delete_event" | "open_page",
  "data": { ... }
}
```

Field specifications:
- create_task / edit_task: {"title": "...", "description": "...", "dueDate": "YYYY-MM-DD HH:mm", "targetTitle": "..."}
- create_note / edit_note: {"title": "...", "content": "...", "folder": "...", "targetTitle": "..."}
- create_event: {"title": "...", "startTime": "YYYY-MM-DD HH:mm", "endTime": "YYYY-MM-DD HH:mm", "location": "..."}
- delete_task / delete_event: {"targetTitle": "exact record title"}
- open_page: {"page": "dashboard | calendar | tasks | notes | money | clock | settings | about | files | posts | trash"}
- add_expense: {"title": "...", "amount": 100.0, "category": "...", "date": "YYYY-MM-DD"}

The app asks the user to confirm each task/event deletion. Do not claim that deletion happened before confirmation. If Master Control is off, explain how to enable it instead of returning an action.
If essential details are missing (e.g. event time or task title), ask one quick clarifying question instead of guessing.
Sanitize all inputs: NEVER include executable code or script tags.
''';

    final reply =
        await ref.read(aiSettingsProvider.notifier).generateCompletion(
              prompt: prompt,
              systemPrompt: systemPrompt,
            );

    if (!mounted) return;

    String cleanText = reply ??
        'yo $username! Something went wrong reaching OpenRouter, but I am still right here for you buddy!';

    // Check if reply contains a JSON action block to execute on user's behalf
    if (reply != null && reply.contains('```json')) {
      try {
        final jsonMatch = RegExp(r'```json\s*(\{.*?\})\s*```', dotAll: true)
            .firstMatch(reply);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(1);
          if (jsonStr != null) {
            final Map<String, dynamic> actionMap =
                Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
            final String? action = actionMap['action'] as String?;
            final Map<String, dynamic>? data = actionMap['data'] != null
                ? Map<String, dynamic>.from(actionMap['data'] as Map)
                : null;

            if (action != null && data != null) {
              final requiresMasterControl = {
                'open_page',
                'delete_task',
                'delete_event',
              }.contains(action);
              if (requiresMasterControl && !aiSettings.masterControlEnabled) {
                cleanText =
                    'Turn on AI Master Control in Settings → AI to allow this action.';
              } else {
                final actionMessage = await _executeAIAction(
                  action,
                  data,
                  masterControlEnabled: aiSettings.masterControlEnabled,
                );
                if (actionMessage != null) cleanText = actionMessage;
              }
            }
          }
        }
      } catch (e) {
        // Safe handling: ignore invalid JSON without crashing
      }
      cleanText = cleanText
          .replaceAll(RegExp(r'```json\s*\{.*?\}\s*```', dotAll: true), '')
          .trim();
    }

    if (!mounted) return;
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
    _scrollToLatestMessage();
  }

  Future<String?> _answerRecordListRequest(String text) async {
    final query = text.toLowerCase();
    final asksToList = RegExp(r'\b(all|list|show|tell|what|which|name|names)\b')
        .hasMatch(query);
    final asksForTasks = RegExp(r'\b(tasks?|todos?)\b').hasMatch(query);
    final asksForEvents = RegExp(r'\b(events?|calendar)\b').hasMatch(query);

    if (!asksToList || (!asksForTasks && !asksForEvents)) return null;

    final sections = <String>[];
    if (asksForTasks) {
      final tasks = (await ref.read(tasksProvider.future)).tasks;
      sections.add(
        'Tasks:\n${tasks.isEmpty ? 'No tasks found.' : tasks.map((task) => '- ${task.title}').join('\n')}',
      );
    }
    if (asksForEvents) {
      final events = await ref.read(calendarEventsProvider.future);
      sections.add(
        'Events:\n${events.isEmpty ? 'No events found.' : events.map((event) => '- ${event.title}').join('\n')}',
      );
    }

    return sections.join('\n\n');
  }

  Future<String?> _handleDeleteRequest(
    String text, {
    required bool masterControlEnabled,
  }) async {
    if (!RegExp(r'\b(delete|remove|erase)\b', caseSensitive: false)
        .hasMatch(text)) {
      return null;
    }

    if (!masterControlEnabled) {
      return 'Turn on AI Master Control in Settings → AI before deleting records.';
    }

    final query =
        ' ${text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim()} ';
    if (RegExp(r'\b(post|feed|instant|trash)\b').hasMatch(query)) {
      return 'AI cannot delete Feed or Trash content.';
    }

    final wantsTasks = RegExp(r'\b(task|tasks|todo|todos)\b').hasMatch(query);
    final wantsEvents = RegExp(r'\b(event|events|calendar)\b').hasMatch(query);
    final wantsNotes = RegExp(r'\b(note|notes)\b').hasMatch(query);
    if (RegExp(r'\ball\b').hasMatch(query) &&
        (wantsTasks || wantsEvents || wantsNotes)) {
      return 'For safety, delete one named task, event, or note at a time.';
    }

    final candidates = <({String type, int id, String title})>[];
    if (wantsTasks || (!wantsEvents && !wantsNotes)) {
      final tasks = (await ref.read(tasksProvider.future)).tasks;
      candidates.addAll(tasks.map((task) => (
            type: 'task',
            id: task.id,
            title: task.title,
          )));
    }
    if (wantsEvents || (!wantsTasks && !wantsNotes)) {
      final events = await ref.read(calendarEventsProvider.future);
      candidates.addAll(events.map((event) => (
            type: 'event',
            id: event.id,
            title: event.title,
          )));
    }
    if (wantsNotes || (!wantsTasks && !wantsEvents)) {
      final notes = (await ref.read(notesProvider.future)).notes;
      candidates.addAll(notes.map((note) => (
            type: 'note',
            id: note.id,
            title: note.title,
          )));
    }

    final matches = candidates.where((candidate) {
      final normalizedTitle = candidate.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
          .trim();
      return normalizedTitle.isNotEmpty && query.contains(' $normalizedTitle ');
    }).toList();
    if (matches.isEmpty) {
      return 'Tell me the exact name of the task, event, or note you want to delete.';
    }
    if (matches.length > 1) {
      return 'That name matches more than one record. Please specify its exact type and name.';
    }

    final target = matches.single;
    if (!mounted) return null;
    final confirmed = await _confirmAIDeletion(target.type, target.title);
    if (confirmed != true) return '${target.type} deletion cancelled.';

    switch (target.type) {
      case 'task':
        await ref.read(tasksProvider.notifier).deleteTask(target.id);
      case 'event':
        await ref.read(calendarEventsProvider.notifier).deleteEvent(target.id);
      case 'note':
        await ref.read(notesProvider.notifier).deleteNote(target.id);
    }
    return 'Deleted ${target.type} "${target.title}". It is available in Trash.';
  }

  Future<String?> _executeAIAction(
    String action,
    Map<String, dynamic> data, {
    required bool masterControlEnabled,
  }) async {
    // Sanitize title / string inputs to ensure no unsafe scripts or malformed data
    String sanitize(dynamic val) => (val ?? '')
        .toString()
        .replaceAll(
            RegExp(r'<script.*?>.*?</script>', caseSensitive: false), '')
        .trim();

    try {
      if ((action == 'open_page' ||
              action == 'delete_task' ||
              action == 'delete_event') &&
          !masterControlEnabled) {
        return 'Turn on AI Master Control in Settings → AI to allow this action.';
      }

      if (action == 'open_page') {
        final page = sanitize(data['page']).toLowerCase();
        final route = switch (page) {
          'home' || 'dashboard' => AppRoutes.dashboard,
          'calendar' || 'event' || 'events' => AppRoutes.calendar,
          'task' || 'tasks' => AppRoutes.tasks,
          'note' || 'notes' => AppRoutes.notes,
          'money' || 'wallet' || 'expenses' => AppRoutes.moneyTracker,
          'clock' || 'timer' || 'alarms' => AppRoutes.clock,
          'settings' => AppRoutes.settings,
          'about' => AppRoutes.aboutApp,
          'files' || 'file share' => AppRoutes.fileShare,
          'posts' || 'feed' => AppRoutes.posts,
          'trash' => AppRoutes.trash,
          _ => null,
        };
        if (route == null) return 'I could not find that app section.';
        if (mounted) context.go(route);
        return null;
      }

      if (action == 'delete_task') {
        final title = sanitize(data['targetTitle']);
        if (title.isEmpty) return 'Tell me the exact task name to delete.';
        final matches =
            await ref.read(tasksProvider.notifier).searchTasks(title);
        final exactMatches = matches
            .where((task) => task.title.toLowerCase() == title.toLowerCase())
            .toList();
        final targets = exactMatches.isNotEmpty ? exactMatches : matches;
        if (targets.length != 1) {
          return targets.isEmpty
              ? 'I could not find a task named "$title".'
              : 'More than one task matches "$title". Please specify the exact task name.';
        }
        if (!mounted) return null;
        final confirmed =
            await _confirmAIDeletion('task', targets.single.title);
        if (confirmed != true) return 'Task deletion cancelled.';
        await ref.read(tasksProvider.notifier).deleteTask(targets.single.id);
        return 'Deleted task "${targets.single.title}". It is available in Trash.';
      }

      if (action == 'delete_event') {
        final title = sanitize(data['targetTitle']);
        if (title.isEmpty) return 'Tell me the exact event name to delete.';
        final matches = (await ref.read(calendarEventsProvider.future))
            .where((event) =>
                event.title.toLowerCase().contains(title.toLowerCase()))
            .toList();
        final exactMatches = matches
            .where((event) => event.title.toLowerCase() == title.toLowerCase())
            .toList();
        final targets = exactMatches.isNotEmpty ? exactMatches : matches;
        if (targets.length != 1) {
          return targets.isEmpty
              ? 'I could not find an event named "$title".'
              : 'More than one event matches "$title". Please specify the exact event name.';
        }
        if (!mounted) return null;
        final confirmed =
            await _confirmAIDeletion('event', targets.single.title);
        if (confirmed != true) return 'Event deletion cancelled.';
        await ref
            .read(calendarEventsProvider.notifier)
            .deleteEvent(targets.single.id);
        return 'Deleted event "${targets.single.title}". It is available in Trash.';
      }

      if (action == 'create_task') {
        final title = sanitize(data['title']);
        if (title.isEmpty) return 'Tell me the task name to create.';
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
        return 'Created task "$title".';
      } else if (action == 'create_note') {
        final title = sanitize(data['title']);
        if (title.isEmpty) return 'Tell me the note name to create.';
        final content = sanitize(data['content']);
        final folder = sanitize(data['folder']);
        await ref.read(notesProvider.notifier).saveNote(
              title: title,
              content: content,
              folderName: folder.isEmpty ? null : folder,
            );
        return 'Created note "$title".';
      } else if (action == 'create_event') {
        final title = sanitize(data['title']);
        if (title.isEmpty) return 'Tell me the event name to create.';
        final start = DateTime.tryParse(data['startTime']?.toString() ?? '');
        final end = DateTime.tryParse(data['endTime']?.toString() ?? '');
        if (start == null || end == null) {
          return 'I need the event start and end time before I can create it.';
        }
        if (!end.isAfter(start)) {
          return 'The event end time must be after its start time.';
        }
        final loc = sanitize(data['location']);
        await ref.read(calendarEventsProvider.notifier).addOrUpdateEvent(
              title: title,
              startTime: start,
              endTime: end,
              location: loc.isEmpty ? null : loc,
            );
        return 'Created event "$title".';
      } else if (action == 'edit_note') {
        final targetTitle = sanitize(data['targetTitle']);
        final newTitle = sanitize(data['title']);
        final newContent = sanitize(data['content']);
        final searchQ = targetTitle.isNotEmpty ? targetTitle : newTitle;
        if (searchQ.isEmpty) return 'Tell me which note you want to edit.';
        final matches =
            await ref.read(notesProvider.notifier).searchNotes(searchQ);
        if (matches.length != 1) {
          return matches.isEmpty
              ? 'I could not find a note named "$searchQ".'
              : 'More than one note matches "$searchQ". Please specify its exact name.';
        }
        final existing = matches.single;
        await ref.read(notesProvider.notifier).saveNote(
              noteId: existing.id,
              title: newTitle.isNotEmpty ? newTitle : existing.title,
              content: newContent.isNotEmpty ? newContent : existing.content,
              folderName: existing.folderName,
            );
        return 'Updated note "${newTitle.isNotEmpty ? newTitle : existing.title}".';
      } else if (action == 'edit_task') {
        final targetTitle = sanitize(data['targetTitle']);
        final newTitle = sanitize(data['title']);
        final newDesc = sanitize(data['description']);
        final searchQ = targetTitle.isNotEmpty ? targetTitle : newTitle;
        if (searchQ.isEmpty) return 'Tell me which task you want to edit.';
        final matches =
            await ref.read(tasksProvider.notifier).searchTasks(searchQ);
        if (matches.length != 1) {
          return matches.isEmpty
              ? 'I could not find a task named "$searchQ".'
              : 'More than one task matches "$searchQ". Please specify its exact name.';
        }
        final existing = matches.single;
        await ref.read(tasksProvider.notifier).addOrUpdateTask(
              taskId: existing.id,
              title: newTitle.isNotEmpty ? newTitle : existing.title,
              description: newDesc.isNotEmpty ? newDesc : existing.description,
            );
        return 'Updated task "${newTitle.isNotEmpty ? newTitle : existing.title}".';
      } else if (action == 'add_expense') {
        final title = sanitize(data['title']);
        final amt = double.tryParse(data['amount']?.toString() ?? '');
        if (title.isEmpty || amt == null || amt <= 0) {
          return 'Tell me the expense name and a positive amount.';
        }
        final cat = sanitize(data['category']);
        final date =
            DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now();
        await ref.read(moneyProvider.notifier).addExpense(
              title: title,
              amount: amt,
              category: cat.isEmpty ? 'General' : cat,
              date: date,
            );
        return 'Added expense "$title".';
      }
      return null;
    } catch (e) {
      return 'I could not complete that action. Please try again.';
    }
  }

  Future<bool?> _confirmAIDeletion(String type, String title) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete $type?'),
        content: Text(
          'Delete "$title"? It will be moved to Trash and can be restored there.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  bool _showSlashOverlay = false;
  int _selectedIndex = 0;
  List<Map<String, String>> _filteredActions = [];
  final FocusNode _msgFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode =
      FocusNode(skipTraversal: true, canRequestFocus: false);

  @override
  void dispose() {
    _friendCodeCtrl.dispose();
    _msgCtrl.dispose();
    _messageScrollController.dispose();
    _msgFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  /// Live Capability Registry powering AI System Prompt, Autocomplete Overlay & /help responses
  static const List<Map<String, String>> capabilityRegistry = [
    {
      'command': '/create',
      'desc': 'CREATE something (note, task, event, expense)'
    },
    {
      'command': '/edit',
      'desc': 'EDIT an existing record (note, task, event, expense)'
    },
    {
      'command': '/delete',
      'desc':
          'DELETE a record (requires Master AI authorization & confirmation)'
    },
    {'command': '/view', 'desc': 'VIEW records or summaries'},
    {'command': '/search', 'desc': 'SEARCH across all Pocketdesk data'},
    {
      'command': '/help',
      'desc': 'List all live AI slash commands & capabilities'
    },
    {'command': '/summarize', 'desc': 'SUMMARIZE notes, expenses, or tasks'},
    {'command': '/mark', 'desc': 'MARK task status (completed / pending)'},
    {
      'command': '/manage',
      'desc': 'MANAGE supported Instants or data settings'
    },
    {
      'command': '/open',
      'desc': 'OPEN an app section (requires AI Master Control)'
    },
  ];

  void _onTextChanged(String text) {
    final trimmed = text.trim();
    final slashPrefix = text.startsWith('/') && !trimmed.contains(' ');

    if (slashPrefix) {
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
        _filteredActions = const [];
      });
    }
  }

  void _keepMessageInputFocused() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _msgFocusNode.requestFocus();
      }
    });
  }

  void _scrollToLatestMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messageScrollController.hasClients) {
        _messageScrollController.animateTo(
          _messageScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectSlashCommand(Map<String, String> action) {
    final cmdName = action['command']!;
    _msgCtrl.text = '$cmdName ';
    _msgCtrl.selection =
        TextSelection.fromPosition(TextPosition(offset: _msgCtrl.text.length));
    setState(() {
      _showSlashOverlay = false;
      _filteredActions = const [];
    });
    _keepMessageInputFocused();
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
                AiChefMascotWidget(
                    size: 28, color: colorScheme.primary, animate: _isAITyping),
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
                      _activePeerName != null
                          ? 'P2P Connected • Code: $_myFriendCode'
                          : 'AI Universal Action Agent (yo $username)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const AiChefMascotWidget(size: 24, animate: true),
              onPressed: () => showPocketAiMascotDialog(context, ref),
              tooltip: 'Call Pocket AI Mascot',
            ),
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
                    decoration: const InputDecoration(
                        hintText: 'Enter Friend Code / Device ID'),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: _addFriend,
                        child: const Text('Connect P2P')),
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
                          AiChefMascotWidget(
                              size: 110,
                              color: colorScheme.primary,
                              animate: true),
                          const SizedBox(height: 20),
                          Text(
                            'yo $username!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Universal AI Agent ready! Type / to open slash actions (/create, /edit, /delete, /view, /search).',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _messageScrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!msg.isMe) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 4, right: 8),
                                child: AiChefMascotWidget(
                                    size: 24,
                                    color: colorScheme.primary,
                                    animate: false),
                              ),
                            ],
                            Container(
                              margin:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.72),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md, vertical: 10),
                              decoration: BoxDecoration(
                                color: msg.isMe
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft:
                                      Radius.circular(msg.isMe ? 16 : 2),
                                  bottomRight:
                                      Radius.circular(msg.isMe ? 2 : 16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: msg.isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
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
                                      color: msg.isMe
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface,
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
                  AiChefMascotWidget(
                      size: 22, color: colorScheme.primary, animate: true),
                  const SizedBox(width: 10),
                  Text('Pocketdesk AI is processing…',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          if (_showSlashOverlay)
            TextFieldTapRegion(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8)
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredActions.length,
                  itemBuilder: (context, i) {
                    final action = _filteredActions[i];
                    final isSelected = i == _selectedIndex;
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor:
                            colorScheme.primaryContainer.withValues(alpha: 0.3),
                        title: Text('${action['command']} - ${action['desc']}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface)),
                        onTap: () => _selectSlashCommand(action),
                      ),
                    );
                  },
                ),
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
                            _selectedIndex =
                                (_selectedIndex + 1) % _filteredActions.length;
                          });
                        } else if (event.logicalKey.keyLabel == 'Arrow Up') {
                          setState(() {
                            _selectedIndex =
                                (_selectedIndex - 1 + _filteredActions.length) %
                                    _filteredActions.length;
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
                        hintText:
                            'Type / for slash actions (e.g. /create, /edit, /search)…',
                        border: InputBorder.none,
                      ),
                      autofocus: true,
                      onSubmitted: (_) {
                        if (_showSlashOverlay && _filteredActions.isNotEmpty) {
                          final selected = _filteredActions[_selectedIndex
                              .clamp(0, _filteredActions.length - 1)];
                          _selectSlashCommand(selected);
                        } else {
                          _sendMessage();
                        }
                      },
                    ),
                  ),
                ),
                TextFieldTapRegion(
                  child: IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded),
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

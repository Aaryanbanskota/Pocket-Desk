import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketdesk/core/router/app_routes.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pocketdesk/features/calendar/presentation/providers/calendar_events_notifier.dart';
import 'package:pocketdesk/features/money_tracker/presentation/providers/money_notifier.dart';
import 'package:pocketdesk/features/notes/presentation/providers/notes_notifier.dart';
import 'package:pocketdesk/features/settings/presentation/providers/ai_settings_notifier.dart';
import 'package:pocketdesk/features/tasks/presentation/providers/tasks_notifier.dart';

/// A custom mascot widget representing the Pocket AI Chef/Cloud mascot.
/// Inspired by the vibrant scalloped mascot silhouette with twin vertical capsule eyes.
class AiChefMascotWidget extends StatefulWidget {
  final double size;
  final Color? color;
  final Color? eyeColor;
  final bool animate;

  const AiChefMascotWidget({
    super.key,
    this.size = 32,
    this.color,
    this.eyeColor,
    this.animate = true,
  });

  @override
  State<AiChefMascotWidget> createState() => _AiChefMascotWidgetState();
}

class _AiChefMascotWidgetState extends State<AiChefMascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (widget.animate && !isTest) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AiChefMascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      final isTest = Platform.environment.containsKey('FLUTTER_TEST');
      if (widget.animate && !isTest) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mascotColor = widget.color ?? const Color(0xFF00E676);
    final eyeColor = widget.eyeColor ?? theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatOffset = widget.animate
            ? math.sin(_controller.value * math.pi) * (widget.size * 0.04)
            : 0.0;
        final scalePulse = widget.animate
            ? 1.0 + math.sin(_controller.value * math.pi) * 0.02
            : 1.0;

        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: Transform.scale(
            scale: scalePulse,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _AiChefMascotPainter(
                mascotColor: mascotColor,
                eyeColor: eyeColor,
                animValue: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AiChefMascotPainter extends CustomPainter {
  final Color mascotColor;
  final Color eyeColor;
  final double animValue;

  _AiChefMascotPainter({
    required this.mascotColor,
    required this.eyeColor,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Paints
    final bodyPaint = Paint()
      ..color = mascotColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Draw Bottom Stand / Base Bar
    final baseBarHeight = h * 0.10;
    final baseBarWidth = w * 0.55;
    final baseBarRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.92),
        width: baseBarWidth,
        height: baseBarHeight,
      ),
      Radius.circular(baseBarHeight / 2),
    );
    canvas.drawRRect(baseBarRRect, bodyPaint);

    // 2. Draw Chef / Cloud Scalloped Head
    final headPath = Path();
    final center = Offset(w * 0.5, h * 0.44);

    // Head base boundary
    final headRect = Rect.fromCenter(
      center: center,
      width: w * 0.88,
      height: h * 0.72,
    );

    // Main rounded head base
    headPath.addRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.28)),
    );

    // Top cloud puffy lobes (Scalloped chef hat shape)
    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.50, h * 0.22),
      radius: w * 0.26,
    ));

    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.28, h * 0.28),
      radius: w * 0.22,
    ));

    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.72, h * 0.28),
      radius: w * 0.22,
    ));

    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.18, h * 0.48),
      radius: w * 0.18,
    ));

    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.82, h * 0.48),
      radius: w * 0.18,
    ));

    canvas.drawPath(headPath, bodyPaint);

    // 3. Draw Vertical Capsule Eyes
    final eyeWidth = w * 0.12;
    final eyeHeight = h * 0.26;
    final eyeY = h * 0.42;

    final leftEyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.38, eyeY),
        width: eyeWidth,
        height: eyeHeight,
      ),
      Radius.circular(eyeWidth / 2),
    );

    final rightEyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.62, eyeY),
        width: eyeWidth,
        height: eyeHeight,
      ),
      Radius.circular(eyeWidth / 2),
    );

    canvas.drawRRect(leftEyeRect, eyePaint);
    canvas.drawRRect(rightEyeRect, eyePaint);
  }

  @override
  bool shouldRepaint(_AiChefMascotPainter oldDelegate) {
    return oldDelegate.mascotColor != mascotColor ||
        oldDelegate.eyeColor != eyeColor ||
        oldDelegate.animValue != animValue;
  }
}

/// Helper to trigger the interactive Pocket AI Mascot dialog anywhere in desktop or mobile.
void showPocketAiMascotDialog(BuildContext context, WidgetRef ref, {String? initialText}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => PocketAiMascotDialog(initialText: initialText),
  );
}

/// Helper function to construct a custom text selection menu item for "Call Pocket AI"
Widget buildPocketAiSelectionToolbar(
  BuildContext context,
  SelectableRegionState selectableRegionState,
  WidgetRef ref,
) {
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: selectableRegionState.contextMenuAnchors,
    buttonItems: [
      ...selectableRegionState.contextMenuButtonItems,
      ContextMenuButtonItem(
        label: 'Call Pocket AI 🤖',
        onPressed: () {
          selectableRegionState.hideToolbar();
          showPocketAiMascotDialog(context, ref);
        },
      ),
    ],
  );
}

class PocketAiMascotDialog extends ConsumerStatefulWidget {
  final String? initialText;

  const PocketAiMascotDialog({super.key, this.initialText});

  @override
  ConsumerState<PocketAiMascotDialog> createState() => _PocketAiMascotDialogState();
}

class _PocketAiMascotDialogState extends ConsumerState<PocketAiMascotDialog> {
  final TextEditingController _promptCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late String _speechText;
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    final text = widget.initialText?.trim();
    if (text != null && text.isNotEmpty) {
      _speechText = 'Yo! I see you selected:\n"$text"\n\nWhat can I help you with?';
    } else {
      _speechText = 'Yo! I\'m your Pocket Assistant! 🤖 What can I help you with today?';
    }
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _keepFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _sendMessage() async {
    final userText = _promptCtrl.text.trim();
    if (userText.isEmpty || _isThinking) return;

    setState(() {
      _promptCtrl.clear();
      _isThinking = true;
    });

    final authState = ref.read(authNotifierProvider).valueOrNull;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final username = user?.displayName ?? user?.username ?? 'User';
    final userId = user?.id ?? 0;

    final fullPromptText = widget.initialText != null && widget.initialText!.isNotEmpty
        ? 'Selected text context: "${widget.initialText}"\nUser question: $userText'
        : userText;

    // 1. Check record listing request
    final recordListReply = await _answerRecordListRequest(fullPromptText);
    if (!mounted) return;
    if (recordListReply != null) {
      setState(() {
        _isThinking = false;
        _speechText = recordListReply;
      });
      _keepFocus();
      return;
    }

    final aiSettings = await ref
        .read(aiSettingsRepositoryProvider.future)
        .then((r) => r.getOrCreateSettings(userId));

    // 2. Check deletion request
    final deletionReply = await _handleDeleteRequest(
      fullPromptText,
      masterControlEnabled: aiSettings.masterControlEnabled,
    );
    if (!mounted) return;
    if (deletionReply != null) {
      setState(() {
        _isThinking = false;
        _speechText = deletionReply;
      });
      _keepFocus();
      return;
    }

    if (!aiSettings.isEnabled || aiSettings.apiKey.trim().isEmpty) {
      setState(() {
        _isThinking = false;
        _speechText =
            'yo $username! I am your AI Mascot! 🤖 To enable real-time actions & replies, please add your OpenRouter API key in Settings → AI.';
      });
      _keepFocus();
      return;
    }

    final nowStr = DateTime.now().toString();
    final systemPrompt = '''
You are Pocket Assistant 🤖, the official built-in mascot & universal action agent for Pocketdesk. Always address the user warmly (e.g. "yo $username"). Be casual, helpful, clear, and friendly like the Duolingo mascot!
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

CAPABILITY & PERMISSION MATRIX:
1. Calendar & Events: Support reading, creating, and editing events.
2. Tasks: Support reading, creating, and editing tasks. Understand natural date phrases like "tomorrow", "next Monday", "in 2 days".
3. Notes: Support reading, creating, and editing notes.
4. Money Tracker: Support reading, creating, and logging expenses.
5. Personal Feed: STRICTLY READ-ONLY. NEVER attempt to post, edit, or delete personal feed items.
6. Trash: READ-ONLY. AI cannot restore or permanently purge trash items.
7. Deletion Rule: Task, event, and note deletion is available only when AI Master Control is enabled.

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

Sanitize all inputs: NEVER include executable code or script tags. Keep conversational parts concise (2-3 sentences max).
''';

    final response = await ref
        .read(aiSettingsProvider.notifier)
        .generateCompletion(prompt: fullPromptText, systemPrompt: systemPrompt);

    if (!mounted) return;

    String cleanText = response ??
        'yo $username! Something went wrong reaching OpenRouter, but I am still right here for you!';

    if (response != null && response.contains('```json')) {
      try {
        final jsonMatch = RegExp(r'```json\s*(\{.*?\})\s*```', dotAll: true)
            .firstMatch(response);
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
      } catch (_) {}
      cleanText = cleanText
          .replaceAll(RegExp(r'```json\s*\{.*?\}\s*```', dotAll: true), '')
          .trim();
    }

    if (!mounted) return;
    setState(() {
      _isThinking = false;
      _speechText = cleanText.isEmpty ? 'Action performed successfully!' : cleanText;
    });
    _keepFocus();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final aiSettings = ref.watch(aiSettingsProvider).valueOrNull;
    final isMinimalist = aiSettings?.mascotDesignStyle == 'minimalist';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SelectionArea(
        child: Container(
          width: math.min(MediaQuery.of(context).size.width * 0.9, 420),
          padding: const EdgeInsets.all(20),
          decoration: isMinimalist
              ? const BoxDecoration(
                  color: Colors.transparent,
                )
              : BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: isMinimalist
                    ? _buildMinimalistLayout(context, colorScheme)
                    : _buildBoxedLayout(context, colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalistLayout(BuildContext context, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 12),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isThinking
                      ? Text(
                          'Pocket Assistant is thinking...',
                          key: const ValueKey('thinking'),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            height: 1.35,
                          ),
                        )
                      : Text(
                          _speechText,
                          key: ValueKey(_speechText),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            height: 1.35,
                          ),
                        ),
                ),
              ),
            ),
            const AiChefMascotWidget(size: 64, animate: true),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promptCtrl,
                focusNode: _focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type here |',
                  isDense: true,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sendMessage,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.all(12),
              ),
              icon: const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBoxedLayout(BuildContext context, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AiChefMascotWidget(size: 76, animate: true),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isThinking
                ? Row(
                    key: const ValueKey('thinking'),
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pocket Assistant is thinking...',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    _speechText,
                    key: ValueKey(_speechText),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promptCtrl,
                focusNode: _focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  isDense: true,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sendMessage,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.all(12),
              ),
              icon: const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ],
    );
  }
}

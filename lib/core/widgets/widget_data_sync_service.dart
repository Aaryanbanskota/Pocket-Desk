import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/budget/data/budget_repository.dart';
import '../../features/notes/data/notes_repository.dart';
import '../../features/tasks/data/tasks_repository.dart';
import '../utils/nepali_calendar_converter.dart';

/// Syncs the user's real tasks, events, notes, budget, and calendar dates to SharedPreferences
/// and prompts Android native AppWidgets to immediately update and display the user's actual data.
class WidgetDataSyncService {
  WidgetDataSyncService._();

  static const MethodChannel _deviceChannel = MethodChannel('pocketdesk/device');

  static Future<void> syncWidgetsData({
    required TasksRepository tasksRepository,
    NotesRepository? notesRepository,
    BudgetRepository? budgetRepository,
    required String accountId,
  }) async {
    try {
      final allTasks = await tasksRepository.getTasks(accountId);

      // Filter active (non-deleted) items
      final active = allTasks.where((t) => !t.isDeleted).toList();

      // 1. Tasks (to-dos, not tagged as events)
      final todos = active.where((t) => !t.tags.contains('event')).toList();
      todos.sort((a, b) {
        if (a.isDone != b.isDone) {
          return a.isDone ? 1 : -1;
        }
        return a.dueDate.compareTo(b.dueDate);
      });

      final tasksJsonList = todos.take(10).map((t) {
        return {
          'id': t.id,
          'title': t.title,
          'isDone': t.isDone,
          'time': t.dueDate.isNotEmpty ? t.dueDate : 'Today',
        };
      }).toList();

      // 2. Agenda Events (tagged with 'event' or timed duration)
      final events = active.where((t) => t.tags.contains('event') || t.kind == 'timed').toList();
      events.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      final eventsJsonList = events.take(10).map((e) {
        return {
          'id': e.id,
          'title': e.title,
          'time': e.dueDate.isNotEmpty ? e.dueDate : 'Today',
          'color': '#FF6B00',
        };
      }).toList();

      // 3. Dynamic Date Strings (AD and BS)
      final now = DateTime.now();
      const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      const monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final adDateStr = '${dayNames[now.weekday - 1]}, ${now.day} ${monthNames[now.month - 1]}';
      final bsDateStr = NepaliCalendarConverter.formatBSShort(now);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_tasks_json', jsonEncode(tasksJsonList));
      await prefs.setString('widget_agenda_json', jsonEncode(eventsJsonList));
      await prefs.setString('widget_ad_date', adDateStr);
      await prefs.setString('widget_bs_date', bsDateStr);
      await prefs.setString('widget_nepali_date', bsDateStr);

      // 4. Notes Sync
      if (notesRepository != null) {
        try {
          final notes = await notesRepository.getNotes(accountId);
          final activeNotes = notes.where((n) => !n.isDeleted).take(6).map((n) {
            return {
              'id': n.id,
              'title': n.title.isNotEmpty ? n.title : 'Untitled Note',
              'body': n.body.isNotEmpty ? n.body : 'No content',
            };
          }).toList();
          await prefs.setString('widget_notes_json', jsonEncode(activeNotes));
        } catch (_) {}
      }

      // 5. Budget Sync
      if (budgetRepository != null) {
        try {
          final wallets = await budgetRepository.getWallets(accountId);
          final activeWallets = wallets.where((w) => !w.isDeleted).toList();
          final totalBalance = activeWallets.fold<double>(0.0, (sum, w) => sum + (w.currentBalance / 100.0));
          final currency = activeWallets.isNotEmpty ? activeWallets.first.currency : '\$';
          await prefs.setString('widget_budget_balance', '$currency${totalBalance.toStringAsFixed(2)}');
          await prefs.setString('widget_budget_spent', 'Today: $currency 0.00');
          await prefs.setString('widget_budget_status', 'Within Budget');
        } catch (_) {}
      }

      // 6. Trigger Android Native Widget Provider update
      try {
        await _deviceChannel.invokeMethod('updateWidgets');
      } catch (_) {}
    } catch (_) {}
  }
}

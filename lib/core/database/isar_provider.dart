import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/auth/data/models/user_model.dart';
import '../../features/calendar/data/models/calendar_event_model.dart';
import '../../features/calendar/data/models/calendar_model.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/notes/data/models/note_model.dart';
import '../../features/money_tracker/data/models/wallet_model.dart';
import '../../features/money_tracker/data/models/expense_model.dart';
import '../../features/posts/data/models/post_model.dart';
import '../../features/posts/data/models/instant_model.dart';
import '../../features/settings/data/models/ai_settings_model.dart';
import '../../features/trash/data/models/trash_item_model.dart';
import '../../core/logging/app_logger.dart';

final bool _isTest = Platform.environment.containsKey('FLUTTER_TEST');

/// Provides an initialized [Isar] instance to the whole app.
///
/// Opening is async, so we use [FutureProvider] — await it at bootstrap.
final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final openFuture = Isar.open(
    [
      UserModelSchema,
      CalendarEventModelSchema,
      CalendarModelSchema,
      TaskModelSchema,
      NoteModelSchema,
      WalletModelSchema,
      ExpenseModelSchema,
      PostModelSchema,
      InstantModelSchema,
      AISettingsModelSchema,
      TrashItemModelSchema,
    ],
    directory: dir.path,
    name: 'pocketdesk',
    inspector: false,
  );
  try {
    return await (_isTest
        ? openFuture
        : openFuture.timeout(const Duration(seconds: 10)));
  } catch (e, st) {
    AppLogger.e('Failed to open Isar database',
        tag: 'IsarProvider', error: e, st: st);
    rethrow;
  }
});

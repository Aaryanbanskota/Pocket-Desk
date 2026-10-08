import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:pocketdesk/features/auth/data/models/user_model.dart';
import 'package:pocketdesk/features/calendar/data/models/calendar_event_model.dart';
import 'package:pocketdesk/features/calendar/data/models/calendar_model.dart';
import 'package:pocketdesk/features/tasks/data/models/task_model.dart';
import 'package:pocketdesk/features/notes/data/models/note_model.dart';
import 'package:pocketdesk/features/money_tracker/data/models/wallet_model.dart';
import 'package:pocketdesk/features/money_tracker/data/models/expense_model.dart';
import 'package:pocketdesk/features/posts/data/models/post_model.dart';
import 'package:pocketdesk/features/posts/data/models/instant_model.dart';
import 'package:pocketdesk/features/settings/data/models/ai_settings_model.dart';
import 'package:pocketdesk/features/trash/data/models/trash_item_model.dart';

void main() {
  test('inspect old pocketdesk.isar', () async {
    await Isar.initializeIsarCore(download: false);
    final isar = await Isar.open(
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
      directory: '/tmp',
      name: 'phone_pocketdesk',
      inspector: false,
    );

    final users = await isar.userModels.where().findAll();
    print('FOUND USERS: ${users.length}');
    for (final u in users) {
      print('User: id=${u.id}, username="${u.username}", displayName="${u.displayName}", salt="${u.passwordSalt}", hash="${u.passwordHash}"');
    }

    final tasks = await isar.taskModels.where().findAll();
    print('FOUND TASKS: ${tasks.length}');
    for (final t in tasks) {
      print('Task: id=${t.id}, userId="${t.userId}", title="${t.title}", status=${t.status}');
    }

    final notes = await isar.noteModels.where().findAll();
    print('FOUND NOTES: ${notes.length}');
    for (final n in notes) {
      print('Note: id=${n.id}, userId="${n.userId}", title="${n.title}"');
    }

    final wallets = await isar.walletModels.where().findAll();
    print('FOUND WALLETS: ${wallets.length}');
    for (final w in wallets) {
      print('Wallet: id=${w.id}, userId="${w.userId}", name="${w.name}", balance=${w.balance}');
    }

    final posts = await isar.postModels.where().findAll();
    print('FOUND POSTS: ${posts.length}');
    for (final p in posts) {
      print('Post: id=${p.id}, userId="${p.userId}", content="${p.content}", images=${p.imagePaths.length}');
    }
    final expenses = await isar.expenseModels.where().findAll();
    print('FOUND EXPENSES: ${expenses.length}');
    for (final e in expenses.take(10)) {
      print('Expense: id=${e.id}, title="${e.title}", amount=${e.amount}, category="${e.category}"');
    }

    final events = await isar.calendarEventModels.where().findAll();
    print('FOUND EVENTS: ${events.length}');
    for (final ev in events.take(10)) {
      print('Event: id=${ev.id}, title="${ev.title}", start=${ev.startTime}, end=${ev.endTime}');
    }
    for (final p in posts.take(10)) {
      print('Post: id=${p.id}, content="${p.content}", images=${p.imagePaths.length}');
    }

    final instants = await isar.instantModels.where().findAll();
    print('FOUND INSTANTS: ${instants.length}');

    await isar.close();
  });
}

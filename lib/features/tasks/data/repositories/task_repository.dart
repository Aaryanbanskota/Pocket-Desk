import 'package:isar/isar.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/task_model.dart';

class TaskRepository {
  TaskRepository({required Isar isar}) : _isar = isar;
  final Isar _isar;

  Future<List<TaskModel>> getTasksForUser(int userId, {TaskStatus? status}) async {
    try {
      var q = _isar.taskModels.where().userIdEqualTo(userId);
      final all = await q.findAll();
      if (status != null) return all.where((t) => t.status == status).toList();
      return all;
    } catch (e, st) {
      AppLogger.e('Failed to fetch tasks', tag: 'TaskRepo', error: e, st: st);
      return [];
    }
  }

  Future<List<TaskModel>> searchTasks(int userId, String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final all = await _isar.taskModels.where().userIdEqualTo(userId).findAll();
      final q = query.toLowerCase();
      return all.where((t) =>
        t.title.toLowerCase().contains(q) ||
        (t.description?.toLowerCase().contains(q) ?? false)
      ).toList();
    } catch (e, st) {
      AppLogger.e('Failed to search tasks', tag: 'TaskRepo', error: e, st: st);
      return [];
    }
  }

  Future<List<TaskModel>> getSubtasks(int parentId) async {
    try {
      final all = await _isar.taskModels.where().findAll();
      return all.where((t) => t.parentTaskId == parentId).toList();
    } catch (e, st) {
      AppLogger.e('Failed to fetch subtasks', tag: 'TaskRepo', error: e, st: st);
      return [];
    }
  }

  Future<({TaskModel? task, AppFailure? error})> saveTask(TaskModel task) async {
    try {
      final now = DateTime.now();
      task.updatedAt = now;
      if (task.id == Isar.autoIncrement) task.createdAt = now;
      await _isar.writeTxn(() => _isar.taskModels.put(task));
      AppLogger.i('Saved task: ${task.title}', tag: 'TaskRepo');
      return (task: task, error: null);
    } catch (e, st) {
      AppLogger.e('Failed to save task', tag: 'TaskRepo', error: e, st: st);
      return (task: null, error: UnexpectedFailure('Failed to save task', error: e, stackTrace: st));
    }
  }

  Future<AppFailure?> deleteTask(int taskId) async {
    try {
      await _isar.writeTxn(() => _isar.taskModels.delete(taskId));
      return null;
    } catch (e, st) {
      return UnexpectedFailure('Failed to delete task', error: e, stackTrace: st);
    }
  }

  Future<AppFailure?> updateStatus(int taskId, TaskStatus status) async {
    try {
      final task = await _isar.taskModels.get(taskId);
      if (task == null) return const DatabaseFailure('Task not found');
      task.status = status;
      task.updatedAt = DateTime.now();
      await _isar.writeTxn(() => _isar.taskModels.put(task));
      return null;
    } catch (e, st) {
      return UnexpectedFailure('Failed to update task status', error: e, stackTrace: st);
    }
  }
}

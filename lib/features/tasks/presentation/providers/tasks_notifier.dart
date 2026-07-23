import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/isar_provider.dart';
import '../../../../core/error/app_failure.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';

final taskRepositoryProvider = FutureProvider<TaskRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return TaskRepository(isar: isar);
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TasksState {
  const TasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.filter = TaskStatus.todo,
    this.error,
  });

  final List<TaskModel> tasks;
  final bool isLoading;
  final TaskStatus filter;
  final AppFailure? error;

  TasksState copyWith({List<TaskModel>? tasks, bool? isLoading, TaskStatus? filter, AppFailure? error}) =>
      TasksState(
        tasks: tasks ?? this.tasks,
        isLoading: isLoading ?? this.isLoading,
        filter: filter ?? this.filter,
        error: error,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TasksNotifier extends AutoDisposeAsyncNotifier<TasksState> {
  @override
  Future<TasksState> build() async => TasksState(tasks: await _fetch());

  Future<List<TaskModel>> _fetch({TaskStatus? status}) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return [];
    final repo = await ref.read(taskRepositoryProvider.future);
    return repo.getTasksForUser(auth.user.id, status: status);
  }

  Future<void> setFilter(TaskStatus status) async {
    final prev = state.valueOrNull ?? const TasksState();
    state = AsyncValue.data(prev.copyWith(isLoading: true, filter: status));
    final tasks = await _fetch(status: status);
    state = AsyncValue.data(prev.copyWith(tasks: tasks, isLoading: false, filter: status));
  }

  Future<void> addOrUpdateTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.none,
    DateTime? dueDate,
    String? category,
    String? listName,
    String? folderName,
    List<String> subtaskTitles = const [],
    bool isRecurring = false,
    String? recurrenceRule,
    int? parentTaskId,
    int? taskId,
  }) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;
    final repo = await ref.read(taskRepositoryProvider.future);

    final task = TaskModel()
      ..userId = auth.user.id
      ..title = title
      ..description = description
      ..priority = priority
      ..dueDate = dueDate
      ..category = category
      ..listName = listName
      ..folderName = folderName
      ..subtaskTitles = subtaskTitles
      ..subtaskDone = List.filled(subtaskTitles.length, false)
      ..isRecurring = isRecurring
      ..recurrenceRule = recurrenceRule
      ..parentTaskId = parentTaskId;

    if (taskId != null) task.id = taskId;

    final result = await repo.saveTask(task);
    if (result.error != null) {
      state = AsyncValue.data((state.valueOrNull ?? const TasksState())
          .copyWith(error: result.error));
    } else {
      ref.invalidateSelf();
    }
  }

  Future<void> updateStatus(int taskId, TaskStatus status) async {
    final repo = await ref.read(taskRepositoryProvider.future);
    final error = await repo.updateStatus(taskId, status);
    if (error != null) {
      state = AsyncValue.data((state.valueOrNull ?? const TasksState()).copyWith(error: error));
    } else {
      ref.invalidateSelf();
    }
  }

  Future<void> deleteTask(int taskId) async {
    final repo = await ref.read(taskRepositoryProvider.future);
    final error = await repo.deleteTask(taskId);
    if (error != null) {
      state = AsyncValue.data((state.valueOrNull ?? const TasksState()).copyWith(error: error));
    } else {
      ref.invalidateSelf();
    }
  }

  Future<List<TaskModel>> searchTasks(String query) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return [];
    final repo = await ref.read(taskRepositoryProvider.future);
    return repo.searchTasks(auth.user.id, query);
  }
}

final tasksProvider = AutoDisposeAsyncNotifierProvider<TasksNotifier, TasksState>(
  TasksNotifier.new,
);

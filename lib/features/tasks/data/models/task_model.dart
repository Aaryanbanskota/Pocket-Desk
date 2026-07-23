import 'package:isar/isar.dart';

part 'task_model.g.dart';

enum TaskPriority { none, low, medium, high, urgent }
enum TaskStatus { todo, inProgress, done, archived }

@collection
class TaskModel {
  TaskModel();

  Id id = Isar.autoIncrement;

  @Index()
  late int userId;

  late String title;
  String? description;

  @enumerated
  TaskPriority priority = TaskPriority.none;

  @enumerated
  TaskStatus status = TaskStatus.todo;

  @Index()
  DateTime? dueDate;

  List<String> reminderMinutesRaw = []; // stored as strings for Isar compat

  String? category;
  String? listName;
  String? folderName;

  bool isRecurring = false;
  String? recurrenceRule;

  int? parentTaskId; // for subtasks

  List<String> attachmentPaths = [];
  List<String> subtaskTitles = [];
  List<bool> subtaskDone = [];

  bool isSynced = false;
  late DateTime createdAt;
  late DateTime updatedAt;
}

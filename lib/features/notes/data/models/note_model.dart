import 'package:isar/isar.dart';

part 'note_model.g.dart';

@collection
class NoteModel {
  NoteModel();

  Id id = Isar.autoIncrement;

  @Index()
  late int userId;

  late String title;
  String content = ''; // plain text / markdown

  @Index()
  String? folderName;

  List<String> tags = [];

  bool isPinned = false;
  bool isFavorite = false;
  bool hasChecklist = false;

  // Checklist items stored as parallel lists
  List<String> checklistItems = [];
  List<bool> checklistDone = [];

  List<String> imagePaths = [];

  bool isSynced = false;
  late DateTime createdAt;
  late DateTime updatedAt;
}

import 'package:isar/isar.dart';

part 'post_model.g.dart';

@collection
class PostModel {
  PostModel();

  Id id = Isar.autoIncrement;

  @Index()
  late int userId;

  String? title;
  late String content;
  List<String> imagePaths = [];
  List<String> tags = [];

  bool isPinned = false;
  bool isSaved = false;
  int likesCount = 0;
  bool isLiked = false;

  List<String> comments = [];
  List<String> commentAuthors = [];
  List<DateTime> commentDates = [];

  late DateTime createdAt;
  late DateTime updatedAt;
}

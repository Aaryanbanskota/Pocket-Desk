import 'package:isar/isar.dart';

part 'instant_model.g.dart';

@collection
class InstantModel {
  InstantModel();

  Id id = Isar.autoIncrement;

  @Index()
  late int userId;

  late String imagePath;
  String? textOverlay;

  // Text overlay normalized coordinates (0.0 to 1.0)
  double textX = 0.5;
  double textY = 0.5;

  late DateTime createdAt;
  late DateTime expiresAt;
}

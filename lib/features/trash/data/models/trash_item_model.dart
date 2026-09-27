import 'package:isar/isar.dart';

part 'trash_item_model.g.dart';

/// Item types that can be moved to Trash.
enum TrashItemType {
  post,
  note,
  task,
  event,
  expense,
}

/// Unified Trash collection stored in Isar.
@collection
class TrashItemModel {
  TrashItemModel();

  Id id = Isar.autoIncrement;

  @Index()
  late int userId;

  @enumerated
  late TrashItemType itemType;

  /// Original item ID from its respective database collection.
  late int originalId;

  /// Display title / summary of the deleted item.
  late String title;

  /// Detailed subtitle / preview snippet.
  String? snippet;

  /// JSON payload encoding full original model data for seamless restoration.
  late String payloadJson;

  /// Timestamp when the item was moved to Trash.
  @Index()
  late DateTime deletedAt;

  /// Calculated timestamp after 20 days when item is auto-purged.
  @Index()
  late DateTime expiresAt;
}

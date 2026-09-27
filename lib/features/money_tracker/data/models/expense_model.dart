import 'package:isar/isar.dart';

part 'expense_model.g.dart';

@collection
class ExpenseModel {
  ExpenseModel();

  Id id = Isar.autoIncrement;

  @Index()
  late int userId;

  int? walletId;

  late String title;
  late double amount;
  late String category;
  late DateTime date;

  String? note;
  List<String> tags = [];

  bool isDeleted = false;
  DateTime? deletedAt;

  late DateTime createdAt;
  late DateTime updatedAt;
}

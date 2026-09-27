import 'package:isar/isar.dart';

part 'wallet_model.g.dart';

@collection
class WalletModel {
  WalletModel();

  Id id = Isar.autoIncrement;

  @Index()
  late int userId;

  String name = 'Main Wallet';
  double balance = 10000.0;
  String currency = 'Rs.';
  bool isDefault = true;

  late DateTime createdAt;
  late DateTime updatedAt;
}

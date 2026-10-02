import 'package:isar/isar.dart';

part 'ai_settings_model.g.dart';

@collection
class AISettingsModel {
  AISettingsModel();

  Id id = Isar.autoIncrement;

  @Index()
  late int userId;

  bool isEnabled = true;
  bool masterControlEnabled = false;
  String provider = 'OpenRouter';
  String apiKey = '';
  String selectedModel = 'openai/gpt-4o-mini';

  // Specific Feature Toggles
  bool postReactionsEnabled = true;
  bool moneyAnalysisEnabled = true;
  bool noteAssistanceEnabled = true;

  // Mascot Assistant Customization
  String mascotDesignStyle = 'boxed'; // 'boxed' or 'minimalist'

  // Data Access Permissions
  bool allowNotesAccess = true;
  bool allowMoneyAccess = true;
  bool allowPostsAccess = true;
  bool allowAttachmentsAccess = false; // Always text-only by default

  late DateTime updatedAt;
}

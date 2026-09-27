import 'package:isar/isar.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/ai_settings_model.dart';

class AISettingsRepository {
  AISettingsRepository({required Isar isar}) : _isar = isar;
  final Isar _isar;

  Future<AISettingsModel> getOrCreateSettings(int userId) async {
    try {
      final existing = await _isar.aISettingsModels
          .where()
          .userIdEqualTo(userId)
          .findFirst();
      if (existing != null) return existing;

      final newSettings = AISettingsModel()
        ..userId = userId
        ..isEnabled = true
        ..provider = 'OpenRouter'
        ..apiKey = ''
        ..selectedModel = 'openai/gpt-4o-mini'
        ..updatedAt = DateTime.now();

      await _isar.writeTxn(() => _isar.aISettingsModels.put(newSettings));
      return newSettings;
    } catch (e, st) {
      AppLogger.e('Failed to get/create AI settings', tag: 'AIRepo', error: e, st: st);
      return AISettingsModel()
        ..userId = userId
        ..isEnabled = true;
    }
  }

  Future<void> saveSettings(AISettingsModel settings) async {
    try {
      settings.updatedAt = DateTime.now();
      await _isar.writeTxn(() => _isar.aISettingsModels.put(settings));
    } catch (e, st) {
      AppLogger.e('Failed to save AI settings', tag: 'AIRepo', error: e, st: st);
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/isar_provider.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/ai_settings_model.dart';
import '../../data/repositories/ai_settings_repository.dart';

final aiSettingsRepositoryProvider = FutureProvider<AISettingsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return AISettingsRepository(isar: isar);
});

class AISettingsNotifier extends AutoDisposeAsyncNotifier<AISettingsModel> {
  @override
  Future<AISettingsModel> build() async {
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) {
      return AISettingsModel()..isEnabled = true;
    }
    final repo = await ref.watch(aiSettingsRepositoryProvider.future);
    return repo.getOrCreateSettings(auth.user.id);
  }

  Future<void> updateSettings(AISettingsModel settings) async {
    final repo = await ref.read(aiSettingsRepositoryProvider.future);
    await repo.saveSettings(settings);
    ref.invalidateSelf();
  }

  Future<({bool success, String message})> testConnection(String apiKey, String model) async {
    if (apiKey.trim().isEmpty) {
      return (success: false, message: 'Please enter an API key');
    }
    try {
      final res = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${apiKey.trim()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': 'Test ping'}
          ],
          'max_tokens': 5,
        }),
      );

      if (res.statusCode == 200) {
        return (success: true, message: 'Connection successful!');
      } else {
        final err = jsonDecode(res.body);
        final msg = err['error']?['message'] ?? 'Status code ${res.statusCode}';
        return (success: false, message: 'Connection failed: $msg');
      }
    } catch (e) {
      return (success: false, message: 'Connection error: $e');
    }
  }

  /// Global helper to generate AI completions for Money analysis, Note assistance, or Feed reactions
  Future<String?> generateCompletion({
    required String prompt,
    required String systemPrompt,
    int? userId,
  }) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    final uid = userId ?? (auth is AuthAuthenticated ? auth.user.id : 0);
    final repo = await ref.read(aiSettingsRepositoryProvider.future);
    final settings = await repo.getOrCreateSettings(uid);

    if (!settings.isEnabled || settings.apiKey.trim().isEmpty) {
      AppLogger.w('AI completion aborted: isEnabled=${settings.isEnabled}, apiKeyLength=${settings.apiKey.length}', tag: 'AIService');
      return null;
    }

    try {
      final res = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${settings.apiKey.trim()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': settings.selectedModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 200,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;
        return content?.trim();
      } else {
        AppLogger.e('OpenRouter API returned status ${res.statusCode}: ${res.body}', tag: 'AIService');
      }
    } catch (e, st) {
      AppLogger.e('AI Completion failed', tag: 'AIService', error: e, st: st);
    }
    return null;
  }
}

final aiSettingsProvider = AutoDisposeAsyncNotifierProvider<AISettingsNotifier, AISettingsModel>(
  AISettingsNotifier.new,
);

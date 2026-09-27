import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import '../../data/models/ai_settings_model.dart';
import '../providers/ai_settings_notifier.dart';

class AISettingsWidget extends ConsumerStatefulWidget {
  const AISettingsWidget({super.key});

  @override
  ConsumerState<AISettingsWidget> createState() => _AISettingsWidgetState();
}

class _AISettingsWidgetState extends ConsumerState<AISettingsWidget> {
  final _apiKeyCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedModel = 'openai/gpt-4o-mini';
  bool _testing = false;
  String? _testResult;
  bool? _testSuccess;
  bool _isUnlocked = false;

  final List<String> _models = [
    'openai/gpt-4o-mini',
    'openai/gpt-4o',
    'anthropic/claude-3.5-sonnet',
    'meta-llama/llama-3.1-8b-instruct',
    'google/gemini-flash-1.5',
  ];

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showUnlockDialog(AISettingsModel settings, {required VoidCallback onUnlocked}) {
    _passwordCtrl.clear();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Enter Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your login password to unlock and edit your saved API key:'),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Login Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final pwd = _passwordCtrl.text.trim();
              if (pwd.isEmpty) return;
              final ok = await ref.read(authNotifierProvider.notifier).verifyPassword(pwd);
              if (!ctx.mounted) return;
              if (ok) {
                Navigator.pop(ctx);
                setState(() => _isUnlocked = true);
                onUnlocked();
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Incorrect password! Unable to unlock API key.')),
                );
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final aiAsync = ref.watch(aiSettingsProvider);

    return aiAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading AI settings: $e')),
      data: (settings) {
        if (_apiKeyCtrl.text.isEmpty && settings.apiKey.isNotEmpty) {
          _apiKeyCtrl.text = settings.apiKey;
          _selectedModel = settings.selectedModel;
        }

        final isKeySaved = settings.apiKey.isNotEmpty;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Master Enable Toggle
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: settings.isEnabled ? cs.primary : cs.outlineVariant.withOpacity(0.5), width: 1.5),
              ),
              child: SwitchListTile(
                title: const Text('Enable Pocketdesk AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: const Text('Global master switch for AI companion, money insights, notes helper, and feed reactions'),
                value: settings.isEnabled,
                activeColor: cs.primary,
                onChanged: (val) async {
                  final updated = settings..isEnabled = val;
                  await ref.read(aiSettingsProvider.notifier).updateSettings(updated);
                },
              ),
            ),
            const SizedBox(height: 20),

            if (!settings.isEnabled)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pocketdesk AI is currently turned OFF. Turn on the switch above to make AI available across all pages.',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

            // OpenRouter API Key Section
            Text('AI Provider & Security', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (isKeySaved && !_isUnlocked) ...[
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('API Key Locked & Secured 🔒', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Key stored securely. Authenticate with your password to view, delete, or update.', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.key_rounded, size: 18),
                        label: const Text('Unlock'),
                        onPressed: () => _showUnlockDialog(settings, onUnlocked: () {}),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              TextField(
                controller: _apiKeyCtrl,
                obscureText: !_isUnlocked && isKeySaved,
                decoration: InputDecoration(
                  labelText: 'OpenRouter API Key',
                  hintText: 'sk-or-v1-...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.key_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isKeySaved)
                        IconButton(
                          icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                          tooltip: 'Delete Key',
                          onPressed: () async {
                            settings.apiKey = '';
                            _apiKeyCtrl.clear();
                            await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('API Key deleted successfully')),
                              );
                            }
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.save_rounded),
                        tooltip: 'Save Key',
                        onPressed: () async {
                          settings.apiKey = _apiKeyCtrl.text.trim();
                          await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('API Key saved & locked securely')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _models.contains(_selectedModel) ? _selectedModel : _models.first,
              decoration: const InputDecoration(
                labelText: 'Model Selection',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.smart_toy_rounded),
              ),
              items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (m) async {
                if (m == null) return;
                setState(() => _selectedModel = m);
                settings.selectedModel = m;
                await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _testing ? null : () async {
                    setState(() { _testing = true; _testResult = null; });
                    final res = await ref.read(aiSettingsProvider.notifier).testConnection(_apiKeyCtrl.text, _selectedModel);
                    setState(() {
                      _testing = false;
                      _testSuccess = res.success;
                      _testResult = res.message;
                    });
                  },
                  icon: _testing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.bug_report_rounded),
                  label: const Text('Test Connection'),
                ),
                if (_testResult != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: TextStyle(
                        color: _testSuccess == true ? Colors.green : cs.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const Divider(height: 32),

            // Feature Toggles Section
            Text('AI Feature Enablement (All Pages)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Enable or disable AI capabilities for specific pages across Pocketdesk:', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),

            CheckboxListTile(
              title: const Text('Chat Page AI Companion 🤖'),
              subtitle: const Text('Talk to Pocketdesk AI buddy (yo {username}) when no P2P friend is connected'),
              value: settings.isEnabled, // Sync with global AI enabled
              onChanged: (val) async {
                settings.isEnabled = val ?? true;
                await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
              },
            ),
            CheckboxListTile(
              title: const Text('AI Post Reactions'),
              subtitle: const Text('Allow AI to post friendly reactions/comments on offline personal feed posts'),
              value: settings.postReactionsEnabled,
              onChanged: (val) async {
                settings.postReactionsEnabled = val ?? true;
                await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
              },
            ),
            CheckboxListTile(
              title: const Text('AI Money Health Analysis'),
              subtitle: const Text('Explain monthly spending patterns and budget insights in Money Health page'),
              value: settings.moneyAnalysisEnabled,
              onChanged: (val) async {
                settings.moneyAnalysisEnabled = val ?? true;
                await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
              },
            ),
            CheckboxListTile(
              title: const Text('AI Note Formatting Assistant'),
              subtitle: const Text('Formatting and auto-summarization help inside Note Editor'),
              value: settings.noteAssistanceEnabled,
              onChanged: (val) async {
                settings.noteAssistanceEnabled = val ?? true;
                await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
              },
            ),

            const Divider(height: 32),

            // AI Data Access Controls
            Text('AI Data Access Permissions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Strict privacy boundaries: control exactly which text modules AI can read.', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),

            CheckboxListTile(
              title: const Text('Post Text'),
              value: settings.allowPostsAccess,
              onChanged: (val) async {
                settings.allowPostsAccess = val ?? true;
                await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
              },
            ),
            CheckboxListTile(
              title: const Text('Notes'),
              value: settings.allowNotesAccess,
              onChanged: (val) async {
                settings.allowNotesAccess = val ?? true;
                await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
              },
            ),
            CheckboxListTile(
              title: const Text('Money Data'),
              value: settings.allowMoneyAccess,
              onChanged: (val) async {
                settings.allowMoneyAccess = val ?? true;
                await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
              },
            ),
            CheckboxListTile(
              title: const Text('Attachments / Images'),
              subtitle: const Text('Disabled by default. AI receives text only.'),
              value: settings.allowAttachmentsAccess,
              onChanged: (val) async {
                settings.allowAttachmentsAccess = val ?? false;
                await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
              },
            ),
          ],
        );
      },
    );
  }
}

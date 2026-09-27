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

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // ─── Master Enable Switch Card ─────────────────────────────────────
            Card(
              elevation: 0,
              color: settings.isEnabled ? cs.primaryContainer.withValues(alpha: 0.3) : cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: settings.isEnabled ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: const Text(
                    'Enable Pocketdesk AI',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: const Text(
                    'Global switch for AI companion, money insights, notes formatting, and feed reactions',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: settings.isEnabled,
                  onChanged: (val) async {
                    final updated = settings..isEnabled = val;
                    await ref.read(aiSettingsProvider.notifier).updateSettings(updated);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (!settings.isEnabled)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.8)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pocketdesk AI is currently turned OFF. Turn on the switch above to activate AI features across all screens.',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // ─── AI Provider & Security Card ──────────────────────────────────
            _buildSectionHeader(
              context,
              'AI Provider & Key Security',
              'Configure your OpenRouter API key and preferred model',
              Icons.key_rounded,
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isKeySaved && !_isUnlocked) ...[
                      // Locked State - Responsive Layout without Horizontal Overflow
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_rounded, color: Colors.green, size: 26),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('API Key Secured 🔒', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text(
                                      'Key is saved & locked securely.',
                                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.key_rounded, size: 16),
                            label: const Text('Unlock Key'),
                            onPressed: () => _showUnlockDialog(settings, onUnlocked: () {}),
                          ),
                        ],
                      ),
                    ] else ...[
                      // API Key Text Field (Full Width, non-overflowing)
                      TextField(
                        controller: _apiKeyCtrl,
                        obscureText: !_isUnlocked && isKeySaved,
                        decoration: const InputDecoration(
                          labelText: 'OpenRouter API Key',
                          hintText: 'sk-or-v1-...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.key_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Action buttons in clean Row / Wrap
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: const Text('Save Key'),
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
                          if (isKeySaved)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              icon: const Icon(Icons.delete_forever_rounded, size: 18),
                              label: const Text('Delete Key'),
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
                        ],
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Model Selection Dropdown (with isExpanded and TextOverflow.ellipsis)
                    DropdownButtonFormField<String>(
                      initialValue: _models.contains(_selectedModel) ? _selectedModel : _models.first,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Model Selection',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.smart_toy_rounded),
                      ),
                      items: _models
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (m) async {
                        if (m == null) return;
                        setState(() => _selectedModel = m);
                        settings.selectedModel = m;
                        await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
                      },
                    ),

                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _testing
                              ? null
                              : () async {
                                  setState(() {
                                    _testing = true;
                                    _testResult = null;
                                  });
                                  final res = await ref.read(aiSettingsProvider.notifier).testConnection(_apiKeyCtrl.text, _selectedModel);
                                  setState(() {
                                    _testing = false;
                                    _testSuccess = res.success;
                                    _testResult = res.message;
                                  });
                                },
                          icon: _testing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.bug_report_rounded, size: 18),
                          label: const Text('Test Connection'),
                        ),
                        if (_testResult != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _testSuccess == true
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : cs.errorContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _testResult!,
                              style: TextStyle(
                                color: _testSuccess == true ? Colors.green[700] : cs.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ─── Feature Enablement Card ──────────────────────────────────────
            _buildSectionHeader(
              context,
              'AI Feature Enablement',
              'Enable or disable AI modules across Pocketdesk screens',
              Icons.widgets_rounded,
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Chat AI Companion 🤖', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Fall back to Pocketdesk AI companion when no P2P friend is connected'),
                    value: settings.isEnabled,
                    onChanged: (val) async {
                      settings.isEnabled = val;
                      await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('AI Post Reactions', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Allow AI to post reactions and comments on local feed posts'),
                    value: settings.postReactionsEnabled,
                    onChanged: (val) async {
                      settings.postReactionsEnabled = val;
                      await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('AI Money Health Analysis', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Provide budget recommendations and spending score (0-100)'),
                    value: settings.moneyAnalysisEnabled,
                    onChanged: (val) async {
                      settings.moneyAnalysisEnabled = val;
                      await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('AI Note Formatting Assistant', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Auto-summarization and rich formatting inside Note Editor'),
                    value: settings.noteAssistanceEnabled,
                    onChanged: (val) async {
                      settings.noteAssistanceEnabled = val;
                      await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Data Access Permissions Card ─────────────────────────────────
            _buildSectionHeader(
              context,
              'Data Access Permissions',
              'Control exactly which local text modules AI is permitted to read',
              Icons.shield_rounded,
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Post Text Access', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: settings.allowPostsAccess,
                    onChanged: (val) async {
                      settings.allowPostsAccess = val;
                      await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('Notes Text Access', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: settings.allowNotesAccess,
                    onChanged: (val) async {
                      settings.allowNotesAccess = val;
                      await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('Money Data Access', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: settings.allowMoneyAccess,
                    onChanged: (val) async {
                      settings.allowMoneyAccess = val;
                      await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('Attachments / Images', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Disabled by default. AI receives text content only.'),
                    value: settings.allowAttachmentsAccess,
                    onChanged: (val) async {
                      settings.allowAttachmentsAccess = val;
                      await ref.read(aiSettingsProvider.notifier).updateSettings(settings);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

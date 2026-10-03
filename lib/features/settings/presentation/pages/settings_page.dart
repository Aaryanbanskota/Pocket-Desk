import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_mode_notifier.dart';
import '../widgets/qr_data_share_widget.dart';
import '../widgets/device_settings_widget.dart';
import '../widgets/privacy_settings_widget.dart';
import '../widgets/appearance_settings_widget.dart';
import '../widgets/security_settings_widget.dart';
import '../widgets/ai_settings_widget.dart';

class _SettingSearchItem {
  const _SettingSearchItem({
    required this.title,
    required this.subtitle,
    required this.tabName,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String tabName;
  final IconData icon;
}

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_SettingSearchItem> _getSearchableItems(bool isShareUnlocked) {
    return [
      // ─── AI TAB ─────────────────────────────────────────────────────────────
      const _SettingSearchItem(
        title: 'AI Master Control & Toggle',
        subtitle: 'Turn AI functionality on/off or allow action execution',
        tabName: 'AI',
        icon: Icons.smart_toy_rounded,
      ),
      const _SettingSearchItem(
        title: 'OpenRouter API Key & Unlock',
        subtitle: 'Configure your OpenRouter key, password unlock & API security',
        tabName: 'AI',
        icon: Icons.key_rounded,
      ),
      const _SettingSearchItem(
        title: 'AI Model Selection',
        subtitle: 'Choose models: GPT-4o, Claude 3.5 Sonnet, Llama 3.1, Gemini Flash',
        tabName: 'AI',
        icon: Icons.psychology_rounded,
      ),
      const _SettingSearchItem(
        title: 'AI Mascot Design Style',
        subtitle: 'Toggle floating minimalist mascot or boxed card chat dialog style',
        tabName: 'AI',
        icon: Icons.design_services_rounded,
      ),
      const _SettingSearchItem(
        title: 'AI Temperature & Token Limit',
        subtitle: 'Tune response creativity, max tokens, and context window limits',
        tabName: 'AI',
        icon: Icons.tune_rounded,
      ),

      // ─── SHARE TAB (IF UNLOCKED) ────────────────────────────────────────────
      if (isShareUnlocked)
        const _SettingSearchItem(
          title: 'Generate Login QR Code',
          subtitle: 'Share desktop session credentials with mobile app via camera QR',
          tabName: 'Share',
          icon: Icons.qr_code_2_rounded,
        ),
      if (isShareUnlocked)
        const _SettingSearchItem(
          title: 'Export / Import Settings & Sync',
          subtitle: 'Backup or sync app configuration via QR or file payload',
          tabName: 'Share',
          icon: Icons.swap_horiz_rounded,
        ),

      // ─── DEVICES TAB ────────────────────────────────────────────────────────
      const _SettingSearchItem(
        title: 'Connected Devices & P2P Sync',
        subtitle: 'Manage local network paired companion devices, device name & status',
        tabName: 'Devices',
        icon: Icons.devices_rounded,
      ),
      const _SettingSearchItem(
        title: 'App Software Updates',
        subtitle: 'Check for PocketDesk app updates, channel releases, and version info',
        tabName: 'Devices',
        icon: Icons.system_update_rounded,
      ),

      // ─── APPEARANCE TAB ─────────────────────────────────────────────────────
      const _SettingSearchItem(
        title: 'Theme Mode (Light / Dark / System)',
        subtitle: 'Switch application color theme, dark mode, and high contrast colors',
        tabName: 'Appearance',
        icon: Icons.palette_rounded,
      ),
      const _SettingSearchItem(
        title: 'Text Size & Typography',
        subtitle: 'Adjust app font scaling, readable text size, and spacing',
        tabName: 'Appearance',
        icon: Icons.format_size_rounded,
      ),
      const _SettingSearchItem(
        title: 'Rearrange Dashboard & Menu Widgets',
        subtitle: 'Toggle custom widget reordering feature on or off on homepage',
        tabName: 'Appearance',
        icon: Icons.widgets_rounded,
      ),

      // ─── PRIVACY TAB ────────────────────────────────────────────────────────
      const _SettingSearchItem(
        title: 'Data Privacy & Local Encryption',
        subtitle: 'Manage telemetry, local database encryption, analytics & cloud backup',
        tabName: 'Privacy',
        icon: Icons.privacy_tip_rounded,
      ),
      const _SettingSearchItem(
        title: 'Sync & Data Sharing Permissions',
        subtitle: 'Configure P2P syncing, peer permissions, and offline mode data',
        tabName: 'Privacy',
        icon: Icons.sync_rounded,
      ),

      // ─── SECURITY TAB ───────────────────────────────────────────────────────
      const _SettingSearchItem(
        title: 'Biometric Authentication & App Lock',
        subtitle: 'Fingerprint unlock, Face ID, biometrics, passcode, and auto-lock security',
        tabName: 'Security',
        icon: Icons.fingerprint_rounded,
      ),
      const _SettingSearchItem(
        title: 'Change Account Password & Credentials',
        subtitle: 'Update user account login password and credential security',
        tabName: 'Security',
        icon: Icons.lock_reset_rounded,
      ),
    ];
  }

  void _jumpToTab(BuildContext context, String tabName, bool isShareUnlocked) {
    final Map<String, int> tabIndexes = isShareUnlocked
        ? {
            'AI': 0,
            'Share': 1,
            'Devices': 2,
            'Appearance': 3,
            'Privacy': 4,
            'Security': 5,
          }
        : {
            'AI': 0,
            'Devices': 1,
            'Appearance': 2,
            'Privacy': 3,
            'Security': 4,
          };

    final targetIndex = tabIndexes[tabName];
    final tabController = DefaultTabController.maybeOf(context);
    if (targetIndex != null && tabController != null) {
      tabController.animateTo(targetIndex);
      setState(() {
        _isSearching = false;
        _searchQuery = '';
        _searchCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isShareUnlocked =
        ref.watch(shareTabUnlockedProvider).valueOrNull ?? false;

    final tabs = [
      const Tab(
        icon: Icon(Icons.smart_toy_rounded),
        text: 'AI',
      ),
      if (isShareUnlocked)
        const Tab(
          icon: Icon(Icons.qr_code_2_rounded),
          text: 'Share',
        ),
      const Tab(
        icon: Icon(Icons.devices_rounded),
        text: 'Devices',
      ),
      const Tab(
        icon: Icon(Icons.palette_rounded),
        text: 'Appearance',
      ),
      const Tab(
        icon: Icon(Icons.privacy_tip_rounded),
        text: 'Privacy',
      ),
      const Tab(
        icon: Icon(Icons.security_rounded),
        text: 'Security',
      ),
    ];

    final views = [
      const AISettingsWidget(),
      if (isShareUnlocked) const QrDataShareWidget(),
      const DeviceSettingsWidget(),
      const AppearanceSettingsWidget(),
      const PrivacySettingsWidget(),
      const SecuritySettingsWidget(),
    ];

    final searchableItems = _getSearchableItems(isShareUnlocked);
    final queryTokens = _searchQuery
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final filteredItems = queryTokens.isEmpty
        ? searchableItems
        : searchableItems.where((item) {
            final searchableText =
                '${item.title} ${item.subtitle} ${item.tabName}'.toLowerCase();
            // All typed query tokens must match somewhere in title/subtitle/tabName
            return queryTokens.every((token) => searchableText.contains(token));
          }).toList();

    return DefaultTabController(
      key: ValueKey(isShareUnlocked),
      length: isShareUnlocked ? 6 : 5,
      child: Builder(
        builder: (tabContext) {
          return Scaffold(
            appBar: AppBar(
              title: _isSearching
                  ? TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search settings...',
                        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    )
                  : Text(
                      'Settings',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
                  tooltip: _isSearching ? 'Close Search' : 'Search Settings',
                  onPressed: () {
                    setState(() {
                      if (_isSearching) {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchCtrl.clear();
                      } else {
                        _isSearching = true;
                      }
                    });
                  },
                ),
              ],
              bottom: _isSearching
                  ? null
                  : TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      indicatorColor: colorScheme.primary,
                      indicatorWeight: 3,
                      tabs: tabs,
                    ),
            ),
            body: _isSearching
                ? (filteredItems.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 48, color: colorScheme.onSurfaceVariant),
                              const SizedBox(height: 12),
                              Text(
                                'No settings matching "$_searchQuery"',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                foregroundColor: colorScheme.onPrimaryContainer,
                                child: Icon(item.icon),
                              ),
                              title: Text(item.title,
                                  style:
                                      const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(item.subtitle),
                              trailing: Chip(
                                label: Text(item.tabName),
                                labelStyle: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () =>
                                  _jumpToTab(tabContext, item.tabName, isShareUnlocked),
                            ),
                          );
                        },
                      ))
                : TabBarView(
                    children: views,
                  ),
          );
        },
      ),
    );
  }
}

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

class _SettingsPageState extends ConsumerState<SettingsPage>
    with TickerProviderStateMixin {
  TabController? _tabController;
  bool? _lastUnlockedState;
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  void _updateTabController(bool isUnlocked) {
    if (_lastUnlockedState != isUnlocked) {
      _lastUnlockedState = isUnlocked;
      _tabController?.dispose();
      final count = isUnlocked ? 6 : 5;
      _tabController = TabController(length: count, vsync: this);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  List<_SettingSearchItem> _getSearchableItems(bool isShareUnlocked) {
    return [
      const _SettingSearchItem(
        title: 'AI Model & Provider',
        subtitle: 'Configure Ollama, OpenAI, or local AI endpoints',
        tabName: 'AI',
        icon: Icons.smart_toy_rounded,
      ),
      const _SettingSearchItem(
        title: 'AI Temperature & Token Limit',
        subtitle: 'Tune response creativity and token limits',
        tabName: 'AI',
        icon: Icons.tune_rounded,
      ),
      if (isShareUnlocked)
        const _SettingSearchItem(
          title: 'Generate Login QR Code',
          subtitle: 'Share desktop session credentials with mobile app',
          tabName: 'Share',
          icon: Icons.qr_code_2_rounded,
        ),
      if (isShareUnlocked)
        const _SettingSearchItem(
          title: 'Export / Import Settings',
          subtitle: 'Sync app state via QR or file payload',
          tabName: 'Share',
          icon: Icons.swap_horiz_rounded,
        ),
      const _SettingSearchItem(
        title: 'Connected Devices',
        subtitle: 'Manage local network paired companion devices',
        tabName: 'Devices',
        icon: Icons.devices_rounded,
      ),
      const _SettingSearchItem(
        title: 'Theme Mode (Light / Dark / System)',
        subtitle: 'Switch application color theme and high contrast colors',
        tabName: 'Appearance',
        icon: Icons.palette_rounded,
      ),
      const _SettingSearchItem(
        title: 'Rearrange Dashboard & Menu Widgets',
        subtitle: 'Toggle custom widget reordering feature on or off',
        tabName: 'Appearance',
        icon: Icons.widgets_rounded,
      ),
      const _SettingSearchItem(
        title: 'Data Privacy & Analytics',
        subtitle: 'Manage telemetry, diagnostics, and data collection',
        tabName: 'Privacy',
        icon: Icons.privacy_tip_rounded,
      ),
      const _SettingSearchItem(
        title: 'App Lock & Security Credentials',
        subtitle: 'Biometrics, passcode protection, and encryption',
        tabName: 'Security',
        icon: Icons.security_rounded,
      ),
    ];
  }

  void _jumpToTab(String tabName, bool isShareUnlocked) {
    final Map<String, int> tabIndexes;
    if (isShareUnlocked) {
      tabIndexes = {
        'AI': 0,
        'Share': 1,
        'Devices': 2,
        'Appearance': 3,
        'Privacy': 4,
        'Security': 5,
      };
    } else {
      tabIndexes = {
        'AI': 0,
        'Devices': 1,
        'Appearance': 2,
        'Privacy': 3,
        'Security': 4,
      };
    }

    final targetIndex = tabIndexes[tabName];
    if (targetIndex != null && _tabController != null) {
      _tabController!.animateTo(targetIndex);
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

    _updateTabController(isShareUnlocked);

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
    final filteredItems = _searchQuery.isEmpty
        ? searchableItems
        : searchableItems.where((item) {
            final q = _searchQuery.toLowerCase();
            return item.title.toLowerCase().contains(q) ||
                item.subtitle.toLowerCase().contains(q) ||
                item.tabName.toLowerCase().contains(q);
          }).toList();

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
                controller: _tabController,
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
                        onTap: () => _jumpToTab(item.tabName, isShareUnlocked),
                      ),
                    );
                  },
                ))
          : TabBarView(
              controller: _tabController,
              children: views,
            ),
    );
  }
}

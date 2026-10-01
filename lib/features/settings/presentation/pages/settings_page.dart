import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_mode_notifier.dart';
import '../widgets/qr_data_share_widget.dart';
import '../widgets/device_settings_widget.dart';
import '../widgets/privacy_settings_widget.dart';
import '../widgets/appearance_settings_widget.dart';
import '../widgets/security_settings_widget.dart';
import '../widgets/ai_settings_widget.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with TickerProviderStateMixin {
  TabController? _tabController;
  bool? _lastUnlockedState;

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
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isShareUnlocked = ref.watch(shareTabUnlockedProvider).valueOrNull ?? false;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        bottom: TabBar(
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
      body: TabBarView(
        controller: _tabController,
        children: views,
      ),
    );
  }
}

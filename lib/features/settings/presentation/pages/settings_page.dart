import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/qr_data_share_widget.dart';
import '../widgets/device_settings_widget.dart';
import '../widgets/privacy_settings_widget.dart';
import '../widgets/appearance_settings_widget.dart';
import '../widgets/security_settings_widget.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          tabs: const [
            Tab(
              icon: Icon(Icons.qr_code_2_rounded),
              text: 'Share',
            ),
            Tab(
              icon: Icon(Icons.devices_rounded),
              text: 'Devices',
            ),
            Tab(
              icon: Icon(Icons.palette_rounded),
              text: 'Appearance',
            ),
            Tab(
              icon: Icon(Icons.privacy_tip_rounded),
              text: 'Privacy',
            ),
            Tab(
              icon: Icon(Icons.security_rounded),
              text: 'Security',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          QrDataShareWidget(),
          DeviceSettingsWidget(),
          AppearanceSettingsWidget(),
          PrivacySettingsWidget(),
          SecuritySettingsWidget(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/myday_database.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/circular_icon_button.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../../../core/services/app_update_service.dart';
import '../../auth/data/auth_repository.dart';
import 'developer_mode_screen.dart';

/// About App Screen
///
/// Displays official application version, build number, and recent update date.
/// Contains the secret 10-tap gesture on the version tile to unlock Developer Mode.
class AboutAppScreen extends StatefulWidget {
  final UserSession? session;
  final MyDayDatabase? db;
  final bool isDarkMode;

  const AboutAppScreen({
    super.key,
    this.session,
    this.db,
    this.isDarkMode = true,
  });

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  int _versionClickCount = 0;
  bool _isDevModeUnlocked = false;
  bool _isCheckingUpdates = false;
  String _versionNumber = '1.2.2';
  String _buildNumber = '6';

  // Release metadata
  static const String recentUpdatedDate = 'October 26, 2026';
  static const String releaseChannel = 'Stable Release (Official)';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _checkDevModeUnlocked();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          if (info.version.isNotEmpty) _versionNumber = info.version;
          if (info.buildNumber.isNotEmpty) _buildNumber = info.buildNumber;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkDevModeUnlocked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlocked = prefs.getBool('developer_mode_unlocked') ?? false;
      if (mounted) {
        setState(() => _isDevModeUnlocked = unlocked);
      }
    } catch (_) {}
  }

  void _onVersionTapped() async {
    if (_isDevModeUnlocked) {
      UndoToast.show(
        context,
        message: 'Developer mode is already active! Tap below to open.',
      );
      return;
    }

    setState(() => _versionClickCount++);

    if (_versionClickCount >= 10) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('developer_mode_unlocked', true);
      setState(() => _isDevModeUnlocked = true);

      if (mounted) {
        UndoToast.show(
          context,
          message: '🎉 Developer Mode Unlocked! Storage & Database Inspector enabled.',
        );
      }
    } else if (_versionClickCount >= 5) {
      final remaining = 10 - _versionClickCount;
      if (mounted) {
        UndoToast.show(
          context,
          message: 'You are $remaining step${remaining == 1 ? '' : 's'} away from Developer Mode.',
        );
      }
    }
  }

  void _openDeveloperMode() {
    final effectiveDb = widget.db ?? MyDayDatabase.create();
    final effectiveSession = widget.session ??
        const UserSession(
          accountId: 'dev_user',
          name: 'Developer Mode',
          handle: 'developer',
          bio: 'Dev Inspector',
          isCloud: false,
          isBioEnabled: false,
        );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DeveloperModeScreen(
          session: effectiveSession,
          db: effectiveDb,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    ).then((_) => _checkDevModeUnlocked());
  }

  Future<void> _checkForUpdates() async {
    if (_isCheckingUpdates) return;
    setState(() => _isCheckingUpdates = true);
    try {
      await AppUpdateService.checkForUpdates(
        context,
        showStatus: true,
        manual: true,
      );
    } catch (e) {
      if (mounted) {
        UndoToast.show(context, message: 'Could not check for updates: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdates = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircularIconButton(
            icon: AppIcons.back,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        titleSpacing: 0,
        title: Text(
          'About Pocketdesk',
          style: AppTypography.h3.copyWith(color: context.appText),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_isDevModeUnlocked)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ActionChip(
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
                avatar: const Icon(AppIcons.sparkles, size: 14, color: AppColors.accent),
                label: const Text(
                  'DEV MODE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                onPressed: _openDeveloperMode,
              ),
            ),
        ],
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // 1. App Brand Hero
          Center(
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: context.appLine, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.accent, Color(0xFF7B3FE4)],
                          ),
                        ),
                        child: const Center(
                          child: Icon(AppIcons.widget, size: 40, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'MyDay',
                  style: AppTypography.h1.copyWith(
                    color: context.appText,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your offline-first productivity & life ecosystem',
                  style: AppTypography.captionMuted.copyWith(
                    color: context.appMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Version & Recent Update Card (INTERACTIVE TAP TARGET)
          InkWell(
            onTap: _onVersionTapped,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isDevModeUnlocked
                      ? AppColors.accent.withValues(alpha: 0.4)
                      : context.appLine,
                  width: _isDevModeUnlocked ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(AppIcons.checkSquare, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'v$_versionNumber',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: context.appText,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: context.appSurface2,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Build $_buildNumber',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: context.appMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              releaseChannel,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isDevModeUnlocked && _versionClickCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Tap: $_versionClickCount/10',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(color: context.appLine, height: 1),
                  const SizedBox(height: 12),

                  // Recent update date display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Update Date:',
                        style: TextStyle(fontSize: 12, color: context.appMuted),
                      ),
                      Text(
                        recentUpdatedDate,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: context.appText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Database Engine:',
                        style: TextStyle(fontSize: 12, color: context.appMuted),
                      ),
                      const Text(
                        'SQLite 3 (Drift Offline Engine)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Software Update Check Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.system_update_rounded, color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Software Updates',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.appText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Check for the latest features & stability updates',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.appMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: context.appLine, height: 1),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isCheckingUpdates ? null : _checkForUpdates,
                    icon: _isCheckingUpdates
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      _isCheckingUpdates ? 'Checking for updates...' : 'Check for Updates',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Unlocked Developer Mode Card
          if (_isDevModeUnlocked)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(AppIcons.sparkles, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Developer Mode Active',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: context.appText,
                              ),
                            ),
                            Text(
                              'Inspect raw database tables, storage size & calendar streams',
                              style: TextStyle(fontSize: 11.5, color: context.appMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _openDeveloperMode,
                      icon: const Icon(AppIcons.eye, size: 18),
                      label: const Text(
                        'Open Developer Tools & Inspector',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // 4. Feature Architecture Highlights
          Text(
            'SYSTEM ARCHITECTURE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.appMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appLine),
            ),
            child: Column(
              children: [
                _buildFeatureTile(
                  icon: AppIcons.checkSquare,
                  title: 'Offline-First Engine',
                  subtitle: 'All reads & writes persist locally first in SQLite',
                ),
                Divider(height: 1, color: context.appLine),
                _buildFeatureTile(
                  icon: AppIcons.calendar,
                  title: '4-Stream Calendar Hub',
                  subtitle: 'Aggregates tasks, notes, moments and transactions',
                ),
                Divider(height: 1, color: context.appLine),
                _buildFeatureTile(
                  icon: AppIcons.fingerprint,
                  title: 'Hardware Biometric Shield',
                  subtitle: 'Native fingerprint/face unlock with auto-lock timer',
                ),
                Divider(height: 1, color: context.appLine),
                _buildFeatureTile(
                  icon: AppIcons.sparkles,
                  title: 'Decrypted Local Sandbox',
                  subtitle: 'User data is never transmitted to third parties',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 5. Copyright Footer
          Center(
            child: Column(
              children: [
                Text(
                  '© 2026 MyDay (Pocketdesk)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Created with offline-first privacy at heart',
                  style: TextStyle(fontSize: 11, color: context.appMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.appSurface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.appText,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: context.appMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

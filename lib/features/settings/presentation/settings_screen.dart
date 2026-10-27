import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/app_bottom_sheet.dart';
import '../../../core/design_system/widgets/app_scaffold.dart';
import '../../../core/design_system/widgets/calendar_system_toggle.dart';
import '../../../core/design_system/widgets/circular_icon_button.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../auth/data/auth_repository.dart';
import '../../budget/data/budget_repository.dart';
import '../../feed/data/feed_repository.dart';
import '../../notes/data/notes_repository.dart';
import '../../tasks/data/tasks_repository.dart';
import '../../trash/data/trash_repository.dart';
import '../data/legacy_pocketdesk_importer.dart';
import 'about_app_screen.dart';
import 'developer_mode_screen.dart';
import 'dialogs/pull_pocketdesk_data_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final UserSession session;
  final AuthRepository authRepository;
  final TasksRepository tasksRepository;
  final NotesRepository notesRepository;
  final BudgetRepository budgetRepository;
  final FeedRepository feedRepository;
  final TrashRepository trashRepository;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final ValueChanged<MyDayNavTab> onNavigate;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.session,
    required this.authRepository,
    required this.tasksRepository,
    required this.notesRepository,
    required this.budgetRepository,
    required this.feedRepository,
    required this.trashRepository,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBS = false;
  String _currency = 'Rs';
  String _currencyName = 'NPR - Nepalese Rupee';
  bool _timerNotifications = true;
  bool _taskReminders = true;
  bool _soundEffects = true;
  bool _systemNotificationsGranted = true;
  bool _biometricEnabled = false;
  bool _canUseBiometrics = false;
  String _autoLockDuration = 'Immediately';
  bool _isDevModeUnlocked = false;

  int _tasksCount = 0;
  int _notesCount = 0;
  int _momentsCount = 0;
  int _txsCount = 0;

  final List<Map<String, String>> _currencies = [
    {'code': 'Rs', 'name': 'NPR - Nepalese Rupee'},
    {'code': '\$', 'name': 'USD - United States Dollar'},
    {'code': '€', 'name': 'EUR - Euro'},
    {'code': '£', 'name': 'GBP - British Pound'},
    {'code': '₹', 'name': 'INR - Indian Rupee'},
    {'code': 'A\$', 'name': 'AUD - Australian Dollar'},
    {'code': 'C\$', 'name': 'CAD - Canadian Dollar'},
    {'code': '¥', 'name': 'JPY - Japanese Yen'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadDataStats();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final cal = prefs.getString('myday_calendar_system') ?? 'AD';
    final cur = prefs.getString('myday_currency') ?? 'Rs';
    final timerNotifs = prefs.getBool('myday_timer_notifications') ?? true;
    final taskReminders = prefs.getBool('myday_task_reminders') ?? true;
    final soundEffects = prefs.getBool('myday_sound_effects') ?? true;
    final autoLock = prefs.getString('myday_autolock') ?? 'After 2 minutes';
    final devMode = prefs.getBool('developer_mode_unlocked') ?? false;
    final canBiometrics = await widget.authRepository.biometricService.isBiometricAvailable();
    final biometrics = widget.session.isBioEnabled;

    final curName = _currencies.firstWhere(
      (c) => c['code'] == cur,
      orElse: () => {'code': cur, 'name': cur},
    )['name']!;

    bool grantedNotifs = true;
    try {
      grantedNotifs = await LocalNotificationService.requestNotificationPermissions();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isBS = cal == 'BS';
        _currency = cur;
        _currencyName = curName;
        _timerNotifications = timerNotifs;
        _taskReminders = taskReminders;
        _soundEffects = soundEffects;
        _systemNotificationsGranted = grantedNotifs;
        _biometricEnabled = biometrics;
        _canUseBiometrics = canBiometrics;
        _autoLockDuration = autoLock;
        _isDevModeUnlocked = devMode;
      });
    }
  }

  Future<void> _loadDataStats() async {
    final accountId = widget.session.accountId;
    final tasks = await widget.tasksRepository.getTasks(accountId);
    final notes = await widget.notesRepository.getNotes(accountId);
    final posts = await widget.feedRepository.getPosts(accountId);
    final txs = await widget.budgetRepository.getTransactions(accountId: accountId);

    if (mounted) {
      setState(() {
        _tasksCount = tasks.length;
        _notesCount = notes.length;
        _momentsCount = posts.length;
        _txsCount = txs.length;
      });
    }
  }

  Future<void> _updateCalendarSystem(bool isBS) async {
    setState(() => _isBS = isBS);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('myday_calendar_system', isBS ? 'BS' : 'AD');
  }

  Future<void> _selectCurrency() async {
    final selected = await AppBottomSheet.show<Map<String, String>>(
      context: context,
      title: 'Select Default Currency',
      builder: (sheetContext) {
        return Column(
          children: _currencies.map((c) {
            final isSelected = c['code'] == _currency;
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: isSelected ? sheetContext.appSurface2 : Colors.transparent,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : sheetContext.appSurface2,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    c['code']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.accent : sheetContext.appText,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              title: Text(
                c['name']!,
                style: TextStyle(
                  color: sheetContext.appText,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: isSelected ? const Icon(AppIcons.check, color: AppColors.accent, size: 20) : null,
              onTap: () {
                Navigator.of(sheetContext).pop(c);
              },
            );
          }).toList(),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _currency = selected['code']!;
        _currencyName = selected['name']!;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('myday_currency', selected['code']!);
      if (mounted) {
        UndoToast.show(context, message: 'Currency updated to ${selected['name']}');
      }
    }
  }

  Future<void> _selectAutoLock() async {
    final options = ['After 2 minutes', 'After 5 minutes', 'After 15 minutes', 'Immediately', 'Never'];
    final selected = await AppBottomSheet.show<String>(
      context: context,
      title: 'Auto-Lock Timeout',
      builder: (sheetContext) {
        return Column(
          children: options.map((opt) {
            final isSelected = opt == _autoLockDuration;
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: isSelected ? sheetContext.appSurface2 : Colors.transparent,
              title: Text(
                opt,
                style: TextStyle(
                  color: sheetContext.appText,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: isSelected ? const Icon(AppIcons.check, color: AppColors.accentOrange, size: 20) : null,
              onTap: () {
                Navigator.of(sheetContext).pop(opt);
              },
            );
          }).toList(),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _autoLockDuration = selected);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('myday_autolock', selected);
      if (mounted) {
        UndoToast.show(context, message: 'Auto-lock set to $selected');
      }
    }
  }

  Future<void> _confirmEmptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: dialogCtx.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Empty Trash?',
          style: AppTypography.h3.copyWith(color: dialogCtx.appText),
        ),
        content: Text(
          'All deleted tasks, notes, transactions, posts, and files will be permanently erased. This cannot be undone.',
          style: AppTypography.body.copyWith(color: dialogCtx.appMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: dialogCtx.appMuted, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Empty Trash', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.trashRepository.emptyAllTrash(widget.session.accountId);
      await _loadDataStats();
      if (mounted) {
        UndoToast.show(context, message: 'Trash emptied permanently');
      }
    }
  }

  Future<void> _toggleBiometrics(bool enable) async {
    if (enable && !_canUseBiometrics) {
      if (mounted) {
        UndoToast.show(context, message: 'Biometrics is not available or enrolled on this device');
      }
      return;
    }
    setState(() => _biometricEnabled = enable);
    await widget.authRepository.toggleBiometric(widget.session, enable);
    if (mounted) {
      UndoToast.show(
        context,
        message: enable ? 'Biometric security activated' : 'Biometric security deactivated',
      );
    }
  }

  Future<void> _exportDataJson() async {
    try {
      final jsonStr = await widget.authRepository.exportDataJson(widget.session.accountId);
      final docsDir = await getApplicationDocumentsDirectory();
      final file = File('${docsDir.path}/myday-backup-${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);

      if (mounted) {
        UndoToast.show(
          context,
          message: 'Data backup saved: ${file.path}',
        );
      }
    } catch (e) {
      if (mounted) {
        UndoToast.show(context, message: 'Export failed: $e');
      }
    }
  }

  void _showPullPocketdeskData() {
    final importer = LegacyPocketdeskImporter(widget.authRepository.db);
    PullPocketdeskDataSheet.show(
      context: context,
      importer: importer,
      currentAccountId: widget.session.accountId,
      onDataImported: () {
        _loadDataStats();
        if (mounted) {
          UndoToast.show(context, message: 'Pocketdesk data successfully integrated');
        }
      },
    );
  }

  void _openAboutApp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AboutAppScreen(
          session: widget.session,
          db: widget.authRepository.db,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    ).then((_) => _checkDevMode());
  }

  Future<void> _checkDevMode() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getBool('developer_mode_unlocked') ?? false;
    if (mounted && unlocked != _isDevModeUnlocked) {
      setState(() => _isDevModeUnlocked = unlocked);
    }
  }

  void _openDeveloperMode() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DeveloperModeScreen(
          session: widget.session,
          db: widget.authRepository.db,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    ).then((_) => _checkDevMode());
  }

  @override
  Widget build(BuildContext context) {
    final initial = (widget.session.name.isNotEmpty ? widget.session.name[0] : 'U').toUpperCase();

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 26),
      children: [
        // 1. Account Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.appLine, width: 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.name,
                      style: AppTypography.h3.copyWith(color: context.appText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.session.isCloud
                          ? (widget.session.email ?? 'Cloud account')
                          : 'Local Offline Account',
                      style: AppTypography.captionMuted.copyWith(color: context.appMuted),
                    ),
                  ],
                ),
              ),
              CircularIconButton(
                icon: AppIcons.forward,
                onPressed: () => widget.onNavigate(MyDayNavTab.profile),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. General & Regional Section
        _buildSectionHeader('General & Regional', AppIcons.calendar),
        const SizedBox(height: 8),
        _buildSettingsCard(
          children: [
            // Calendar System
            _buildSettingRow(
              icon: AppIcons.calendar,
              title: 'Calendar System',
              subtitle: _isBS ? 'Bikram Sambat (BS)' : 'Gregorian (AD)',
              trailing: CalendarSystemToggle(
                isBS: _isBS,
                onChanged: _updateCalendarSystem,
                isCreamContext: false,
              ),
            ),
            Divider(color: context.appLine, height: 1),

            // Default Currency
            _buildSettingRow(
              icon: AppIcons.wallet,
              title: 'Default Currency',
              subtitle: _currencyName,
              onTap: _selectCurrency,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currency,
                    style: const TextStyle(
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(AppIcons.forward, size: 16, color: context.appMuted),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 3. Appearance Section
        _buildSectionHeader('Appearance', AppIcons.sun),
        const SizedBox(height: 8),
        _buildSettingsCard(
          children: [
            _buildSettingRow(
              icon: widget.isDarkMode ? AppIcons.moon : AppIcons.sun,
              title: 'Theme Mode',
              subtitle: widget.isDarkMode ? 'Dark mode enabled' : 'Light mode enabled',
              trailing: Switch.adaptive(
                value: widget.isDarkMode,
                activeTrackColor: AppColors.accentOrange,
                onChanged: (_) => widget.onThemeToggle(),
              ),
              onTap: widget.onThemeToggle,
            ),
            Divider(color: context.appLine, height: 1),
            _buildSettingRow(
              icon: AppIcons.widget,
              title: 'Device & Home Screen Widgets',
              subtitle: 'Preview, customize, and add widgets to your phone & PC',
              trailing: Icon(AppIcons.forward, size: 16, color: context.appMuted),
              onTap: () => widget.onNavigate(MyDayNavTab.widgets),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 4. Notifications & Audio Section
        _buildSectionHeader('Notifications & Audio', AppIcons.clock),
        const SizedBox(height: 8),
        _buildSettingsCard(
          children: [
            _buildSettingRow(
              icon: AppIcons.bell,
              title: 'System Notifications & Alarms',
              subtitle: _systemNotificationsGranted
                  ? 'Active • Full alerts and exact alarms enabled'
                  : 'Action needed • Tap to grant Android notification access',
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _systemNotificationsGranted
                      ? AppColors.successGreen.withValues(alpha: 0.15)
                      : AppColors.accentOrange,
                  foregroundColor: _systemNotificationsGranted
                      ? AppColors.successGreen
                      : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final granted = await LocalNotificationService.requestNotificationPermissions();
                  if (!mounted) return;
                  setState(() => _systemNotificationsGranted = granted);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(granted
                          ? 'Notifications & alarms are enabled'
                          : 'Please enable notifications in system settings'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  _systemNotificationsGranted ? 'Enabled' : 'Grant',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Divider(color: context.appLine, height: 1),
            _buildSettingRow(
              icon: AppIcons.clock,
              title: 'Timer Alerts',
              subtitle: 'Sound and system notification when countdown finishes',
              trailing: Switch.adaptive(
                value: _timerNotifications,
                activeTrackColor: AppColors.accentOrange,
                onChanged: (val) async {
                  setState(() => _timerNotifications = val);
                  LocalNotificationService.isNotificationEnabled = val;
                  if (val) {
                    final granted = await LocalNotificationService.requestNotificationPermissions();
                    setState(() => _systemNotificationsGranted = granted);
                  }
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('myday_timer_notifications', val);
                },
              ),
            ),
            Divider(color: context.appLine, height: 1),
            _buildSettingRow(
              icon: AppIcons.tasks,
              title: 'Task Due Reminders',
              subtitle: 'Daily briefing and upcoming task alarms',
              trailing: Switch.adaptive(
                value: _taskReminders,
                activeTrackColor: AppColors.accentOrange,
                onChanged: (val) async {
                  setState(() => _taskReminders = val);
                  if (val) {
                    final granted = await LocalNotificationService.requestNotificationPermissions();
                    setState(() => _systemNotificationsGranted = granted);
                  }
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('myday_task_reminders', val);
                },
              ),
            ),
            Divider(color: context.appLine, height: 1),
            _buildSettingRow(
              icon: AppIcons.check,
              title: 'In-App Sound Feedback',
              subtitle: 'Subtle audio cues on action completions',
              trailing: Switch.adaptive(
                value: _soundEffects,
                activeTrackColor: AppColors.accentOrange,
                onChanged: (val) async {
                  setState(() => _soundEffects = val);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('myday_sound_effects', val);
                },
              ),
            ),
            Divider(color: context.appLine, height: 1),
            _buildSettingRow(
              icon: AppIcons.sparkles,
              title: 'Test Notification & Sound',
              subtitle: 'Sends an immediate test banner and audible alert',
              trailing: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentOrange,
                  side: const BorderSide(color: AppColors.accentOrange, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  LocalNotificationService.showNotification(
                    id: 7777,
                    title: '🔔 MyDay Notification & Alarm Test',
                    body: 'Alerts, sound, and exact reminders are fully operational!',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent with audio!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Test', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 5. Security & Privacy Section
        _buildSectionHeader('Security & Privacy', AppIcons.fingerprint),
        const SizedBox(height: 8),
        _buildSettingsCard(
          children: [
            _buildSettingRow(
              icon: AppIcons.fingerprint,
              title: 'Biometric Lock',
              subtitle: _canUseBiometrics
                  ? 'Require biometric unlock upon app opening'
                  : 'Hardware not enrolled or unavailable',
              trailing: Switch.adaptive(
                value: _biometricEnabled,
                activeTrackColor: AppColors.accentOrange,
                onChanged: _canUseBiometrics ? _toggleBiometrics : null,
              ),
            ),
            Divider(color: context.appLine, height: 1),
            _buildSettingRow(
              icon: AppIcons.clock,
              title: 'Auto-Lock',
              subtitle: _autoLockDuration,
              trailing: Icon(AppIcons.forward, size: 16, color: context.appMuted),
              onTap: _selectAutoLock,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 6. Data & Storage Management
        _buildSectionHeader('Data & Offline Storage', AppIcons.download),
        const SizedBox(height: 8),
        _buildSettingsCard(
          children: [
            // Stats summary row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Tasks', '$_tasksCount'),
                  _buildStatItem('Notes', '$_notesCount'),
                  _buildStatItem('Moments', '$_momentsCount'),
                  _buildStatItem('Transactions', '$_txsCount'),
                ],
              ),
            ),
            Divider(color: context.appLine, height: 1),
            _buildSettingRow(
              icon: AppIcons.download,
              title: 'Export Backup (JSON)',
              subtitle: 'Save a portable backup copy of all data locally',
              onTap: _exportDataJson,
              trailing: Icon(AppIcons.forward, size: 16, color: context.appMuted),
            ),
            Divider(color: context.appLine, height: 1),
            _buildSettingRow(
              icon: AppIcons.refresh,
              title: 'Pull Old Pocketdesk Data',
              subtitle: 'Import saved tasks, notes, wallets & feed from old Pocketdesk',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Migrate',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(AppIcons.forward, size: 16, color: context.appMuted),
                ],
              ),
              onTap: _showPullPocketdeskData,
            ),
            Divider(color: context.appLine, height: 1),
            _buildSettingRow(
              icon: AppIcons.trash,
              title: 'Empty Trash',
              subtitle: 'Permanently remove deleted notes, tasks and files',
              onTap: _confirmEmptyTrash,
              trailing: Icon(AppIcons.forward, size: 16, color: context.appMuted),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 7. About MyDay Section
        _buildSectionHeader('About MyDay', AppIcons.info),
        const SizedBox(height: 8),
        _buildSettingsCard(
          children: [
            _buildSettingRow(
              icon: AppIcons.checkSquare,
              title: 'Version',
              subtitle: 'Pocketdesk 1.2.2 (Build 6) · Offline-First Engine',
              onTap: _openAboutApp,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Up to date',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(AppIcons.forward, size: 16, color: context.appMuted),
                ],
              ),
            ),
            if (_isDevModeUnlocked) ...[
              Divider(color: context.appLine, height: 1),
              _buildSettingRow(
                icon: AppIcons.sparkles,
                title: 'Developer Options',
                subtitle: 'Inspect raw database, storage architecture & decrypted tables',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'DEV ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentOrange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(AppIcons.forward, size: 16, color: context.appMuted),
                  ],
                ),
                onTap: _openDeveloperMode,
              ),
            ],
          ],
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.appMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appLine, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.appSurface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.accent, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.appText,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.appMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.appText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.appMuted,
          ),
        ),
      ],
    );
  }
}

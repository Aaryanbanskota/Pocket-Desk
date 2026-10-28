import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/myday_database.dart';
import 'core/design_system/app_colors.dart';
import 'core/design_system/widgets/app_scaffold.dart';
import 'core/notifications/local_notification_service.dart';
import 'core/security/app_lock_overlay.dart';
import 'core/security/biometric_service.dart';
import 'core/services/app_update_service.dart';
import 'core/sync/myday_sync_service.dart';
import 'core/widgets/widget_data_sync_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/budget/data/budget_repository.dart';
import 'features/budget/presentation/budget_screen.dart';
import 'features/budget/presentation/transaction_sheet.dart';
import 'features/calendar/presentation/calendar_screen.dart';
import 'features/chat/data/chat_repository.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/chat/presentation/widgets/phone_call_dialog.dart';
import 'features/chat/services/chat_socket_service.dart';
import 'features/chat/services/voice_call_audio_service.dart';
import 'features/clock/presentation/clock_screen.dart';
import 'features/feed/data/feed_repository.dart';
import 'features/feed/presentation/compose_sheet.dart';
import 'features/feed/presentation/feed_screen.dart';
import 'features/files/data/files_repository.dart';
import 'features/files/presentation/files_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/home/presentation/quick_actions_sheet.dart';
import 'features/notes/data/notes_repository.dart';
import 'features/notes/presentation/notepad_editor_screen.dart';
import 'features/notes/presentation/notes_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/tasks/data/tasks_repository.dart';
import 'features/tasks/presentation/task_bottom_sheet.dart';
import 'features/tasks/presentation/tasks_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/trash/data/trash_repository.dart';
import 'features/trash/presentation/trash_screen.dart';
import 'features/widgets/presentation/widgets_gallery_screen.dart';

class NoScrollbarBehavior extends MaterialScrollBehavior {
  const NoScrollbarBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

class MyDayApp extends StatefulWidget {
  final MyDayDatabase database;

  const MyDayApp({super.key, required this.database});

  @override
  State<MyDayApp> createState() => _MyDayAppState();
}

class _MyDayAppState extends State<MyDayApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  BuildContext get _navContext => _navigatorKey.currentContext ?? context;

  late final AuthRepository _authRepository;
  late final TasksRepository _tasksRepository;
  late final BudgetRepository _budgetRepository;
  late final NotesRepository _notesRepository;
  late final FeedRepository _feedRepository;
  late final FilesRepository _filesRepository;
  late final TrashRepository _trashRepository;
  late final ChatRepository _chatRepository;
  late final MyDaySyncService _syncService;

  UserSession? _currentSession;
  bool _isInitializing = true;
  bool _isDarkMode = true;
  late final ValueNotifier<ThemeMode> _themeModeNotifier;
  MyDayNavTab _currentTab = MyDayNavTab.home;
  int _dataVersion = 0;
  static const MethodChannel _deviceChannel = MethodChannel('pocketdesk/device');
  String? _pendingWidgetAction;
  StreamSubscription<CallSignal>? _globalCallSignalSub;

  // Security & Privacy State
  bool _isAppLocked = false;
  bool _isBackgroundObscured = false;
  bool _isLockWarningActive = false;
  DateTime? _lastPausedTime;
  DateTime _lastActivityTime = DateTime.now();
  Timer? _idleCheckTimer;

  void _onDataChanged({bool immediate = false}) {
    if (mounted) {
      setState(() {
        _dataVersion++;
      });
      if (_currentSession != null) {
        if (_currentSession!.isCloud) {
          if (immediate) {
            _syncService.syncPendingRecords(_currentSession!.accountId, force: true);
          } else {
            _syncService.scheduleDebouncedSync(_currentSession!.accountId);
          }
        }
        WidgetDataSyncService.syncWidgetsData(
          tasksRepository: _tasksRepository,
          accountId: _currentSession!.accountId,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeModeNotifier = ValueNotifier<ThemeMode>(_isDarkMode ? ThemeMode.dark : ThemeMode.light);
    _authRepository = AuthRepository(widget.database);
    _tasksRepository = TasksRepository(widget.database);
    _budgetRepository = BudgetRepository(widget.database);
    _notesRepository = NotesRepository(widget.database);
    _feedRepository = FeedRepository(widget.database);
    _filesRepository = FilesRepository(widget.database);
    _trashRepository = TrashRepository(widget.database);
    _chatRepository = ChatRepository(widget.database);
    _syncService = MyDaySyncService(widget.database);

    VoiceCallAudioService.instance.initialize();

    _lastActivityTime = DateTime.now();
    _idleCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkIdleTimeout();
    });

    _initApp();
    _setupDeviceActionChannel();
  }

  @override
  void dispose() {
    _idleCheckTimer?.cancel();
    _globalCallSignalSub?.cancel();
    _deviceChannel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    _syncService.dispose();
    _themeModeNotifier.dispose();
    _chatRepository.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // If biometric prompt is currently active on screen, don't treat it as app backgrounding
      if (BiometricService.isAuthenticating) {
        return;
      }
      _lastPausedTime = DateTime.now();
      if (_currentSession != null) {
        if (_currentSession!.isCloud) {
          _syncService.flushOnExit(_currentSession!.accountId);
        }
        // Obscure screen when app goes to background so Android App Switcher cannot snapshot private info
        if (mounted && !_isBackgroundObscured) {
          setState(() => _isBackgroundObscured = true);
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }

  Future<void> _handleAppResume() async {
    // If the biometric sensor dialog was open, or user just successfully authenticated via biometrics,
    // do not lock the app!
    if (BiometricService.isAuthenticating) {
      if (mounted && _isBackgroundObscured) {
        setState(() => _isBackgroundObscured = false);
      }
      return;
    }
    if (BiometricService.lastSuccessfulAuthTime != null &&
        DateTime.now().difference(BiometricService.lastSuccessfulAuthTime!) < const Duration(seconds: 4)) {
      if (mounted) {
        setState(() {
          _isAppLocked = false;
          _isBackgroundObscured = false;
        });
      }
      return;
    }

    if (_currentSession == null) {
      if (mounted && _isBackgroundObscured) {
        setState(() => _isBackgroundObscured = false);
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final autoLock = prefs.getString('myday_autolock') ?? 'After 2 minutes';
      final isBioEnabled = _currentSession!.isBioEnabled;

      if (isBioEnabled && autoLock != 'Never') {
        final elapsed = _lastPausedTime != null
            ? DateTime.now().difference(_lastPausedTime!)
            : Duration.zero;

        bool shouldLock = false;
        if (autoLock == 'After 5 minutes' && elapsed.inSeconds >= 300) {
          shouldLock = true;
        } else if (autoLock == 'After 15 minutes' && elapsed.inSeconds >= 900) {
          shouldLock = true;
        } else if (autoLock == 'Immediately' && elapsed.inSeconds >= 10) {
          shouldLock = true;
        } else if (elapsed.inSeconds >= 120) {
          // Default: 2 minutes of being away
          shouldLock = true;
        }

        if (shouldLock && mounted) {
          setState(() {
            _isAppLocked = true;
            _isBackgroundObscured = false;
            _isLockWarningActive = false;
          });
          return;
        }
      }
    } catch (_) {}

    _recordUserActivity();

    if (mounted && _isBackgroundObscured) {
      setState(() => _isBackgroundObscured = false);
    }
    if (_currentSession != null) {
      ChatSocketService().reconnectIfNeeded();
      if (_currentSession!.isCloud) {
        unawaited(() async {
          await _syncService.pullAllRemoteData(_currentSession!.accountId);
          if (mounted) {
            _onDataChanged();
          }
        }());
      }
    }
  }

  void _recordUserActivity() {
    _lastActivityTime = DateTime.now();
    if (_isLockWarningActive && mounted) {
      setState(() {
        _isLockWarningActive = false;
      });
    }
  }

  void _checkIdleTimeout() {
    if (!mounted || _currentSession == null || _isAppLocked) return;
    if (!_currentSession!.isBioEnabled) return;
    if (BiometricService.isAuthenticating) return;

    final idleSec = DateTime.now().difference(_lastActivityTime).inSeconds;
    if (idleSec >= 120) {
      setState(() {
        _isAppLocked = true;
        _isLockWarningActive = false;
        _isBackgroundObscured = false;
      });
    } else if (idleSec >= 105 && !_isLockWarningActive) {
      setState(() {
        _isLockWarningActive = true;
      });
    }
  }

  Widget _buildInactivityWarningCard(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9500),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.black87, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Inactivity Notice',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                  ),
                  Text(
                    'This app is going to be locked. Tap anywhere to stay active.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _recordUserActivity,
              style: TextButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Stay Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initApp() async {
    UserSession? session;
    try {
      // 1. Check saved theme
      try {
        final prefs = await SharedPreferences.getInstance()
            .timeout(const Duration(seconds: 2));
        final themeStr = prefs.getString('myday_theme') ?? 'dark';
        _isDarkMode = themeStr == 'dark';
        _themeModeNotifier.value =
            _isDarkMode ? ThemeMode.dark : ThemeMode.light;
      } catch (e) {
        // Fallback default theme
      }

      // 2. Initialize local notifications with timeout
      try {
        await LocalNotificationService.initialize()
            .timeout(const Duration(seconds: 2));
      } catch (_) {}

      // 3. Check active session
      try {
        session = await _authRepository
            .getActiveSession()
            .timeout(const Duration(seconds: 2));
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() {
          _currentSession = session;
          _isInitializing = false;
        });
        if (session != null) {
          _setupGlobalCallListener(session);
          WidgetDataSyncService.syncWidgetsData(
            tasksRepository: _tasksRepository,
            accountId: session.accountId,
          );
          if (session.isCloud) {
            final activeSession = session;
            unawaited(() async {
              await _syncService.pullAllRemoteData(activeSession.accountId);
              if (mounted) {
                _onDataChanged();
              }
            }());
          }
          // Check for app updates with minimal database calls (throttled)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              AppUpdateService.checkForUpdates(_navContext, manual: false);
            }
          });
        }
        if (session != null && _pendingWidgetAction != null) {
          final act = _pendingWidgetAction!;
          _pendingWidgetAction = null;
          _handleWidgetAction(act);
        }
      }
    }
  }

  void _setupDeviceActionChannel() {
    _deviceChannel.setMethodCallHandler((call) async {
      if (call.method == 'onAction') {
        final action = call.arguments as String?;
        if (action != null && action.isNotEmpty) {
          _handleWidgetAction(action);
        }
      }
    });

    try {
      _deviceChannel.invokeMethod<String>('getInitialAction').then((action) {
        if (action != null && action.isNotEmpty) {
          _handleWidgetAction(action);
        }
      }).catchError((_) {});
    } catch (_) {}
  }

  void _handleWidgetAction(String action) {
    if (!mounted) return;
    if (_currentSession == null) {
      _pendingWidgetAction = action;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentSession == null) return;
      switch (action) {
        case 'add_task':
          setState(() => _currentTab = MyDayNavTab.tasks);
          _openAddTaskSheet();
          break;
        case 'add_note':
          setState(() => _currentTab = MyDayNavTab.notes);
          _openNoteEditor();
          break;
        case 'calendar':
          setState(() => _currentTab = MyDayNavTab.calendar);
          break;
        case 'tasks':
          setState(() => _currentTab = MyDayNavTab.tasks);
          break;
        case 'open_widgets':
          setState(() => _currentTab = MyDayNavTab.widgets);
          break;
        default:
          break;
      }
    });
  }

  Future<void> _toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _themeModeNotifier.value = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('myday_theme', _isDarkMode ? 'dark' : 'light');
  }

  void _setupGlobalCallListener(UserSession session) {
    _globalCallSignalSub?.cancel();
    ChatSocketService().initialize(
      accountId: session.accountId,
      identityKey: session.phoneNumber,
      userName: session.name,
      chatRepository: _chatRepository,
    ).catchError((Object e) {
      debugPrint('Error initializing ChatSocketService: $e');
    });

    LocalNotificationService.onCallAction = (accept, payload) {
      if (accept) {
        IncomingCallDialog.answerActiveCall();
      } else {
        IncomingCallDialog.declineActiveCall();
      }
    };

    _globalCallSignalSub = ChatSocketService().onCallSignal.listen((signal) {
      if (!mounted || _currentSession == null) return;
      if (signal.type == CallSignalType.invite) {
        final my10 = ChatSocketService.normalize10(_currentSession!.phoneNumber);
        final myRaw = _currentSession!.phoneNumber.replaceAll(RegExp(r'\D'), '');
        final callee10 = ChatSocketService.normalize10(signal.calleeNumber);
        final calleeRaw = signal.calleeNumber.replaceAll(RegExp(r'\D'), '');
        final target10 = ChatSocketService.normalize10(signal.targetNumber ?? '');
        final targetRaw = (signal.targetNumber ?? '').replaceAll(RegExp(r'\D'), '');

        // Rule 1: Never ring our own physical device instance (eliminate self-echo on same phone)
        if (signal.senderDeviceId != null &&
            signal.senderDeviceId!.isNotEmpty &&
            signal.senderDeviceId == ChatSocketService.currentDeviceId) {
          return;
        }

        // Rule 2: Callee or target must match our number (supports global cross-region: India, USA, Britain, etc.)
        final isForMe = (callee10.isNotEmpty && callee10 == my10) ||
            (target10.isNotEmpty && target10 == my10) ||
            (my10.isNotEmpty && signal.calleeNumber.contains(my10)) ||
            (myRaw.isNotEmpty && calleeRaw.isNotEmpty && (myRaw == calleeRaw || myRaw.endsWith(calleeRaw) || calleeRaw.endsWith(myRaw))) ||
            (myRaw.isNotEmpty && targetRaw.isNotEmpty && (myRaw == targetRaw || myRaw.endsWith(targetRaw) || targetRaw.endsWith(myRaw)));

        if (isForMe) {
          if (mounted && _isBackgroundObscured) {
            setState(() => _isBackgroundObscured = false);
          }
          PhoneCallDialog.showIncomingCall(
            context: _navContext,
            invite: signal,
            accountId: _currentSession!.accountId,
            chatRepository: _chatRepository,
            myNumber: _currentSession!.phoneNumber,
            myName: _currentSession!.name,
          );
        }
      }
    });
  }

  void _onLoginSuccess(UserSession session) {
    _recordUserActivity();
    setState(() {
      _currentSession = session;
      _isAppLocked = false;
      _isLockWarningActive = false;
      _isBackgroundObscured = false;
      _currentTab = MyDayNavTab.home;
    });
    _setupGlobalCallListener(session);
    if (session.isCloud) {
      unawaited(() async {
        await _syncService.pullAllRemoteData(session.accountId);
        await _syncService.syncPendingRecords(session.accountId);
        if (mounted) {
          _onDataChanged();
        }
      }());
    }
    // Check for app updates upon login (throttled)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppUpdateService.checkForUpdates(_navContext, manual: false);
      }
    });
    if (_pendingWidgetAction != null) {
      final act = _pendingWidgetAction!;
      _pendingWidgetAction = null;
      _handleWidgetAction(act);
    }
  }

  Future<void> _logout() async {
    _globalCallSignalSub?.cancel();
    await _authRepository.clearSession();
    setState(() {
      _currentSession = null;
      _isAppLocked = false;
      _isBackgroundObscured = false;
      _currentTab = MyDayNavTab.home;
    });
  }

  void _handleQuickAction() {
    switch (_currentTab) {
      case MyDayNavTab.tasks:
      case MyDayNavTab.calendar:
        _openAddTaskSheet();
        break;
      case MyDayNavTab.notes:
        _openNoteEditor();
        break;
      case MyDayNavTab.budget:
        _openAddTransactionSheet();
        break;
      case MyDayNavTab.feed:
        _openComposeSheet();
        break;
      case MyDayNavTab.files:
        _filesRepository.pickAndSaveFile(_currentSession!.accountId).then((_) {
          if (mounted) setState(() {});
        });
        break;
      default:
        QuickActionsSheet.show(
          _navContext,
          onAddTask: _openAddTaskSheet,
          onAddNote: _openNoteEditor,
          onAddTransaction: _openAddTransactionSheet,
          onComposePost: _openComposeSheet,
        );
        break;
    }
  }

  void _openAddTaskSheet([MyDayTask? task, bool isEvent = false]) {
    TaskBottomSheet.showForAccount(
      context: _navContext,
      tasksRepository: _tasksRepository,
      accountId: _currentSession!.accountId,
      taskToEdit: task,
      isEvent: isEvent || (task?.tags.contains('event') ?? false),
      onSaved: _onDataChanged,
    );
  }

  void _openNoteEditor([MyDayNote? note]) {
    NotepadEditorScreen.open(
      _navContext,
      notesRepository: _notesRepository,
      accountId: _currentSession!.accountId,
      note: note,
    ).then((_) {
      _onDataChanged();
    });
  }

  void _openAddTransactionSheet([MyDayTransaction? tx]) {
    TransactionSheet.showForAccount(
      context: _navContext,
      budgetRepository: _budgetRepository,
      accountId: _currentSession!.accountId,
      transaction: tx,
      onSaved: _onDataChanged,
    );
  }

  void _openComposeSheet() {
    ComposeSheet.showForAccount(
      context: _navContext,
      feedRepository: _feedRepository,
      accountId: _currentSession!.accountId,
      authorName: _currentSession!.name,
      onPostCreated: () => _onDataChanged(immediate: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.darkSurface,
      ),
    );

    final lightTheme = ThemeData.light().copyWith(
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        surface: AppColors.lightSurface,
      ),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;

        return MaterialApp(
          title: 'MyDay',
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          themeAnimationDuration: const Duration(milliseconds: 350),
          themeAnimationCurve: Curves.easeInOutCubic,
          scrollBehavior: const NoScrollbarBehavior(),
          home: _isInitializing
              ? const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              : _currentSession == null
                  ? AuthScreen(
                      authRepository: _authRepository,
                      onAuthenticated: _onLoginSuccess,
                    )
                  : _isAppLocked
                      ? AppLockOverlay(
                          session: _currentSession!,
                          authRepository: _authRepository,
                          isDarkMode: isDark,
                          onUnlocked: () {
                            _recordUserActivity();
                            setState(() {
                              _isAppLocked = false;
                              _isLockWarningActive = false;
                            });
                          },
                          onLogout: _logout,
                        )
                      : Stack(
                          children: [
                            Listener(
                              behavior: HitTestBehavior.translucent,
                              onPointerDown: (_) => _recordUserActivity(),
                              onPointerMove: (_) => _recordUserActivity(),
                              child: AppScaffold(
                                key: const ValueKey('myday_app_scaffold_root'),
                                currentTab: _currentTab,
                                onTabSelected: (tab) => setState(() => _currentTab = tab),
                                onQuickAction: _handleQuickAction,
                                userName: _currentSession!.name,
                                accountType: _currentSession!.isCloud
                                    ? (_currentSession!.email ?? 'Cloud account')
                                    : 'Local account',
                                isDarkMode: isDark,
                                onToggleTheme: _toggleTheme,
                                onLogout: _logout,
                                child: _buildCurrentScreen(),
                              ),
                            ),
                            if (_isLockWarningActive && !_isAppLocked)
                              Positioned(
                                top: MediaQuery.of(context).padding.top + 10,
                                left: 0,
                                right: 0,
                                child: _buildInactivityWarningCard(isDark),
                              ),
                            if (_isBackgroundObscured)
                              Positioned.fill(
                                child: BackgroundPrivacyShield(isDarkMode: isDark),
                              ),
                          ],
                        ),
        );
      },
    );
  }

  Future<void> _pullAndSyncData() async {
    if (_currentSession == null || !_currentSession!.isCloud) return;
    try {
      await _syncService.pullAllRemoteData(_currentSession!.accountId);
      await _syncService.syncPendingRecords(_currentSession!.accountId);
    } catch (_) {}
  }

  Widget _buildCurrentScreen() {
    final session = _currentSession!;
    final tabKey = ValueKey('tab_${_currentTab.name}_${session.accountId}_$_dataVersion');

    switch (_currentTab) {
      case MyDayNavTab.home:
        return HomePage(
          key: tabKey,
          session: session,
          authRepository: _authRepository,
          tasksRepository: _tasksRepository,
          notesRepository: _notesRepository,
          budgetRepository: _budgetRepository,
          onNavigate: (tab) => setState(() => _currentTab = tab),
          onEditTask: (task) => _openAddTaskSheet(task),
          onSessionUpdated: (updated) => setState(() => _currentSession = updated),
          onRefresh: _pullAndSyncData,
        );

      case MyDayNavTab.tasks:
        return TasksPage(
          key: tabKey,
          tasksRepository: _tasksRepository,
          accountId: session.accountId,
          onEditTask: (task) => _openAddTaskSheet(task),
          onAddTask: _openAddTaskSheet,
          onAddEvent: () => _openAddTaskSheet(null, true),
          onRefresh: _pullAndSyncData,
        );

      case MyDayNavTab.calendar:
        return CalendarPage(
          key: tabKey,
          tasksRepository: _tasksRepository,
          notesRepository: _notesRepository,
          feedRepository: _feedRepository,
          budgetRepository: _budgetRepository,
          accountId: session.accountId,
          onEditTask: (task) => _openAddTaskSheet(task),
          onAddTask: _openAddTaskSheet,
          onOpenNote: (note) => _openNoteEditor(note),
          onRefresh: _pullAndSyncData,
        );

      case MyDayNavTab.notes:
        return NotesPage(
          key: tabKey,
          notesRepository: _notesRepository,
          accountId: session.accountId,
          onOpenNote: (note) => _openNoteEditor(note),
          onRefresh: _pullAndSyncData,
        );

      case MyDayNavTab.budget:
        return BudgetPage(
          key: tabKey,
          budgetRepository: _budgetRepository,
          accountId: session.accountId,
          onRefresh: _pullAndSyncData,
        );

      case MyDayNavTab.feed:
        return FeedPage(
          key: tabKey,
          feedRepository: _feedRepository,
          session: session,
          onCompose: _openComposeSheet,
          onDataChanged: () {
            _pullAndSyncData();
            _onDataChanged(immediate: true);
          },
        );

      case MyDayNavTab.clock:
        return ClockScreen(
          tasksRepository: _tasksRepository,
          accountId: session.accountId,
        );

      case MyDayNavTab.call:
        return CallScreen(
          key: tabKey,
          chatRepository: _chatRepository,
          session: session,
        );

      case MyDayNavTab.files:
        return FilesScreen(
          key: tabKey,
          filesRepository: _filesRepository,
          accountId: session.accountId,
          session: session,
        );

      case MyDayNavTab.trash:
        return TrashScreen(
          trashRepository: _trashRepository,
          accountId: session.accountId,
        );

      case MyDayNavTab.profile:
        return ProfileScreen(
          session: session,
          authRepository: _authRepository,
          tasksRepository: _tasksRepository,
          notesRepository: _notesRepository,
          feedRepository: _feedRepository,
          isDarkMode: _isDarkMode,
          onThemeToggle: _toggleTheme,
          onSessionUpdated: (updated) => setState(() => _currentSession = updated),
          onLogout: _logout,
          onOpenSettings: () => setState(() => _currentTab = MyDayNavTab.settings),
        );

      case MyDayNavTab.widgets:
        return WidgetsGalleryScreen(
          session: session,
          tasksRepository: _tasksRepository,
          initialDarkMode: _isDarkMode,
          onNavigate: (tab) => setState(() => _currentTab = tab),
          onBack: () => setState(() => _currentTab = MyDayNavTab.settings),
        );

      case MyDayNavTab.settings:
        return SettingsScreen(
          session: session,
          authRepository: _authRepository,
          tasksRepository: _tasksRepository,
          notesRepository: _notesRepository,
          budgetRepository: _budgetRepository,
          feedRepository: _feedRepository,
          trashRepository: _trashRepository,
          isDarkMode: _isDarkMode,
          onThemeToggle: _toggleTheme,
          onNavigate: (tab) => setState(() => _currentTab = tab),
          onLogout: _logout,
        );
    }
  }
}

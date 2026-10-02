import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_spacing.dart';

class AlarmItem {
  AlarmItem({
    required this.id,
    required this.time,
    required this.label,
    required this.days,
    this.snoozeMinutes = 10,
    this.isEnabled = true,
  });

  final int id;
  TimeOfDay time;
  String label;
  String days;
  int snoozeMinutes;
  bool isEnabled;

  factory AlarmItem.fromJson(Map<dynamic, dynamic> json) => AlarmItem(
        id: json['id'] as int,
        time:
            TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int),
        label: json['label'] as String,
        days: json['days'] as String,
        snoozeMinutes: json['snoozeMinutes'] as int? ?? 10,
        isEnabled: json['isEnabled'] as bool,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'hour': time.hour,
        'minute': time.minute,
        'label': label,
        'days': days,
        'snoozeMinutes': snoozeMinutes,
        'isEnabled': isEnabled,
      };
}

class ClockPage extends ConsumerStatefulWidget {
  const ClockPage({super.key});

  @override
  ConsumerState<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends ConsumerState<ClockPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  bool _showAnalogClock = false;

  // Stopwatch state
  Timer? _stopwatchTimer;
  int _stopwatchMilliseconds = 0;
  bool _isStopwatchRunning = false;

  // Timer state
  Timer? _countDownTimer;
  int _timerInitialSeconds = 60;
  int _timerSeconds = 60;
  bool _isTimerRunning = false;
  DateTime? _timerDeadline;

  // Alarm list state
  final List<AlarmItem> _alarms = [];
  bool _alarmsLoading = true;
  String? _alarmStorageError;

  // Pomodoro state
  Timer? _pomodoroTimer;
  int _pomodoroSeconds = 25 * 60;
  int _pomodoroWorkDuration = 25 * 60;
  int _pomodoroBreakDuration = 5 * 60;
  int _pomodoroLongBreakDuration = 15 * 60;
  int _pomodoroTargetSessions = 4;
  bool _isPomodoroRunning = false;
  bool _isPomodoroBreak = false;
  bool _isPomodoroLongBreak = false;
  int _pomodoroCompletedSessions = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    unawaited(_loadAlarms());
    unawaited(_loadPomodoroSettings());
  }

  void _togglePomodoro() {
    if (_isPomodoroRunning) {
      _pomodoroTimer?.cancel();
      setState(() => _isPomodoroRunning = false);
    } else {
      setState(() => _isPomodoroRunning = true);
      _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_pomodoroSeconds > 0) {
          setState(() => _pomodoroSeconds--);
        } else {
          _finishPomodoroPhase();
        }
      });
    }
  }

  void _finishPomodoroPhase() {
    _pomodoroTimer?.cancel();
    if (_isPomodoroBreak || _isPomodoroLongBreak) {
      _isPomodoroBreak = false;
      _isPomodoroLongBreak = false;
      _pomodoroSeconds = _pomodoroWorkDuration;
      _showClockMessage('Break over! Time to focus on your next session.');
    } else {
      _pomodoroCompletedSessions++;
      final isLongBreak =
          (_pomodoroCompletedSessions % _pomodoroTargetSessions) == 0;
      _isPomodoroBreak = !isLongBreak;
      _isPomodoroLongBreak = isLongBreak;
      _pomodoroSeconds =
          isLongBreak ? _pomodoroLongBreakDuration : _pomodoroBreakDuration;
      final breakMsg = isLongBreak
          ? 'Great work! You completed $_pomodoroTargetSessions sessions. Enjoy a long break!'
          : 'Focus session complete! Take a break.';
      _showClockMessage(breakMsg);
    }
    setState(() => _isPomodoroRunning = false);
  }

  void _switchPomodoroPhase({required bool isBreak, bool isLongBreak = false}) {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = false;
      _isPomodoroBreak = isBreak;
      _isPomodoroLongBreak = isLongBreak;
      if (isLongBreak) {
        _pomodoroSeconds = _pomodoroLongBreakDuration;
      } else if (isBreak) {
        _pomodoroSeconds = _pomodoroBreakDuration;
      } else {
        _pomodoroSeconds = _pomodoroWorkDuration;
      }
    });
  }

  void _resetPomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = false;
      _isPomodoroBreak = false;
      _isPomodoroLongBreak = false;
      _pomodoroSeconds = _pomodoroWorkDuration;
    });
  }

  Future<File> _pomodoroSettingsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/pomodoro_settings.json');
  }

  Future<void> _loadPomodoroSettings() async {
    try {
      final file = await _pomodoroSettingsFile();
      if (await file.exists()) {
        final data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _pomodoroWorkDuration =
                data['workDuration'] as int? ?? (25 * 60);
            _pomodoroBreakDuration =
                data['shortBreakDuration'] as int? ?? (5 * 60);
            _pomodoroLongBreakDuration =
                data['longBreakDuration'] as int? ?? (15 * 60);
            _pomodoroTargetSessions =
                data['targetSessions'] as int? ?? 4;
            if (!_isPomodoroRunning) {
              if (_isPomodoroLongBreak) {
                _pomodoroSeconds = _pomodoroLongBreakDuration;
              } else if (_isPomodoroBreak) {
                _pomodoroSeconds = _pomodoroBreakDuration;
              } else {
                _pomodoroSeconds = _pomodoroWorkDuration;
              }
            }
          });
        }
      }
    } catch (e) {
      AppLogger.w('Failed to load Pomodoro settings: $e');
    }
  }

  Future<void> _savePomodoroSettings() async {
    try {
      final file = await _pomodoroSettingsFile();
      final data = {
        'workDuration': _pomodoroWorkDuration,
        'shortBreakDuration': _pomodoroBreakDuration,
        'longBreakDuration': _pomodoroLongBreakDuration,
        'targetSessions': _pomodoroTargetSessions,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      AppLogger.w('Failed to save Pomodoro settings: $e');
    }
  }

  Future<void> _showPomodoroSettingsDialog() async {
    int workMins = _pomodoroWorkDuration ~/ 60;
    int shortBreakMins = _pomodoroBreakDuration ~/ 60;
    int longBreakMins = _pomodoroLongBreakDuration ~/ 60;
    int targetSessions = _pomodoroTargetSessions;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.tune_rounded),
              SizedBox(width: 8),
              Text('Pomodoro Settings'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Focus Duration'),
                  subtitle: Text('$workMins minutes'),
                  trailing: DropdownButton<int>(
                    value: workMins,
                    items: [5, 10, 15, 20, 25, 30, 45, 60]
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text('$m min'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => workMins = val);
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Short Break'),
                  subtitle: Text('$shortBreakMins minutes'),
                  trailing: DropdownButton<int>(
                    value: shortBreakMins,
                    items: [2, 3, 5, 10, 15]
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text('$m min'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => shortBreakMins = val);
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Long Break'),
                  subtitle: Text('$longBreakMins minutes'),
                  trailing: DropdownButton<int>(
                    value: longBreakMins,
                    items: [10, 15, 20, 25, 30]
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text('$m min'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => longBreakMins = val);
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Target Sessions'),
                  subtitle: Text('$targetSessions focus sessions before long break'),
                  trailing: DropdownButton<int>(
                    value: targetSessions,
                    items: [2, 3, 4, 5, 6]
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text('$s sessions'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => targetSessions = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _pomodoroWorkDuration = workMins * 60;
                  _pomodoroBreakDuration = shortBreakMins * 60;
                  _pomodoroLongBreakDuration = longBreakMins * 60;
                  _pomodoroTargetSessions = targetSessions;
                  if (!_isPomodoroRunning) {
                    if (_isPomodoroLongBreak) {
                      _pomodoroSeconds = _pomodoroLongBreakDuration;
                    } else if (_isPomodoroBreak) {
                      _pomodoroSeconds = _pomodoroBreakDuration;
                    } else {
                      _pomodoroSeconds = _pomodoroWorkDuration;
                    }
                  }
                });
                _savePomodoroSettings();
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clockTimer?.cancel();
    _stopwatchTimer?.cancel();
    _countDownTimer?.cancel();
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  void _toggleStopwatch() {
    if (_isStopwatchRunning) {
      _stopwatchTimer?.cancel();
      setState(() => _isStopwatchRunning = false);
    } else {
      setState(() => _isStopwatchRunning = true);
      _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) setState(() => _stopwatchMilliseconds += 100);
      });
    }
  }

  void _resetStopwatch() {
    _stopwatchTimer?.cancel();
    setState(() {
      _isStopwatchRunning = false;
      _stopwatchMilliseconds = 0;
    });
  }

  Future<void> _toggleTimer() async {
    if (_isTimerRunning) {
      _countDownTimer?.cancel();
      final remaining = _remainingTimerSeconds();
      if (remaining > 0) {
        if (!await NotificationService.instance.cancelTimer(999001)) {
          _startTimerTicker();
          _showClockMessage('Could not cancel the scheduled timer alert.');
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _timerSeconds = remaining;
        _timerDeadline = null;
        _isTimerRunning = false;
      });
      if (remaining == 0) _finishTimer();
    } else {
      if (_timerSeconds <= 0) return;
      late final bool scheduled;
      try {
        scheduled = await NotificationService.instance.scheduleTimer(
          id: 999001,
          duration: Duration(seconds: _timerSeconds),
        );
      } catch (e) {
        if (mounted) {
          _showClockMessage('Could not schedule timer notification: $e');
        }
        return;
      }
      if (!mounted) return;
      if (!scheduled) {
        _showClockMessage(
          Platform.isLinux
              ? 'Enable desktop notifications to receive timer alerts.'
              : 'Allow notifications and Alarms & reminders access in Android Settings to use the timer.',
        );
        return;
      }
      _timerDeadline = DateTime.now().add(Duration(seconds: _timerSeconds));
      setState(() => _isTimerRunning = true);
      _startTimerTicker();
    }
  }

  void _startTimerTicker() {
    _countDownTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      final remaining = _remainingTimerSeconds();
      if (remaining > 0) {
        if (remaining != _timerSeconds) {
          setState(() => _timerSeconds = remaining);
        }
      } else {
        _finishTimer();
      }
    });
  }

  int _remainingTimerSeconds() {
    final milliseconds =
        _timerDeadline?.difference(DateTime.now()).inMilliseconds ??
            _timerSeconds * 1000;
    return ((milliseconds + 999) ~/ 1000).clamp(0, _timerInitialSeconds);
  }

  void _finishTimer() {
    _countDownTimer?.cancel();
    _timerDeadline = null;
    if (mounted) {
      setState(() {
        _timerSeconds = 0;
        _isTimerRunning = false;
      });
      final colors = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Timer finished'),
          backgroundColor: colors.tertiary,
        ),
      );
    }
    if (!Platform.isAndroid) {
      unawaited(
        NotificationService.instance.showNotification(
          id: 999001,
          title: 'Timer Finished',
          body: 'Your countdown timer has ended.',
        ),
      );
    }
  }

  void _resetTimer() {
    _countDownTimer?.cancel();
    _timerDeadline = null;
    unawaited(
      NotificationService.instance.cancelTimer(999001).then<void>((_) {}),
    );
    setState(() {
      _isTimerRunning = false;
      _timerSeconds = _timerInitialSeconds;
    });
  }

  void _setTimerDuration(int seconds) {
    _countDownTimer?.cancel();
    _timerDeadline = null;
    unawaited(
      NotificationService.instance.cancelTimer(999001).then<void>((_) {}),
    );
    setState(() {
      _isTimerRunning = false;
      _timerInitialSeconds = seconds;
      _timerSeconds = seconds;
    });
  }

  Future<void> _showCustomTimerDialog() async {
    final minutesController =
        TextEditingController(text: (_timerInitialSeconds ~/ 60).toString());
    final secondsController =
        TextEditingController(text: (_timerInitialSeconds % 60).toString());

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Custom Timer'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Minutes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: secondsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Seconds'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final m = int.tryParse(minutesController.text.trim()) ?? 0;
              final s = int.tryParse(secondsController.text.trim()) ?? 0;
              if (m < 0 || s < 0 || s > 59) {
                _showClockMessage('Enter minutes and 0–59 seconds.');
                return;
              }
              final total = (m * 60) + s;
              if (total > 0) {
                _setTimerDuration(total);
              } else {
                _showClockMessage('Set a timer longer than zero.');
                return;
              }
              Navigator.pop(ctx);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Future<void> _addOrEditAlarm({AlarmItem? existingAlarm}) async {
    TimeOfDay selectedTime = existingAlarm?.time ?? TimeOfDay.now();
    final labelController =
        TextEditingController(text: existingAlarm?.label ?? 'Alarm');
    String selectedDays = existingAlarm?.days ?? 'Daily';
    var snoozeMinutes = existingAlarm?.snoozeMinutes ?? 10;
    AlarmItem? alarmToSchedule;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colors = Theme.of(context).colorScheme;
          return AlertDialog(
            title: Text(existingAlarm == null ? 'New alarm' : 'Edit alarm'),
            actionsOverflowDirection: VerticalDirection.down,
            content: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'ALARM TIME',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setDialogState(() => selectedTime = picked);
                              }
                            },
                            icon: const Icon(Icons.schedule_rounded),
                            label: Text(
                              selectedTime.format(context),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.md,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: labelController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Alarm name',
                        hintText: 'Wake up',
                        prefixIcon: Icon(Icons.edit_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Repeat',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: ['Once', 'Daily', 'Weekdays', 'Weekends']
                          .map(
                            (days) => ChoiceChip(
                              label: Text(days),
                              selected: selectedDays == days,
                              onSelected: (_) =>
                                  setDialogState(() => selectedDays = days),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<int>(
                      initialValue: snoozeMinutes,
                      decoration: const InputDecoration(
                        labelText: 'Snooze duration',
                        prefixIcon: Icon(Icons.snooze_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: const [5, 10, 15, 20, 30]
                          .map(
                            (minutes) => DropdownMenuItem(
                              value: minutes,
                              child: Text('$minutes minutes'),
                            ),
                          )
                          .toList(),
                      onChanged: (minutes) {
                        if (minutes != null) {
                          setDialogState(() => snoozeMinutes = minutes);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (existingAlarm != null)
                TextButton.icon(
                  onPressed: () async {
                    final cancelled = await NotificationService.instance
                        .cancelAlarm(existingAlarm.id);
                    if (!cancelled) {
                      _showClockMessage('Could not cancel this alarm.');
                      return;
                    }
                    if (!mounted) return;
                    setState(() => _alarms.remove(existingAlarm));
                    await _saveAlarms();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final label = labelController.text.trim().isEmpty
                      ? 'Alarm'
                      : labelController.text.trim();
                  if (existingAlarm != null) {
                    setState(() {
                      existingAlarm.time = selectedTime;
                      existingAlarm.label = label;
                      existingAlarm.days = selectedDays;
                      existingAlarm.snoozeMinutes = snoozeMinutes;
                    });
                    alarmToSchedule = existingAlarm;
                  } else {
                    final alarm = AlarmItem(
                      id: DateTime.now().millisecondsSinceEpoch % 100000,
                      time: selectedTime,
                      label: label,
                      days: selectedDays,
                      snoozeMinutes: snoozeMinutes,
                      isEnabled: false,
                    );
                    setState(() => _alarms.add(alarm));
                    alarmToSchedule = alarm;
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Save alarm'),
              ),
            ],
          );
        },
      ),
    );
    labelController.dispose();
    final alarm = alarmToSchedule;
    if (alarm != null && (existingAlarm == null || alarm.isEnabled)) {
      await _scheduleAlarm(alarm);
    } else if (alarm != null) {
      await _saveAlarms();
    }
  }

  Future<void> _scheduleAlarm(AlarmItem alarm) async {
    late final bool scheduled;
    try {
      scheduled = await NotificationService.instance.scheduleAlarm(
        id: alarm.id,
        title: alarm.label,
        days: alarm.days,
        hour: alarm.time.hour,
        minute: alarm.time.minute,
        snoozeMinutes: alarm.snoozeMinutes,
      );
    } catch (e) {
      if (mounted) {
        setState(() => alarm.isEnabled = false);
        await _saveAlarms();
        _showClockMessage('Could not schedule alarm: $e');
      }
      return;
    }
    if (!mounted) return;
    if (scheduled) {
      setState(() => alarm.isEnabled = true);
      await _saveAlarms();
      if (!mounted) return;
      _showClockMessage('Alarm set for ${alarm.time.format(context)}');
    } else {
      setState(() => alarm.isEnabled = false);
      await _saveAlarms();
      _showClockMessage(
        Platform.isLinux
            ? 'Enable desktop notifications to receive alarm alerts.'
            : 'Allow notifications and Alarms & reminders access in Android Settings to use alarms.',
      );
    }
  }

  Future<void> _toggleAlarmState(AlarmItem alarm, bool enabled) async {
    if (enabled) {
      await _scheduleAlarm(alarm);
    } else {
      if (!await NotificationService.instance.cancelAlarm(alarm.id)) {
        _showClockMessage('Could not cancel this alarm.');
        return;
      }
      if (mounted) setState(() => alarm.isEnabled = false);
      await _saveAlarms();
    }
  }

  Future<File> _alarmFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/alarms.json');
  }

  Future<void> _loadAlarms() async {
    try {
      final file = await _alarmFile();
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
        final saved =
            decoded.map((value) => AlarmItem.fromJson(value as Map)).toList();
        if (mounted) {
          setState(() {
            _alarms
              ..clear()
              ..addAll(saved);
          });
        }
        if (Platform.isLinux) {
          for (final alarm in saved.where((alarm) => alarm.isEnabled)) {
            final scheduled = await NotificationService.instance.scheduleAlarm(
              id: alarm.id,
              title: alarm.label,
              days: alarm.days,
              hour: alarm.time.hour,
              minute: alarm.time.minute,
              snoozeMinutes: alarm.snoozeMinutes,
            );
            if (!scheduled) {
              AppLogger.w(
                'Could not restore Linux alarm ${alarm.id}.',
                tag: 'ClockPage',
              );
            }
          }
        }
      }
    } catch (error, stackTrace) {
      AppLogger.e('Failed to load saved alarms',
          tag: 'ClockPage', error: error, st: stackTrace);
      if (mounted) {
        setState(() => _alarmStorageError = 'Could not load saved alarms.');
      }
    } finally {
      if (mounted) setState(() => _alarmsLoading = false);
    }
  }

  Future<void> _saveAlarms() async {
    try {
      final file = await _alarmFile();
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        jsonEncode(_alarms.map((alarm) => alarm.toJson()).toList()),
        flush: true,
      );
      await temporary.rename(file.path);
      if (_alarmStorageError != null && mounted) {
        setState(() => _alarmStorageError = null);
      }
    } catch (error, stackTrace) {
      AppLogger.e('Failed to save alarms',
          tag: 'ClockPage', error: error, st: stackTrace);
      if (mounted) {
        setState(() => _alarmStorageError = 'Could not save alarms.');
        _showClockMessage('Could not save alarm settings.');
      }
    }
  }

  void _showClockMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clock & Timers'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.access_time_rounded), text: 'Clock'),
            Tab(icon: Icon(Icons.alarm_rounded), text: 'Alarm'),
            Tab(icon: Icon(Icons.timer_rounded), text: 'Timer'),
            Tab(icon: Icon(Icons.timer_outlined), text: 'Stopwatch'),
            Tab(icon: Icon(Icons.psychology_rounded), text: 'Pomodoro'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Clock Tab
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(AppSpacing.xl),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.x2l,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'LOCAL TIME',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (_showAnalogClock)
                            Semantics(
                              label:
                                  'Analog clock showing ${TimeOfDay.fromDateTime(_now).format(context)}',
                              child: CustomPaint(
                                size: const Size(260, 260),
                                painter: _AnalogClockPainter(
                                  time: _now,
                                  color: colorScheme.primary,
                                  faceColor:
                                      colorScheme.surfaceContainerHighest,
                                  tickColor: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          else
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                TimeOfDay.fromDateTime(_now).format(context),
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            MaterialLocalizations.of(context)
                                .formatMediumDate(_now),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: true,
                                icon: Icon(Icons.watch_later_outlined),
                                label: Text('Analog'),
                              ),
                              ButtonSegment(
                                value: false,
                                icon: Icon(Icons.schedule_rounded),
                                label: Text('Digital'),
                              ),
                            ],
                            selected: {_showAnalogClock},
                            onSelectionChanged: (selection) {
                              setState(
                                  () => _showAnalogClock = selection.first);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Alarm Tab
          Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () => _addOrEditAlarm(),
              child: const Icon(Icons.add),
            ),
            body: _alarmsLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      if (_alarmStorageError != null)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            _alarmStorageError!,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.error),
                          ),
                        ),
                      if (Platform.isLinux)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            0,
                          ),
                          child: Text(
                            'Keep PocketDesk running for alarms to fire on Linux.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      Expanded(
                        child: _alarms.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.alarm_add_rounded,
                                          size: 56,
                                          color: colorScheme.onSurfaceVariant),
                                      const SizedBox(height: AppSpacing.md),
                                      Text('No alarms yet',
                                          style: theme.textTheme.titleLarge),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        Platform.isLinux
                                            ? 'Add an alarm. PocketDesk must remain running for it to fire.'
                                            : 'Add an alarm to schedule a local notification.',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                itemCount: _alarms.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final alarm = _alarms[index];
                                  return Card(
                                    margin: EdgeInsets.zero,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: alarm.isEnabled
                                            ? colorScheme.primaryContainer
                                            : colorScheme
                                                .surfaceContainerHighest,
                                        foregroundColor: alarm.isEnabled
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurfaceVariant,
                                        child: const Icon(Icons.alarm_rounded),
                                      ),
                                      title: Text(
                                        alarm.time.format(context),
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${alarm.label}  ·  ${alarm.days}  ·  Snooze ${alarm.snoozeMinutes} min',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Edit alarm',
                                            icon:
                                                const Icon(Icons.edit_outlined),
                                            onPressed: () => _addOrEditAlarm(
                                                existingAlarm: alarm),
                                          ),
                                          Switch(
                                            value: alarm.isEnabled,
                                            onChanged: (val) =>
                                                _toggleAlarmState(alarm, val),
                                            activeThumbColor:
                                                colorScheme.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),

          // 3. Timer Tab
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'COUNTDOWN TIMER',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: 252,
                    height: 252,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: _timerInitialSeconds == 0
                                ? 0
                                : (_timerSeconds / _timerInitialSeconds)
                                    .clamp(0.0, 1.0),
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isTimerRunning
                                  ? Icons.hourglass_top_rounded
                                  : Icons.hourglass_empty_rounded,
                              color: colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isTimerRunning ? 'RUNNING' : 'READY',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                          label: const Text('1 min'),
                          onPressed: () => _setTimerDuration(60)),
                      ActionChip(
                          label: const Text('5 min'),
                          onPressed: () => _setTimerDuration(300)),
                      ActionChip(
                          label: const Text('10 min'),
                          onPressed: () => _setTimerDuration(600)),
                      ActionChip(
                          label: const Text('15 min'),
                          onPressed: () => _setTimerDuration(900)),
                      ActionChip(
                          label: const Text('Custom'),
                          onPressed: _showCustomTimerDialog),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _toggleTimer,
                        icon: Icon(
                            _isTimerRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(_isTimerRunning ? 'Pause' : 'Start'),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. Stopwatch Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(_stopwatchMilliseconds ~/ 1000).toString().padLeft(2, '0')}.${((_stopwatchMilliseconds % 1000) ~/ 100)}',
                  style: theme.textTheme.displayLarge
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 64),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _toggleStopwatch,
                      icon: Icon(
                          _isStopwatchRunning ? Icons.pause : Icons.play_arrow),
                      label: Text(_isStopwatchRunning ? 'Pause' : 'Start'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _resetStopwatch,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 5. Pomodoro Tab
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: (_isPomodoroLongBreak
                                  ? Colors.teal
                                  : (_isPomodoroBreak
                                      ? Colors.green
                                      : colorScheme.primary))
                              .withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isPomodoroLongBreak
                              ? '☕ Long Break (${_pomodoroLongBreakDuration ~/ 60}m)'
                              : (_isPomodoroBreak
                                  ? '🌿 Short Break (${_pomodoroBreakDuration ~/ 60}m)'
                                  : '🔥 Focus Session (${_pomodoroWorkDuration ~/ 60}m)'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: _isPomodoroLongBreak
                                ? Colors.teal
                                : (_isPomodoroBreak
                                    ? Colors.green
                                    : colorScheme.primary),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.tune_rounded),
                        tooltip: 'Pomodoro Settings',
                        onPressed: _showPomodoroSettingsDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ChoiceChip(
                        label: Text('Focus (${_pomodoroWorkDuration ~/ 60}m)'),
                        selected: !_isPomodoroBreak && !_isPomodoroLongBreak,
                        onSelected: (_) => _switchPomodoroPhase(isBreak: false),
                      ),
                      ChoiceChip(
                        label: Text('Short Break (${_pomodoroBreakDuration ~/ 60}m)'),
                        selected: _isPomodoroBreak,
                        onSelected: (_) => _switchPomodoroPhase(isBreak: true),
                      ),
                      ChoiceChip(
                        label: Text('Long Break (${_pomodoroLongBreakDuration ~/ 60}m)'),
                        selected: _isPomodoroLongBreak,
                        onSelected: (_) =>
                            _switchPomodoroPhase(isBreak: true, isLongBreak: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: (_pomodoroSeconds /
                                  (_isPomodoroLongBreak
                                      ? _pomodoroLongBreakDuration
                                      : (_isPomodoroBreak
                                          ? _pomodoroBreakDuration
                                          : _pomodoroWorkDuration)))
                              .clamp(0.0, 1.0),
                          strokeWidth: 10,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isPomodoroLongBreak
                                ? Colors.teal
                                : (_isPomodoroBreak
                                    ? Colors.green
                                    : colorScheme.primary),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(_pomodoroSeconds ~/ 60).toString().padLeft(2, '0')}:${(_pomodoroSeconds % 60).toString().padLeft(2, '0')}',
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completed: $_pomodoroCompletedSessions / $_pomodoroTargetSessions sessions',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _togglePomodoro,
                        icon: Icon(
                            _isPomodoroRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(_isPomodoroRunning
                            ? 'Pause'
                            : (_isPomodoroBreak || _isPomodoroLongBreak
                                ? 'Start Break'
                                : 'Start Focus')),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: _resetPomodoro,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  const _AnalogClockPainter({
    required this.time,
    required this.color,
    required this.faceColor,
    required this.tickColor,
  });

  final DateTime time;
  final Color color;
  final Color faceColor;
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = faceColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = tickColor.withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    for (var mark = 0; mark < 60; mark++) {
      final angle = mark * math.pi / 30 - math.pi / 2;
      final major = mark % 5 == 0;
      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 8),
        center.dy + math.sin(angle) * (radius - 8),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - (major ? 25 : 15)),
        center.dy + math.sin(angle) * (radius - (major ? 25 : 15)),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = tickColor
          ..strokeWidth = major ? 3 : 1.2
          ..strokeCap = StrokeCap.round,
      );
    }

    void drawHand(double angle, double length, double width, Color handColor) {
      canvas.drawLine(
        center,
        Offset(
          center.dx + math.cos(angle) * length,
          center.dy + math.sin(angle) * length,
        ),
        Paint()
          ..color = handColor
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    final minute = time.minute + time.second / 60;
    final hour = time.hour % 12 + minute / 60;
    drawHand(hour * math.pi / 6 - math.pi / 2, radius * 0.48, 6, color);
    drawHand(minute * math.pi / 30 - math.pi / 2, radius * 0.68, 4, color);
    drawHand(
      time.second * math.pi / 30 - math.pi / 2,
      radius * 0.76,
      1.5,
      tickColor,
    );
    canvas.drawCircle(center, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_AnalogClockPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.color != color ||
      oldDelegate.faceColor != faceColor ||
      oldDelegate.tickColor != tickColor;
}

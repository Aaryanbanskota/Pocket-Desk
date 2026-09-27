import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
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
    this.isEnabled = true,
  });

  final int id;
  TimeOfDay time;
  String label;
  String days;
  bool isEnabled;

  factory AlarmItem.fromJson(Map<dynamic, dynamic> json) => AlarmItem(
        id: json['id'] as int,
        time:
            TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int),
        label: json['label'] as String,
        days: json['days'] as String,
        isEnabled: json['isEnabled'] as bool,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'hour': time.hour,
        'minute': time.minute,
        'label': label,
        'days': days,
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    unawaited(_loadAlarms());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clockTimer?.cancel();
    _stopwatchTimer?.cancel();
    _countDownTimer?.cancel();
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
        await NotificationService.instance.cancelTimer(999001);
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
          'Allow notifications in Android Settings to use the timer alarm.',
        );
        return;
      }
      _timerDeadline = DateTime.now().add(Duration(seconds: _timerSeconds));
      setState(() => _isTimerRunning = true);
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
    unawaited(NotificationService.instance.cancelTimer(999001));
    setState(() {
      _isTimerRunning = false;
      _timerSeconds = _timerInitialSeconds;
    });
  }

  void _setTimerDuration(int seconds) {
    _countDownTimer?.cancel();
    _timerDeadline = null;
    unawaited(NotificationService.instance.cancelTimer(999001));
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
    AlarmItem? alarmToSchedule;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingAlarm == null ? 'Add Alarm' : 'Edit Alarm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Time'),
                trailing: Text(
                  selectedTime.format(context),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                      context: context, initialTime: selectedTime);
                  if (picked != null) {
                    setDialogState(() => selectedTime = picked);
                  }
                },
              ),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedDays,
                decoration: const InputDecoration(labelText: 'Repeat'),
                items: const [
                  DropdownMenuItem(value: 'Once', child: Text('Once')),
                  DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'Weekdays', child: Text('Weekdays')),
                  DropdownMenuItem(value: 'Weekends', child: Text('Weekends')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedDays = val);
                },
              ),
            ],
          ),
          actions: [
            if (existingAlarm != null)
              IconButton(
                icon: Icon(Icons.delete,
                    color: Theme.of(context).colorScheme.error),
                onPressed: () async {
                  await NotificationService.instance
                      .cancelAlarm(existingAlarm.id);
                  if (!mounted) return;
                  setState(() => _alarms.remove(existingAlarm));
                  await _saveAlarms();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final label = labelController.text.trim().isEmpty
                    ? 'Alarm'
                    : labelController.text.trim();
                if (existingAlarm != null) {
                  setState(() {
                    existingAlarm.time = selectedTime;
                    existingAlarm.label = label;
                    existingAlarm.days = selectedDays;
                  });
                  alarmToSchedule = existingAlarm;
                } else {
                  final alarm = AlarmItem(
                    id: DateTime.now().millisecondsSinceEpoch % 100000,
                    time: selectedTime,
                    label: label,
                    days: selectedDays,
                    isEnabled: false,
                  );
                  setState(() {
                    _alarms.add(alarm);
                  });
                  alarmToSchedule = alarm;
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
        'Allow notifications in Android Settings to use alarms.',
      );
    }
  }

  Future<void> _toggleAlarmState(AlarmItem alarm, bool enabled) async {
    if (enabled) {
      await _scheduleAlarm(alarm);
    } else {
      await NotificationService.instance.cancelAlarm(alarm.id);
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Clock Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}',
                  style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${_now.day}/${_now.month}/${_now.year}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
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
                                        'Add an alarm to schedule a local notification.',
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
                                          '${alarm.label}  ·  ${alarm.days}'),
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
        ],
      ),
    );
  }
}

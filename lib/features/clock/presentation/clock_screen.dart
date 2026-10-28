import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/circular_icon_button.dart';
import '../../../core/design_system/widgets/pill_chip.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../../core/services/notification_service.dart';
import '../../tasks/data/tasks_repository.dart';
import '../../widgets/presentation/components/clock_pie_agenda_widget.dart';

class AlarmItem {
  final String id;
  final int hour;
  final int minute;
  final String label;
  final bool isEnabled;
  final List<int> repeatDays; // 1 = Mon ... 7 = Sun

  const AlarmItem({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    this.isEnabled = true,
    this.repeatDays = const [],
  });

  String get timeFormatted {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  String get repeatFormatted {
    if (repeatDays.isEmpty) return 'Once / Today';
    if (repeatDays.length == 7) return 'Everyday';
    if (repeatDays.length == 5 &&
        repeatDays.contains(1) &&
        repeatDays.contains(2) &&
        repeatDays.contains(3) &&
        repeatDays.contains(4) &&
        repeatDays.contains(5)) {
      return 'Weekdays (Mon - Fri)';
    }
    const dayNames = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    final names = repeatDays.map((d) => dayNames[d] ?? '').where((s) => s.isNotEmpty).toList();
    return names.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'isEnabled': isEnabled,
        'repeatDays': repeatDays,
      };

  factory AlarmItem.fromJson(Map<String, dynamic> json) => AlarmItem(
        id: (json['id'] as String?) ?? DateTime.now().millisecondsSinceEpoch.toString(),
        hour: (json['hour'] as int?) ?? 7,
        minute: (json['minute'] as int?) ?? 0,
        label: (json['label'] as String?) ?? 'Alarm',
        isEnabled: (json['isEnabled'] as bool?) ?? true,
        repeatDays: (json['repeatDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      );

  AlarmItem copyWith({
    int? hour,
    int? minute,
    String? label,
    bool? isEnabled,
    List<int>? repeatDays,
  }) =>
      AlarmItem(
        id: id,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        label: label ?? this.label,
        isEnabled: isEnabled ?? this.isEnabled,
        repeatDays: repeatDays ?? this.repeatDays,
      );
}

class ClockScreen extends StatefulWidget {
  final TasksRepository? tasksRepository;
  final String? accountId;

  const ClockScreen({
    super.key,
    this.tasksRepository,
    this.accountId,
  });

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

enum ClockSubTab { clock, dayDial, alarm, stopwatch, timer }

class _ClockScreenState extends State<ClockScreen> {
  ClockSubTab _activeTab = ClockSubTab.clock;

  // Clock state
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  String _lastTriggeredKey = '';

  // Alarm state
  List<AlarmItem> _alarms = [];

  // Day Dial Task state
  List<ClockPieTaskItem> _dialTasks = [];
  List<MyDayTask> _rawTasks = [];
  bool _isLoadingDial = false;

  // Stopwatch state
  Timer? _stopwatchTimer;
  final Stopwatch _stopwatch = Stopwatch();
  int _stopwatchElapsedMs = 0;

  // Countdown Timer state
  Timer? _countdownTimer;
  int _timerDurationMinutes = 5;
  int _timerRemainingSeconds = 5 * 60;
  bool _isTimerRunning = false;
  final TextEditingController _timerMinutesController =
      TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    _loadAlarms();
    _loadDialTasks();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
      _checkAlarms();
    });
  }

  @override
  void didUpdateWidget(covariant ClockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasksRepository != widget.tasksRepository ||
        oldWidget.accountId != widget.accountId) {
      _loadDialTasks();
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _stopwatchTimer?.cancel();
    _countdownTimer?.cancel();
    _timerMinutesController.dispose();
    super.dispose();
  }

  // --- Alarms Management & Storage ---
  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('myday_alarms_list');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        _alarms = decoded.map((e) => AlarmItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {});
    }
    for (final alarm in _alarms) {
      if (alarm.isEnabled) {
        unawaited(_syncAlarmToSystem(alarm));
      }
    }
  }

  Future<void> _syncAlarmToSystem(AlarmItem alarm) async {
    final numericId = (int.tryParse(alarm.id) ?? alarm.id.hashCode).abs() % 100000;
    if (!alarm.isEnabled) {
      await NotificationService.instance.cancelAlarm(numericId);
      return;
    }
    String daysParam;
    if (alarm.repeatDays.isEmpty) {
      daysParam = 'Once';
    } else if (alarm.repeatDays.length == 7) {
      daysParam = 'Daily';
    } else if (alarm.repeatDays.length == 5 &&
        alarm.repeatDays.every((d) => d >= 1 && d <= 5)) {
      daysParam = 'Weekdays';
    } else if (alarm.repeatDays.length == 2 &&
        alarm.repeatDays.contains(6) &&
        alarm.repeatDays.contains(7)) {
      daysParam = 'Weekends';
    } else {
      daysParam = 'Days:${alarm.repeatDays.join(',')}';
    }

    await NotificationService.instance.scheduleAlarm(
      id: numericId,
      title: alarm.label,
      days: daysParam,
      hour: alarm.hour,
      minute: alarm.minute,
    );
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_alarms.map((a) => a.toJson()).toList());
    await prefs.setString('myday_alarms_list', jsonStr);
  }

  void _checkAlarms() {
    final currentKey = '${_now.hour}:${_now.minute}';
    if (_lastTriggeredKey != currentKey) {
      for (final alarm in _alarms) {
        if (alarm.isEnabled && alarm.hour == _now.hour && alarm.minute == _now.minute) {
          if (alarm.repeatDays.isEmpty || alarm.repeatDays.contains(_now.weekday)) {
            _lastTriggeredKey = currentKey;
            _triggerAlarm(alarm);
            break;
          }
        }
      }
    }
  }

  void _triggerAlarm(AlarmItem alarm) {
    LocalNotificationService.showNotification(
      id: alarm.id.hashCode,
      title: '⏰ Alarm Reminder: ${alarm.label}',
      body: 'Time is ${alarm.timeFormatted}!',
    );

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.accentOrange,
                shape: BoxShape.circle,
              ),
              child: const Icon(AppIcons.clock, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '⏰ ${alarm.label}',
                style: TextStyle(color: ctx.appText, fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'It is ${alarm.timeFormatted}.\nReminder: ${alarm.label}',
          style: TextStyle(color: ctx.appMuted, fontSize: 14),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: ctx.appMuted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alarm snoozed for 5 minutes')),
              );
            },
            child: const Text('Snooze (5m)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _toggleAlarmEnabled(int index, bool val) {
    setState(() {
      _alarms[index] = _alarms[index].copyWith(isEnabled: val);
    });
    _saveAlarms();
    _syncAlarmToSystem(_alarms[index]);
  }

  void _deleteAlarm(int index) {
    final deleted = _alarms.removeAt(index);
    final numericId = (int.tryParse(deleted.id) ?? deleted.id.hashCode).abs() % 100000;
    NotificationService.instance.cancelAlarm(numericId);
    setState(() {});
    _saveAlarms();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alarm deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddEditAlarmSheet({AlarmItem? alarmToEdit, int? editIndex}) {
    TimeOfDay selectedTime = alarmToEdit != null
        ? TimeOfDay(hour: alarmToEdit.hour, minute: alarmToEdit.minute)
        : TimeOfDay(hour: _now.hour, minute: (_now.minute + 5) % 60);

    final labelController = TextEditingController(text: alarmToEdit?.label ?? 'Morning Wakeup');
    final selectedDays = List<int>.from(alarmToEdit?.repeatDays ?? []);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final cardBg = ctx.appSurface;
            final textPrimary = ctx.appText;
            final textMuted = ctx.appMuted;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          alarmToEdit != null ? 'Edit Alarm' : 'Set New Alarm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: textMuted,
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Time Selection Button
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setSheetState(() => selectedTime = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: ctx.appSurface2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              selectedTime.format(context),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accentOrange,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to change time',
                              style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Label / Reminder field
                    Text(
                      'Alarm / Reminder Label',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: labelController,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. Daily Standup, Medicine, Gym',
                        hintStyle: TextStyle(color: textMuted, fontSize: 13),
                        filled: true,
                        fillColor: ctx.appSurface2,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Repeat Days
                    Text(
                      'Repeat Schedule',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final entry in [
                          {'day': 1, 'name': 'M'},
                          {'day': 2, 'name': 'T'},
                          {'day': 3, 'name': 'W'},
                          {'day': 4, 'name': 'T'},
                          {'day': 5, 'name': 'F'},
                          {'day': 6, 'name': 'S'},
                          {'day': 7, 'name': 'S'},
                        ]) ...[
                          GestureDetector(
                            onTap: () {
                              final d = entry['day'] as int;
                              setSheetState(() {
                                if (selectedDays.contains(d)) {
                                  selectedDays.remove(d);
                                } else {
                                  selectedDays.add(d);
                                  selectedDays.sort();
                                }
                              });
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectedDays.contains(entry['day'])
                                    ? AppColors.accentOrange
                                    : ctx.appSurface2,
                              ),
                              child: Center(
                                child: Text(
                                  entry['name'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: selectedDays.contains(entry['day'])
                                        ? Colors.white
                                        : textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final label = labelController.text.trim();
                          final newAlarm = AlarmItem(
                            id: alarmToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            hour: selectedTime.hour,
                            minute: selectedTime.minute,
                            label: label.isNotEmpty ? label : 'Alarm',
                            isEnabled: true,
                            repeatDays: selectedDays,
                          );

                          setState(() {
                            if (editIndex != null && editIndex < _alarms.length) {
                              _alarms[editIndex] = newAlarm;
                            } else {
                              _alarms.add(newAlarm);
                            }
                          });
                          _saveAlarms();
                          _syncAlarmToSystem(newAlarm);
                          Navigator.of(sheetCtx).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Alarm set for ${newAlarm.timeFormatted}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text(
                          'Save Alarm',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Stopwatch handlers ---
  void _toggleStopwatch() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _stopwatchTimer?.cancel();
      } else {
        _stopwatch.start();
        _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
          if (mounted) {
            setState(() {
              _stopwatchElapsedMs = _stopwatch.elapsedMilliseconds;
            });
          }
        });
      }
    });
  }

  void _resetStopwatch() {
    setState(() {
      _stopwatch.reset();
      _stopwatchElapsedMs = 0;
      if (!_stopwatch.isRunning) {
        _stopwatchTimer?.cancel();
      }
    });
  }

  // --- Countdown Timer handlers ---
  void _toggleCountdown() {
    if (_isTimerRunning) {
      _pauseCountdown();
    } else {
      _startCountdown();
    }
  }

  void _startCountdown() {
    if (_timerRemainingSeconds <= 0) {
      final inputMin = int.tryParse(_timerMinutesController.text) ?? 5;
      _timerDurationMinutes = inputMin.clamp(1, 600);
      _timerRemainingSeconds = _timerDurationMinutes * 60;
    }

    setState(() {
      _isTimerRunning = true;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timerRemainingSeconds > 1) {
          _timerRemainingSeconds--;
        } else {
          _timerRemainingSeconds = 0;
          _isTimerRunning = false;
          _countdownTimer?.cancel();
          _onTimerComplete();
        }
      });
    });
  }

  void _pauseCountdown() {
    setState(() {
      _isTimerRunning = false;
    });
    _countdownTimer?.cancel();
  }

  void _resetCountdown() {
    final inputMin = int.tryParse(_timerMinutesController.text) ?? 5;
    setState(() {
      _isTimerRunning = false;
      _timerDurationMinutes = inputMin.clamp(1, 600);
      _timerRemainingSeconds = _timerDurationMinutes * 60;
    });
    _countdownTimer?.cancel();
  }

  void _onTimerComplete() {
    LocalNotificationService.showNotification(
      id: 9999,
      title: 'Time’s Up! — MyDay',
      body: 'Your $_timerDurationMinutes minute timer has finished!',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Your $_timerDurationMinutes minute timer has finished!'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(AppIcons.clock, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Time’s Up!', style: TextStyle(color: ctx.appText, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Your $_timerDurationMinutes minute countdown has completed.',
          style: TextStyle(color: ctx.appMuted, fontSize: 14),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: ctx.appMuted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _timerRemainingSeconds = 5 * 60;
                _isTimerRunning = true;
              });
              _countdownTimer?.cancel();
              _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (!mounted) return;
                setState(() {
                  if (_timerRemainingSeconds > 1) {
                    _timerRemainingSeconds--;
                  } else {
                    _timerRemainingSeconds = 0;
                    _isTimerRunning = false;
                    _countdownTimer?.cancel();
                    _onTimerComplete();
                  }
                });
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Timer snoozed for 5 minutes'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Snooze (5m)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatStopwatch(int ms) {
    final hundreds = (ms ~/ 10) % 100;
    final totalSeconds = ms ~/ 1000;
    final seconds = totalSeconds % 60;
    final minutes = (totalSeconds ~/ 60) % 60;
    final hours = totalSeconds ~/ 3600;

    final hStr = hundreds.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$mStr:$sStr.$hStr';
    }
    return '$mStr:$sStr.$hStr';
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    return '$mStr:$sStr';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Subtabs: Clock, Alarm, Stopwatch, Timer
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              children: [
                PillChip(
                  label: 'Clock',
                  isSelected: _activeTab == ClockSubTab.clock,
                  onTap: () => setState(() => _activeTab = ClockSubTab.clock),
                ),
                const SizedBox(width: 8),
                PillChip(
                  label: 'Day Dial Pie',
                  isSelected: _activeTab == ClockSubTab.dayDial,
                  onTap: () => setState(() => _activeTab = ClockSubTab.dayDial),
                ),
                const SizedBox(width: 8),
                PillChip(
                  label: 'Alarm & Reminders',
                  isSelected: _activeTab == ClockSubTab.alarm,
                  onTap: () => setState(() => _activeTab = ClockSubTab.alarm),
                ),
                const SizedBox(width: 8),
                PillChip(
                  label: 'Stopwatch',
                  isSelected: _activeTab == ClockSubTab.stopwatch,
                  onTap: () => setState(() => _activeTab = ClockSubTab.stopwatch),
                ),
                const SizedBox(width: 8),
                PillChip(
                  label: 'Timer',
                  isSelected: _activeTab == ClockSubTab.timer,
                  onTap: () => setState(() => _activeTab = ClockSubTab.timer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Content based on tab
          if (_activeTab == ClockSubTab.clock) _buildClockView(textMuted),
          if (_activeTab == ClockSubTab.dayDial) _buildDayDialView(isDark, textMuted),
          if (_activeTab == ClockSubTab.alarm) _buildAlarmView(isDark, textMuted),
          if (_activeTab == ClockSubTab.stopwatch) _buildStopwatchView(isDark),
          if (_activeTab == ClockSubTab.timer) _buildTimerView(isDark, textMuted),
        ],
      ),
    );
  }

  Widget _buildClockView(Color textMuted) {
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute:$second';

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final dateStr = '${days[_now.weekday - 1]}, ${months[_now.month - 1]} ${_now.day}, ${_now.year}';
    final tz = _now.timeZoneName;

    // Find next upcoming enabled alarm
    final enabledAlarms = _alarms.where((a) => a.isEnabled).toList();
    AlarmItem? nextAlarm;
    if (enabledAlarms.isNotEmpty) {
      // Find the one closest to now
      final nowMinutes = _now.hour * 60 + _now.minute;
      enabledAlarms.sort((a, b) {
        final aDiff = (a.hour * 60 + a.minute) - nowMinutes;
        final bDiff = (b.hour * 60 + b.minute) - nowMinutes;
        final aPositive = aDiff >= 0 ? aDiff : aDiff + 24 * 60;
        final bPositive = bDiff >= 0 ? bDiff : bDiff + 24 * 60;
        return aPositive.compareTo(bPositive);
      });
      nextAlarm = enabledAlarms.first;
    }

    return Column(
      children: [
        Text(
          timeStr,
          style: AppTypography.clockBig.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$dateStr · $tz',
          style: TextStyle(
            color: textMuted,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 40),

        // Upcoming Alarm Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appLine, width: 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.clock, color: AppColors.accentOrange, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextAlarm != null ? 'Next Alarm: ${nextAlarm.timeFormatted}' : 'No Active Alarms',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nextAlarm != null
                          ? '${nextAlarm.label} · ${nextAlarm.repeatFormatted}'
                          : 'Set alarms and reminders to keep your day on track',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  if (nextAlarm != null) {
                    setState(() => _activeTab = ClockSubTab.alarm);
                  } else {
                    _showAddEditAlarmSheet();
                  }
                },
                child: Text(
                  nextAlarm != null ? 'View' : '+ Set',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Quick Day Dial Switch Card
        InkWell(
          onTap: () => setState(() => _activeTab = ClockSubTab.dayDial),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.3), width: 1.0),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.clock, color: AppColors.accentOrange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day Dial Pie Schedule',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: context.appText,
                        ),
                      ),
                      Text(
                        'View your 12-hour tasks & events in an interactive pie clock dial',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.accentOrange),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Day Dial Pie Chart Agenda View (Redesigned Clock Base with Real Tasks) ---
  Widget _buildDayDialView(bool isDark, Color textMuted) {
    ClockPieTaskItem? activeTask;
    for (final t in _dialTasks) {
      if (t.isCurrent(_now)) {
        activeTask = t;
        break;
      }
    }

    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    final period = _now.hour >= 12 ? 'PM' : 'AM';
    final liveDigitalTime = '$h:$m:$s $period';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Action Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appLine),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.clock, color: AppColors.accentOrange, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day Dial Clock Base',
                      style: AppTypography.h3.copyWith(color: context.appText, fontSize: 14.5),
                    ),
                    Text(
                      '12-hour analog clock with live scheduled sectors',
                      style: TextStyle(color: textMuted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add_task_rounded, size: 14),
                label: const Text(
                  'Schedule',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                onPressed: _showScheduleTaskSheet,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Central Prominent Circular Clock Base
        Center(
          child: Container(
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF16161A) : const Color(0xFFF9F8F6),
              border: Border.all(
                color: isDark ? const Color(0xFF2E2E36) : const Color(0xFFE4E2DC),
                width: 3.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Live Analog Clock with Task Pie Sectors
                CustomPaint(
                  size: const Size(270, 270),
                  painter: ClockPiePainter(
                    time: _now,
                    tasks: _dialTasks,
                    isDarkMode: isDark,
                    textPrimary: context.appText,
                    textMuted: textMuted,
                    accentColor: AppColors.accentOrange,
                    showAllNumbers: true,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 3. Digital Time Readout & Current Active Task Status
        Center(
          child: Column(
            children: [
              Text(
                liveDigitalTime,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentOrange,
                  fontFamily: 'monospace',
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: activeTask != null
                      ? activeTask.color.withValues(alpha: 0.15)
                      : context.appSurface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: activeTask != null ? activeTask.color : context.appLine,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeTask?.color ?? textMuted,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      activeTask != null
                          ? 'Now: ${activeTask.title} (${activeTask.timeFormatted})'
                          : 'No active task now · Clock Base ready',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: activeTask != null ? context.appText : textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 4. Today's Dial Schedule List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  "Today's Schedule",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_dialTasks.length}',
                    style: const TextStyle(
                      color: AppColors.accentOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoadingDial)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(color: AppColors.accentOrange, strokeWidth: 2),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // 5. Today's Tasks on Clock Base
        if (_dialTasks.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appLine),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.watch_later_outlined, size: 36, color: textMuted),
                  const SizedBox(height: 10),
                  Text(
                    'No tasks scheduled for today',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.appText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "+ Schedule" to place your tasks directly onto the Clock Base dial.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _showScheduleTaskSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Schedule Task Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dialTasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _dialTasks[index];
              final isCurrent = item.isCurrent(_now);
              final rawTask = index < _rawTasks.length ? _rawTasks[index] : null;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? item.color.withValues(alpha: 0.15)
                      : context.appSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent ? item.color : context.appLine,
                    width: isCurrent ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Task Color Dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.color,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13.5,
                                    color: context.appText,
                                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              if (isCurrent) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    'ACTIVE NOW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                item.timeFormatted,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent ? item.color : textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: context.appSurface2,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${item.durationMinutes}m',
                                  style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (item.category.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: item.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: item.color,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Complete Checkbox Button
                    if (rawTask != null)
                      IconButton(
                        icon: Icon(
                          item.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: item.isCompleted ? AppColors.successGreen : textMuted,
                          size: 22,
                        ),
                        onPressed: () async {
                          if (widget.tasksRepository != null) {
                            await widget.tasksRepository!.toggleTaskDone(rawTask);
                            await _loadDialTasks();
                            if (!mounted) return;
                            UndoToast.show(
                              this.context,
                              message: !rawTask.isDone ? 'Task marked complete' : 'Task marked incomplete',
                            );
                          }
                        },
                      ),
                  ],
                ),
              );
            },
          ),

        const SizedBox(height: 40),
      ],
    );
  }

  // --- Real Tasks Loader for Day Dial ---
  Future<void> _loadDialTasks() async {
    if (widget.tasksRepository == null || widget.accountId == null) return;
    setState(() => _isLoadingDial = true);
    try {
      final tasks = await widget.tasksRepository!.getTasks(widget.accountId!, filter: 'all');
      final active = tasks.where((t) => !t.isDeleted).toList();

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final todayTasks = active.where((t) => t.dueDate.contains(todayStr) || t.dueDate.toLowerCase().contains('today') || !t.isDone).toList();

      const colors = [
        Color(0xFF6366F1), // Indigo
        Color(0xFF06B6D4), // Cyan
        Color(0xFF10B981), // Emerald
        AppColors.accentOrange, // Coral/Orange
        Color(0xFFF59E0B), // Amber
        Color(0xFF8B5CF6), // Violet
        Color(0xFFEC4899), // Pink
      ];

      final List<ClockPieTaskItem> pieItems = [];

      for (int i = 0; i < todayTasks.length; i++) {
        final t = todayTasks[i];
        final color = colors[i % colors.length];

        // Default spread times across working hours (e.g. 9am, 10am, 11am, 1pm, 2pm, 4pm...)
        final defaultHours = [9, 10, 11, 13, 14, 15, 16, 17, 18, 19, 20];
        final startH = defaultHours[i % defaultHours.length];
        TimeOfDay start = TimeOfDay(hour: startH, minute: 0);
        int durationMins = t.minDuration > 0 ? t.minDuration : 45;

        // Extract explicit time pattern if specified in dueDate or note
        final timeMatch = RegExp(r'(\d{1,2}):(\d{2})(?:\s*(AM|PM))?', caseSensitive: false)
            .firstMatch('${t.dueDate} ${t.note}');
        if (timeMatch != null) {
          int h = int.parse(timeMatch.group(1)!);
          final m = int.parse(timeMatch.group(2)!);
          final period = timeMatch.group(3)?.toUpperCase();
          if (period == 'PM' && h < 12) h += 12;
          if (period == 'AM' && h == 12) h = 0;
          start = TimeOfDay(hour: h, minute: m);
        }

        final endMinutesTotal = start.hour * 60 + start.minute + durationMins;
        final end = TimeOfDay(hour: (endMinutesTotal ~/ 60) % 24, minute: endMinutesTotal % 60);

        pieItems.add(
          ClockPieTaskItem(
            id: t.id,
            title: t.title,
            startTime: start,
            endTime: end,
            color: color,
            isCompleted: t.isDone,
            category: t.tags.isNotEmpty ? t.tags.first : (t.kind == 'timed' ? 'Timed' : 'Task'),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _dialTasks = pieItems;
          _rawTasks = todayTasks;
          _isLoadingDial = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDial = false);
    }
  }

  // --- Schedule Task Modal for Day Dial ---
  Future<void> _showScheduleTaskSheet() async {
    final titleCtrl = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay(hour: (_now.hour + 1) % 24, minute: 0);
    int selectedDuration = 45;
    String selectedCategory = 'Focus';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final surface = context.appSurface;
          final line = context.appLine;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: line),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Schedule on Day Dial',
                        style: AppTypography.h3.copyWith(color: context.appText, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(AppIcons.x, size: 20),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title Input
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    style: TextStyle(color: context.appText, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Task or Event Title (e.g. Code Review, Workout)',
                      hintStyle: TextStyle(color: context.appMuted, fontSize: 13),
                      filled: true,
                      fillColor: context.appSurface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: line),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Start Time Picker
                  Row(
                    children: [
                      Text(
                        'Start Time:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.appText),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: sheetContext,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setModalState(() => selectedTime = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.accentOrange),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_filled_rounded, size: 16, color: AppColors.accentOrange),
                              const SizedBox(width: 6),
                              Text(
                                '${selectedTime.hour % 12 == 0 ? 12 : selectedTime.hour % 12}:${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.hour >= 12 ? 'PM' : 'AM'}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentOrange),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Duration selector
                  Text(
                    'Duration:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.appText),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [15, 30, 45, 60, 90, 120].map((mins) {
                      final isSel = selectedDuration == mins;
                      return ChoiceChip(
                        label: Text('${mins}m'),
                        selected: isSel,
                        selectedColor: AppColors.accentOrange,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : context.appText,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setModalState(() => selectedDuration = mins),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Category selector
                  Text(
                    'Category:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.appText),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Focus', 'Work', 'Meeting', 'Fitness', 'Personal'].map((cat) {
                      final isSel = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: AppColors.accentOrange,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : context.appText,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setModalState(() => selectedCategory = cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;

                      final period = selectedTime.hour >= 12 ? 'PM' : 'AM';
                      final h = selectedTime.hour % 12 == 0 ? 12 : selectedTime.hour % 12;
                      final m = selectedTime.minute.toString().padLeft(2, '0');
                      final timeStr = '$h:$m $period';

                      if (widget.tasksRepository != null && widget.accountId != null) {
                        await widget.tasksRepository!.addTask(
                          accountId: widget.accountId!,
                          title: title,
                          dueDate: 'Today · $timeStr',
                          minDuration: selectedDuration,
                          tags: [selectedCategory.toLowerCase()],
                          kind: 'timed',
                        );
                        await _loadDialTasks();
                      }

                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    child: const Text(
                      'Place on Clock Base Dial',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Alarm Tab View ---
  Widget _buildAlarmView(bool isDark, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alarms & Reminders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                  ),
                ),
                Text(
                  '${_alarms.where((a) => a.isEnabled).length} active',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(AppIcons.plus, size: 16),
              label: const Text(
                'Add Alarm',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              onPressed: () => _showAddEditAlarmSheet(),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (_alarms.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.appLine, width: 1.0),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    AppIcons.clock,
                    size: 40,
                    color: textMuted.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No alarms set yet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.appText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "+ Add Alarm" to schedule wakeups and reminders',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _alarms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, index) {
              final alarm = _alarms[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: alarm.isEnabled
                        ? AppColors.accentOrange.withValues(alpha: 0.4)
                        : context.appLine,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showAddEditAlarmSheet(
                          alarmToEdit: alarm,
                          editIndex: index,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  alarm.timeFormatted,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: alarm.isEnabled ? context.appText : textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: alarm.isEnabled
                                          ? AppColors.accentOrange.withValues(alpha: 0.15)
                                          : context.appSurface2,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      alarm.repeatFormatted,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: alarm.isEnabled ? AppColors.accentOrange : textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alarm.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: alarm.isEnabled ? context.appText : textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Switch
                    Switch.adaptive(
                      value: alarm.isEnabled,
                      activeTrackColor: AppColors.accentOrange,
                      onChanged: (val) => _toggleAlarmEnabled(index, val),
                    ),

                    // Compact Delete button
                    IconButton(
                      icon: const Icon(AppIcons.trash, size: 16),
                      color: AppColors.errorRed.withValues(alpha: 0.85),
                      tooltip: 'Delete Alarm',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () => _deleteAlarm(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStopwatchView(bool isDark) {
    final display = _formatStopwatch(_stopwatchElapsedMs);
    final isRunning = _stopwatch.isRunning;

    return Column(
      children: [
        Text(
          display,
          style: AppTypography.clockBig.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularIconButton(
              icon: AppIcons.refreshCw,
              size: 54,
              iconSize: 22,
              onPressed: _resetStopwatch,
            ),
            const SizedBox(width: 24),
            CircularIconButton(
              icon: isRunning ? AppIcons.pause : AppIcons.play,
              isFilled: true,
              size: 64,
              iconSize: 26,
              onPressed: _toggleStopwatch,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerView(bool isDark, Color textMuted) {
    final display = _formatTimer(_timerRemainingSeconds);

    return Column(
      children: [
        Text(
          display,
          style: AppTypography.clockBig.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              child: TextField(
                controller: _timerMinutesController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                enabled: !_isTimerRunning,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val) ?? 5;
                  setState(() {
                    _timerDurationMinutes = parsed.clamp(1, 600);
                    _timerRemainingSeconds = _timerDurationMinutes * 60;
                  });
                },
              ),
            ),
            const SizedBox(width: 18),
            CircularIconButton(
              icon: AppIcons.refreshCw,
              size: 54,
              iconSize: 22,
              onPressed: _resetCountdown,
            ),
            const SizedBox(width: 18),
            CircularIconButton(
              icon: _isTimerRunning ? AppIcons.pause : AppIcons.play,
              isFilled: true,
              size: 64,
              iconSize: 26,
              onPressed: _toggleCountdown,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'minutes',
          style: TextStyle(
            color: textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

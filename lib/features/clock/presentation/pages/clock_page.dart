import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

class ClockPage extends ConsumerStatefulWidget {
  const ClockPage({super.key});

  @override
  ConsumerState<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends ConsumerState<ClockPage> with SingleTickerProviderStateMixin {
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

  // Alarm list state
  final List<AlarmItem> _alarms = [
    AlarmItem(id: 1, time: const TimeOfDay(hour: 7, minute: 0), label: 'Morning Wake Up', days: 'Weekdays', isEnabled: true),
    AlarmItem(id: 2, time: const TimeOfDay(hour: 8, minute: 30), label: 'Work Start', days: 'Daily', isEnabled: false),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
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

  void _toggleTimer() {
    if (_isTimerRunning) {
      _countDownTimer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      if (_timerSeconds <= 0) return;
      setState(() => _isTimerRunning = true);
      _countDownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_timerSeconds > 1) {
          setState(() => _timerSeconds--);
        } else {
          _countDownTimer?.cancel();
          setState(() {
            _timerSeconds = 0;
            _isTimerRunning = false;
          });
          NotificationService.instance.showNotification(
            id: 999001,
            title: 'Timer Finished! ⏰',
            body: 'Your countdown timer has ended.',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Timer Finished! ⏰'), backgroundColor: Colors.green),
            );
          }
        }
      });
    }
  }

  void _resetTimer() {
    _countDownTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _timerSeconds = _timerInitialSeconds;
    });
  }

  void _setTimerDuration(int seconds) {
    _countDownTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _timerInitialSeconds = seconds;
      _timerSeconds = seconds;
    });
  }

  Future<void> _showCustomTimerDialog() async {
    final minutesController = TextEditingController(text: (_timerInitialSeconds ~/ 60).toString());
    final secondsController = TextEditingController(text: (_timerInitialSeconds % 60).toString());

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
                decoration: const InputDecoration(labelText: 'Minutes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: secondsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Seconds'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final m = int.tryParse(minutesController.text.trim()) ?? 0;
              final s = int.tryParse(secondsController.text.trim()) ?? 0;
              final total = (m * 60) + s;
              if (total > 0) {
                _setTimerDuration(total);
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
    final labelController = TextEditingController(text: existingAlarm?.label ?? 'Alarm');
    String selectedDays = existingAlarm?.days ?? 'Daily';

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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: selectedTime);
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
                value: selectedDays,
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
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() => _alarms.remove(existingAlarm));
                  Navigator.pop(ctx);
                },
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final label = labelController.text.trim().isEmpty ? 'Alarm' : labelController.text.trim();
                if (existingAlarm != null) {
                  setState(() {
                    existingAlarm.time = selectedTime;
                    existingAlarm.label = label;
                    existingAlarm.days = selectedDays;
                  });
                } else {
                  setState(() {
                    _alarms.add(
                      AlarmItem(
                        id: DateTime.now().millisecondsSinceEpoch % 100000,
                        time: selectedTime,
                        label: label,
                        days: selectedDays,
                        isEnabled: true,
                      ),
                    );
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleAlarmState(AlarmItem alarm, bool val) {
    setState(() => alarm.isEnabled = val);
    if (val) {
      NotificationService.instance.showNotification(
        id: alarm.id,
        title: 'Alarm Set ⏰',
        body: '${alarm.label} scheduled for ${alarm.time.format(context)} (${alarm.days})',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alarm set for ${alarm.time.format(context)}')),
      );
    }
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
                  style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${_now.day}/${_now.month}/${_now.year}',
                  style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
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
            body: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _alarms.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final alarm = _alarms[index];
                return SwitchListTile(
                  title: Text(
                    alarm.time.format(context),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${alarm.days} • ${alarm.label}'),
                  value: alarm.isEnabled,
                  onChanged: (val) => _toggleAlarmState(alarm, val),
                  secondary: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _addOrEditAlarm(existingAlarm: alarm),
                  ),
                );
              },
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
                    '${(_timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
                    style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 64),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(label: const Text('1 min'), onPressed: () => _setTimerDuration(60)),
                      ActionChip(label: const Text('5 min'), onPressed: () => _setTimerDuration(300)),
                      ActionChip(label: const Text('10 min'), onPressed: () => _setTimerDuration(600)),
                      ActionChip(label: const Text('15 min'), onPressed: () => _setTimerDuration(900)),
                      ActionChip(label: const Text('Custom'), onPressed: _showCustomTimerDialog),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _toggleTimer,
                        icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
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
                  style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 64),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _toggleStopwatch,
                      icon: Icon(_isStopwatchRunning ? Icons.pause : Icons.play_arrow),
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


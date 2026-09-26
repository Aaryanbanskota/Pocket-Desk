import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';

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
  int _timerSeconds = 60;
  bool _isTimerRunning = false;

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
      setState(() => _isTimerRunning = true);
      _countDownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_timerSeconds > 0) {
          setState(() => _timerSeconds--);
        } else {
          _countDownTimer?.cancel();
          setState(() => _isTimerRunning = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timer Finished!')));
        }
      });
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
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              SwitchListTile(
                title: const Text('07:00 AM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                subtitle: const Text('Weekdays • Morning Wake Up'),
                value: true,
                onChanged: (_) {},
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('08:30 AM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                subtitle: const Text('Daily • Work Start'),
                value: false,
                onChanged: (_) {},
              ),
            ],
          ),

          // 3. Timer Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(_timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
                  style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: _toggleTimer,
                      child: Text(_isTimerRunning ? 'Pause' : 'Start'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    OutlinedButton(
                      onPressed: () {
                        _countDownTimer?.cancel();
                        setState(() {
                          _isTimerRunning = false;
                          _timerSeconds = 60;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Stopwatch Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(_stopwatchMilliseconds ~/ 1000).toString().padLeft(2, '0')}.${((_stopwatchMilliseconds % 1000) ~/ 100)}',
                  style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: _toggleStopwatch,
                      child: Text(_isStopwatchRunning ? 'Pause' : 'Start'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    OutlinedButton(
                      onPressed: _resetStopwatch,
                      child: const Text('Reset'),
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

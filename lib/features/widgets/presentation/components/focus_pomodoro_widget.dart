import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_icons.dart';
import 'calendar_month_widget.dart';

/// Focus & Pomodoro Timer Widget for home screen
class FocusPomodoroWidget extends StatefulWidget {
  final WidgetSize size;
  final bool isDarkMode;
  final VoidCallback? onTap;

  const FocusPomodoroWidget({
    super.key,
    this.size = WidgetSize.medium,
    this.isDarkMode = false,
    this.onTap,
  });

  @override
  State<FocusPomodoroWidget> createState() => _FocusPomodoroWidgetState();
}

class _FocusPomodoroWidgetState extends State<FocusPomodoroWidget> {
  int _secondsLeft = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          t.cancel();
          setState(() {
            _isRunning = false;
            _secondsLeft = 25 * 60;
          });
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsLeft = 25 * 60;
    });
  }

  String _formatTime() {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFFFFFDF9);
    final textPrimary = widget.isDarkMode ? Colors.white : const Color(0xFF1C1917);
    final textMuted = widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF78716C);
    final borderColor = widget.isDarkMode ? const Color(0xFF2E2E34) : const Color(0xFFE7E5E4);
    final surface2 = widget.isDarkMode ? const Color(0xFF282830) : const Color(0xFFF5F3EF);
    final progress = (25 * 60 - _secondsLeft) / (25 * 60);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.35 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _buildLayout(context, textPrimary, textMuted, borderColor, surface2, progress),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
    double progress,
  ) {
    switch (widget.size) {
      case WidgetSize.small:
        return _buildSmall(textPrimary, textMuted, surface2, progress);
      case WidgetSize.medium:
        return _buildMedium(textPrimary, textMuted, surface2, progress);
      case WidgetSize.large:
        return _buildLarge(textPrimary, textMuted, borderColor, surface2, progress);
    }
  }

  Widget _buildSmall(Color textPrimary, Color textMuted, Color surface2, double progress) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(AppIcons.clock, size: 14, color: AppColors.accentOrange),
                const SizedBox(width: 5),
                Text(
                  'Focus',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _isRunning
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : surface2,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isRunning ? 'Active' : '25m',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: _isRunning ? const Color(0xFF10B981) : textMuted,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress > 0 ? progress : 1.0,
                strokeWidth: 5,
                backgroundColor: surface2,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
              ),
              Center(
                child: Text(
                  _formatTime(),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _toggleTimer,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isRunning ? AppIcons.pause : AppIcons.play, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _isRunning ? 'Pause' : 'Start',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _resetTimer,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surface2,
                ),
                child: Icon(AppIcons.reset, size: 12, color: textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedium(Color textPrimary, Color textMuted, Color surface2, double progress) {
    return Row(
      children: [
        // Left: Dial
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress > 0 ? progress : 1.0,
                strokeWidth: 5,
                backgroundColor: surface2,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
              ),
              Center(
                child: Icon(
                  _isRunning ? AppIcons.pause : AppIcons.play,
                  size: 18,
                  color: AppColors.accentOrange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Middle: Timer Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Pomodoro Focus',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isRunning ? 'Deep focus active' : 'Ready for 25m session',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: _isRunning ? const Color(0xFF10B981) : textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Right: Actions
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _toggleTimer,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentOrange,
                ),
                child: Icon(
                  _isRunning ? AppIcons.pause : AppIcons.play,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _resetTimer,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surface2,
                ),
                child: Icon(
                  AppIcons.reset,
                  size: 13,
                  color: textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLarge(
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(AppIcons.clock, size: 16, color: AppColors.accentOrange),
                const SizedBox(width: 6),
                Text(
                  'Deep Focus Pomodoro',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '25m / 5m',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accentOrange),
              ),
            ),
          ],
        ),

        // Big Dial
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress > 0 ? progress : 1.0,
                strokeWidth: 8,
                backgroundColor: surface2,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(),
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textPrimary),
                    ),
                    Text(
                      _isRunning ? 'ACTIVE' : 'READY',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: _isRunning ? const Color(0xFF10B981) : textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Action Buttons Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: Icon(_isRunning ? AppIcons.pause : AppIcons.play, size: 16),
              label: Text(_isRunning ? 'Pause' : 'Start Focus', style: const TextStyle(fontWeight: FontWeight.w700)),
              onPressed: _toggleTimer,
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: textMuted,
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(AppIcons.reset, size: 14),
              label: const Text('Reset'),
              onPressed: _resetTimer,
            ),
          ],
        ),
      ],
    );
  }
}

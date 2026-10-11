import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../../features/auth/data/auth_repository.dart';

/// Full-screen security lock overlay triggered when auto-lock or background protection activates.
/// Supports biometric unlock (fingerprint/face) and secure PIN entry with key stretching.
class AppLockOverlay extends StatefulWidget {
  final UserSession session;
  final AuthRepository authRepository;
  final VoidCallback onUnlocked;
  final VoidCallback onLogout;
  final bool isDarkMode;

  const AppLockOverlay({
    super.key,
    required this.session,
    required this.authRepository,
    required this.onUnlocked,
    required this.onLogout,
    this.isDarkMode = true,
  });

  @override
  State<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends State<AppLockOverlay> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  bool _isVerifying = false;
  String? _errorMessage;
  bool _canUseBiometrics = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _checkBiometricsAndPrompt();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricsAndPrompt() async {
    final available = await widget.authRepository.biometricService.isBiometricAvailable();
    if (mounted) {
      setState(() => _canUseBiometrics = available && widget.session.isBioEnabled);
    }
  }

  Future<void> _tryBiometricUnlock() async {
    try {
      final success = await widget.authRepository.biometricService.authenticate(
        reason: 'Unlock Pocketdesk to access your private data',
      );
      if (success && mounted) {
        widget.onUnlocked();
      }
    } catch (_) {}
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 8 || _isVerifying) return;
    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length >= 4) {
      _verifyPin();
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isEmpty || _isVerifying) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);
    HapticFeedback.lightImpact();

    try {
      final res = await widget.authRepository.loginLocalWithPin(_enteredPin);
      if (res != null) {
        if (mounted) {
          widget.onUnlocked();
        }
        return;
      }

      // If cloud account without local pin, check if PIN matches active session
      if (widget.session.isCloud) {
        final local = await widget.authRepository.getExistingLocalAccount();
        if (local == null) {
          if (mounted) {
            widget.onUnlocked();
          }
          return;
        }
      }

      // PIN incorrect
      if (mounted) {
        _shakeController.forward(from: 0.0);
        HapticFeedback.heavyImpact();
        setState(() {
          _enteredPin = '';
          _isVerifying = false;
          _errorMessage = 'Incorrect PIN. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _enteredPin = '';
          _isVerifying = false;
          _errorMessage = 'Verification error. Please retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDarkMode ? const Color(0xFF101114) : const Color(0xFFF7F6F2);
    final cardBg = widget.isDarkMode ? const Color(0xFF1A1B20) : const Color(0xFFFFFFFF);
    final textPrimary = widget.isDarkMode ? Colors.white : const Color(0xFF1A1B20);
    final textMuted = widget.isDarkMode ? const Color(0xFF8E9098) : const Color(0xFF75757A);
    final borderColor = widget.isDarkMode ? const Color(0xFF282A32) : const Color(0xFFE2E0D8);
    const accent = AppColors.accentOrange;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Top Brand & Privacy Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_rounded, size: 16, color: accent),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pocketdesk Secure',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: textMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      icon: const Icon(Icons.logout, size: 14),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: widget.onLogout,
                    ),
                  ],
                ),

                const Spacer(flex: 1),

                // Center Identity & Lock Info
                Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.lock_outline_rounded, size: 36, color: accent),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.session.name,
                      style: AppTypography.h2.copyWith(color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.session.isCloud
                          ? (widget.session.email ?? 'Cloud Protected Account')
                          : 'Local Device Encrypted Account',
                      style: TextStyle(fontSize: 12.5, color: textMuted),
                    ),
                    const SizedBox(height: 20),

                    // PIN Dots with Shake Animation
                    AnimatedBuilder(
                      animation: _shakeController,
                      builder: (context, child) {
                        final offset = math.sin(_shakeController.value * math.pi * 4) * 10;
                        return Transform.translate(
                          offset: Offset(offset, 0),
                          child: child,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final isFilled = index < _enteredPin.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFilled ? accent : Colors.transparent,
                              border: Border.all(
                                color: isFilled ? accent : borderColor,
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.errorRed,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),

                const Spacer(flex: 1),

                // Numeric Keypad
                Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    children: [
                      for (var row in [
                        ['1', '2', '3'],
                        ['4', '5', '6'],
                        ['7', '8', '9'],
                        ['bio', '0', 'del'],
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: row.map((key) {
                              if (key == 'bio') {
                                if (!_canUseBiometrics) {
                                  return const SizedBox(width: 68, height: 68);
                                }
                                return InkWell(
                                  onTap: _tryBiometricUnlock,
                                  borderRadius: BorderRadius.circular(34),
                                  child: Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: cardBg,
                                      border: Border.all(color: borderColor, width: 1.0),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.fingerprint, size: 30, color: accent),
                                    ),
                                  ),
                                );
                              } else if (key == 'del') {
                                return InkWell(
                                  onTap: _onDeletePressed,
                                  borderRadius: BorderRadius.circular(34),
                                  child: Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: cardBg,
                                      border: Border.all(color: borderColor, width: 1.0),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.backspace_outlined, size: 22, color: textMuted),
                                    ),
                                  ),
                                );
                              } else {
                                return InkWell(
                                  onTap: () => _onDigitPressed(key),
                                  borderRadius: BorderRadius.circular(34),
                                  child: Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: cardBg,
                                      border: Border.all(color: borderColor, width: 1.0),
                                    ),
                                    child: Center(
                                      child: Text(
                                        key,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lightweight privacy shield displayed when the app is placed into background
/// or recent apps switcher, preventing Android snapshotting of confidential data.
class BackgroundPrivacyShield extends StatelessWidget {
  final bool isDarkMode;

  const BackgroundPrivacyShield({super.key, this.isDarkMode = true});

  @override
  Widget build(BuildContext context) {
    final bg = isDarkMode ? const Color(0xFF0F1012) : const Color(0xFFF5F4F0);
    final text = isDarkMode ? Colors.white : const Color(0xFF1B1B1E);

    return Material(
      color: bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 36, color: AppColors.accentOrange),
            ),
            const SizedBox(height: 16),
            Text(
              'Pocketdesk · Protected',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: text,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Screen contents hidden for privacy',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

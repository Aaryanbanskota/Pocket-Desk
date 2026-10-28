import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_typography.dart';
import '../../settings/presentation/pages/legal_document_page.dart';
import '../../settings/data/legacy_pocketdesk_importer.dart';
import '../../settings/presentation/dialogs/pull_pocketdesk_data_sheet.dart';
import '../data/auth_repository.dart';

class AuthScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final ValueChanged<UserSession> onAuthenticated;

  const AuthScreen({
    super.key,
    required this.authRepository,
    required this.onAuthenticated,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Tab: 'cloud' or 'local'
  String _tab = 'local'; // Default to local for offline-first

  // Cloud state
  bool _isRegister = false;
  bool _agreedToTerms = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cloudNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Local state
  Map<String, dynamic>? _existingLocalAccount;
  UserSession? _lastCloudSession;
  bool _isLoadingLocal = true;
  String _localName = '';
  final _localNameController = TextEditingController();
  String _enteredPin = '';
  String _pinConfirmation = '';
  bool _isConfirmingPin = false;

  // Scoped error messages
  String? _cloudErrorMessage;
  String? _localErrorMessage;
  String? _infoBannerMessage;
  bool _isBusy = false;
  bool _isResendingEmail = false;
  int _resendCooldownSeconds = 0;
  Timer? _resendCooldownTimer;

  @override
  void initState() {
    super.initState();
    _checkExistingAccounts();
  }

  @override
  void dispose() {
    _resendCooldownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cloudNameController.dispose();
    _localNameController.dispose();
    super.dispose();
  }

  void _startResendCooldown([int seconds = 60]) {
    _resendCooldownTimer?.cancel();
    setState(() => _resendCooldownSeconds = seconds);
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _resendCooldownSeconds = 0);
      } else {
        setState(() => _resendCooldownSeconds--);
      }
    });
  }

  Future<void> _checkExistingAccounts() async {
    Map<String, dynamic>? existing;
    UserSession? lastCloud;
    try {
      existing = await widget.authRepository
          .getExistingLocalAccount()
          .timeout(const Duration(seconds: 2));
    } catch (_) {}

    try {
      lastCloud = await widget.authRepository
          .getLastCloudSession()
          .timeout(const Duration(seconds: 2));
    } catch (_) {}

    if (mounted) {
      setState(() {
        _existingLocalAccount = existing;
        _lastCloudSession = lastCloud;
        _isLoadingLocal = false;
      });
    }
  }

  Future<void> _onCloudBiometricTap() async {
    try {
      final available = await widget.authRepository.biometricService.isBiometricAvailable();
      if (!available) {
        if (mounted) {
          setState(() => _cloudErrorMessage = 'Biometrics not supported or enrolled on this device.');
        }
        return;
      }
      setState(() => _isBusy = true);
      final session = await widget.authRepository.loginCloudWithBiometrics();
      if (mounted) {
        setState(() => _isBusy = false);
        if (session != null) {
          try {
            widget.onAuthenticated(session);
          } catch (e) {
            setState(() => _cloudErrorMessage = 'Error launching account: $e');
          }
        } else {
          setState(() => _cloudErrorMessage = 'Biometric authentication cancelled or not recognized');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _cloudErrorMessage = 'Biometric error: $e';
        });
      }
    }
  }

  Future<void> _onKeypadTap(String key) async {
    if (_isBusy) return;
    if (_enteredPin.length >= 4 && key != 'del') return;

    setState(() {
      _localErrorMessage = null;
      if (key == 'del') {
        if (_enteredPin.isNotEmpty) {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      } else {
        _enteredPin += key;
      }
    });

    if (_enteredPin.length == 4) {
      // 220ms delay ensures Flutter paints all 4 dots filled on screen,
      // providing clear visual feedback that the 4th digit entered!
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      await _handlePinCompleted();
    }
  }

  Future<void> _handlePinCompleted() async {
    final pin = _enteredPin;

    if (_existingLocalAccount != null) {
      // Existing user logging in
      setState(() => _isBusy = true);
      UserSession? session;
      try {
        session = await widget.authRepository.loginLocalWithPin(pin);
      } catch (e) {
        if (mounted) {
          setState(() {
            _isBusy = false;
            _enteredPin = '';
            _localErrorMessage = 'Unlock failed: ${e.toString()}';
          });
        }
        return;
      }

      if (mounted) {
        setState(() => _isBusy = false);
        if (session != null) {
          try {
            widget.onAuthenticated(session);
          } catch (e) {
            setState(() {
              _enteredPin = '';
              _localErrorMessage = 'Error launching session: ${e.toString()}';
            });
          }
        } else {
          setState(() {
            _enteredPin = '';
            _localErrorMessage = 'Wrong PIN. Please try again.';
          });
        }
      }
    } else {
      // Creating PIN
      if (!_isConfirmingPin) {
        // Step 1 completed -> Move to Step 2 (Confirmation)
        setState(() {
          _pinConfirmation = pin;
          _isConfirmingPin = true;
          _enteredPin = '';
          _localErrorMessage = null;
        });
      } else {
        // Step 2: Confirming PIN
        if (pin == _pinConfirmation) {
          setState(() => _isBusy = true);
          try {
            final session = await widget.authRepository.createLocalAccount(
              name: _localName,
              pin: pin,
            );
            if (mounted) {
              setState(() => _isBusy = false);
              widget.onAuthenticated(session);
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isBusy = false;
                _enteredPin = '';
                _localErrorMessage = 'Account creation error: ${e.toString()}';
              });
            }
          }
        } else {
          setState(() {
            _enteredPin = '';
            _localErrorMessage = 'PINs did not match. Please re-enter your 4-digit PIN.';
          });
        }
      }
    }
  }

  void _continueToLocalPin() {
    final name = _localNameController.text.trim();
    if (name.length < 2) {
      setState(() => _localErrorMessage = 'Please enter your name.');
      return;
    }
    if (!_agreedToTerms) {
      setState(() => _localErrorMessage = 'Please accept the Terms of Service and Privacy Policy to continue.');
      return;
    }
    setState(() {
      _localName = name;
      _localErrorMessage = null;
      _isConfirmingPin = false;
      _enteredPin = '';
      _pinConfirmation = '';
    });
  }

  void _showForgotPasswordDialog() {
    final resetEmailCtrl = TextEditingController(text: _emailController.text.trim());
    bool isSending = false;
    String? dialogError;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.appSurface,
            title: Text(
              'Reset Password',
              style: TextStyle(color: context.appText, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your email address to receive a password reset link.',
                  style: TextStyle(color: context.appMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: context.appText),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'user@example.com',
                    filled: true,
                    fillColor: context.appBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    dialogError!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: TextStyle(color: context.appMuted)),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        final email = resetEmailCtrl.text.trim();
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                          setDialogState(() => dialogError = 'Please enter a valid email address.');
                          return;
                        }
                        setDialogState(() {
                          isSending = true;
                          dialogError = null;
                        });
                        try {
                          await widget.authRepository.sendPasswordResetEmail(email);
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                          if (mounted) {
                            setState(() {
                              _infoBannerMessage = 'Password reset link sent to $email. Please check your inbox.';
                              _cloudErrorMessage = null;
                            });
                          }
                        } catch (e) {
                          setDialogState(() {
                            isSending = false;
                            dialogError = e
                                .toString()
                                .replaceFirst('Exception: ', '')
                                .replaceFirst('AuthException: ', '');
                          });
                        }
                      },
                child: Text(isSending ? 'Sending...' : 'Send Link'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onBiometricTap() async {
    try {
      final available = await widget.authRepository.biometricService.isBiometricAvailable();
      if (!available) {
        if (mounted) {
          setState(() => _localErrorMessage = 'Biometrics not supported or enrolled on this device. Use your PIN.');
        }
        return;
      }
      setState(() => _isBusy = true);
      final session = await widget.authRepository.loginLocalWithBiometrics();
      if (mounted) {
        setState(() => _isBusy = false);
        if (session != null) {
          try {
            widget.onAuthenticated(session);
          } catch (e) {
            setState(() => _localErrorMessage = 'Error launching session: $e');
          }
        } else {
          setState(() => _localErrorMessage = 'Biometric authentication cancelled or not recognized');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _localErrorMessage = 'Biometric error: $e';
        });
      }
    }
  }

  void _openOldPocketdeskMigrationSheet() {
    final importer = LegacyPocketdeskImporter(widget.authRepository.db);
    PullPocketdeskDataSheet.show(
      context: context,
      importer: importer,
      authRepository: widget.authRepository,
      onAccountCreated: (session) {
        widget.onAuthenticated(session);
      },
    );
  }

  Future<void> _handleCloudAuth() async {
    if (_isBusy) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _cloudNameController.text.trim();

    if (_isRegister && name.length < 2) {
      setState(() => _cloudErrorMessage = 'Please enter your name.');
      return;
    }

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _cloudErrorMessage = 'Enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      setState(() => _cloudErrorMessage = 'Password needs 6+ characters.');
      return;
    }

    if (_isRegister && password != _confirmPasswordController.text) {
      setState(() => _cloudErrorMessage = 'Passwords do not match.');
      return;
    }

    if (_isRegister && !_agreedToTerms) {
      setState(() => _cloudErrorMessage = 'Please accept the Terms of Service and Privacy Policy to create an account.');
      return;
    }

    setState(() {
      _isBusy = true;
      _cloudErrorMessage = null;
    });

    UserSession? session;
    try {
      session = await widget.authRepository.authenticateCloud(
        email: email,
        password: password,
        name: name,
        isRegister: _isRegister,
      );
    } on EmailConfirmationRequiredException catch (e) {
      if (mounted) {
        _startResendCooldown(60);
        setState(() {
          _isBusy = false;
          _isRegister = false;
          _infoBannerMessage = e.message;
          _cloudErrorMessage = null;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
      return;
    } catch (e) {
      if (mounted) {
        final errText = e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('AuthException: ', '');
        if (errText.toLowerCase().contains('rate limit') || errText.toLowerCase().contains('security purposes')) {
          _startResendCooldown(60);
        }
        if (errText.toLowerCase().contains('already exists') ||
            errText.toLowerCase().contains('already registered')) {
          setState(() {
            _isBusy = false;
            _isRegister = false; // Switch to login tab
            _cloudErrorMessage = 'An account with $email already exists. Please sign in with your password, or use Forgot password.';
          });
        } else {
          setState(() {
            _isBusy = false;
            _cloudErrorMessage = errText;
          });
        }
      }
      return;
    }

    if (mounted) {
      setState(() => _isBusy = false);
      try {
        widget.onAuthenticated(session);
      } catch (e) {
        setState(() => _cloudErrorMessage = 'Error launching session: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLocal) {
      return Scaffold(
        backgroundColor: context.appBg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.appBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Top Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 44),
                      Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              'assets/logo.jpeg',
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.accentOrange,
                                  child: const Center(
                                    child: Icon(
                                      Icons.calendar_month_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Import Old Pocket Dex Data',
                        icon: const Icon(AppIcons.refresh, size: 20, color: AppColors.accentOrange),
                        onPressed: _openOldPocketdeskMigrationSheet,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Segmented Tab Toggle [Cloud account | Local account]
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: context.appLine),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _tab = 'cloud';
                              _cloudErrorMessage = null;
                              _localErrorMessage = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _tab == 'cloud'
                                    ? (context.isDarkMode ? AppColors.darkText : AppColors.lightText)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Center(
                                child: Text(
                                  'Cloud account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _tab == 'cloud'
                                        ? (context.isDarkMode ? AppColors.darkBg : AppColors.lightBg)
                                        : context.appMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _tab = 'local';
                              _cloudErrorMessage = null;
                              _localErrorMessage = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _tab == 'local'
                                    ? (context.isDarkMode ? AppColors.darkText : AppColors.lightText)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Center(
                                child: Text(
                                  'Local account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _tab == 'local'
                                        ? (context.isDarkMode ? AppColors.darkBg : AppColors.lightBg)
                                        : context.appMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Content based on tab
                  if (_tab == 'cloud') _buildCloudAuth() else _buildLocalAuth(),

                  const SizedBox(height: 28),
                  _buildLegalFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloudAuth() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isRegister ? 'Create your account' : 'Welcome back',
          style: AppTypography.h2.copyWith(color: context.appText),
        ),
        const SizedBox(height: 4),
        Text(
          _isRegister
              ? 'Free cloud account powered by Supabase.'
              : 'Sign in to sync your data across devices.',
          style: AppTypography.body.copyWith(color: context.appMuted),
        ),
        const SizedBox(height: 20),

        if (_infoBannerMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentOrange.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.mark_email_read_rounded, color: AppColors.accentOrange, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _infoBannerMessage!,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        if (_isRegister) ...[
          _buildField(
            label: 'Full name',
            controller: _cloudNameController,
            hint: 'Aaryan',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
        ],

        _buildField(
          label: 'Email',
          controller: _emailController,
          hint: 'user@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),

        _buildField(
          label: 'Password',
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: _isRegister ? TextInputAction.next : TextInputAction.done,
          onSubmitted: (_) {
            if (!_isRegister) _handleCloudAuth();
          },
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? AppIcons.eye : AppIcons.eyeOff,
              size: 20,
              color: context.appMuted,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),

        if (!_isRegister) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  color: context.appMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],

        if (_isRegister) ...[
          const SizedBox(height: 14),
          _buildField(
            label: 'Confirm password',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleCloudAuth(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? AppIcons.eye : AppIcons.eyeOff,
                size: 20,
                color: context.appMuted,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          const SizedBox(height: 12),
          _buildTermsCheckbox(),
        ],

        const SizedBox(height: 12),
        if (_cloudErrorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.danger.withOpacity(0.3)),
            ),
            child: Text(
              _cloudErrorMessage!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
          if (_cloudErrorMessage!.toLowerCase().contains('email not confirmed') ||
              _cloudErrorMessage!.toLowerCase().contains('confirm') ||
              _cloudErrorMessage!.toLowerCase().contains('verify')) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: (_isResendingEmail || _resendCooldownSeconds > 0)
                    ? null
                    : () async {
                        final email = _emailController.text.trim();
                        if (email.isEmpty) return;
                        setState(() => _isResendingEmail = true);
                        try {
                          await widget.authRepository.resendConfirmationEmail(email);
                          if (mounted) {
                            _startResendCooldown(60);
                            setState(() {
                              _isResendingEmail = false;
                              _infoBannerMessage = 'Confirmation email resent to $email! Please check your inbox.';
                              _cloudErrorMessage = null;
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            _startResendCooldown(60);
                            setState(() {
                              _isResendingEmail = false;
                              _cloudErrorMessage = e
                                  .toString()
                                  .replaceFirst('Exception: ', '')
                                  .replaceFirst('AuthException: ', '');
                            });
                          }
                        }
                      },
                icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.accentOrange),
                label: Text(
                  _isResendingEmail
                      ? 'Sending...'
                      : _resendCooldownSeconds > 0
                          ? 'Wait ${_resendCooldownSeconds}s to resend'
                          : 'Resend confirmation email',
                  style: TextStyle(
                    color: _resendCooldownSeconds > 0 ? context.appMuted : AppColors.accentOrange,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 12),

        // Action Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.isDarkMode ? AppColors.darkText : AppColors.lightText,
            foregroundColor: context.isDarkMode ? AppColors.darkBg : AppColors.lightBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onPressed: _isBusy ? null : _handleCloudAuth,
          child: Text(
            _isBusy ? 'Please wait…' : (_isRegister ? 'Create account' : 'Login'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        if (!_isRegister && _lastCloudSession != null && _lastCloudSession!.isBioEnabled) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: context.appText,
              side: BorderSide(color: context.appLine),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _isBusy ? null : _onCloudBiometricTap,
            icon: const Icon(AppIcons.fingerprint, size: 20),
            label: Text('Unlock ${_lastCloudSession!.name} with Biometrics'),
          ),
        ],

        const SizedBox(height: 16),

        // Bottom link
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _isRegister = !_isRegister;
              _cloudErrorMessage = null;
              _infoBannerMessage = null;
            }),
            child: RichText(
              text: TextSpan(
                style: AppTypography.body.copyWith(color: context.appMuted),
                children: [
                  TextSpan(
                    text: _isRegister ? 'Have an account? ' : 'New here? ',
                  ),
                  TextSpan(
                    text: _isRegister ? 'Login' : 'Register',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.appText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalAuth() {
    if (_existingLocalAccount != null) {
      // Existing user entering PIN
      final name = _existingLocalAccount!['name'] as String;
      return Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final keyChar = event.character;
            if (keyChar != null && RegExp(r'^[0-9]$').hasMatch(keyChar)) {
              _onKeypadTap(keyChar);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.backspace ||
                event.logicalKey == LogicalKeyboardKey.delete) {
              _onKeypadTap('del');
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hi, $name',
              style: AppTypography.h2.copyWith(color: context.appText),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter your PIN to unlock.',
              style: AppTypography.body.copyWith(color: context.appMuted),
            ),
            const SizedBox(height: 24),

            // 4-dot PIN indicator
            _buildPinDots(),
            const SizedBox(height: 24),

            if (_localErrorMessage != null) ...[
              Center(
                child: Text(
                  _localErrorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 3x4 Keypad
            _buildKeypad(showBio: true),

            const SizedBox(height: 14),
            Center(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.appText,
                  side: BorderSide(color: context.appLine),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: _isBusy ? null : _onBiometricTap,
                icon: const Icon(AppIcons.fingerprint, size: 20, color: AppColors.accentOrange),
                label: const Text('Unlock with Biometrics', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: context.appSurface,
                      title: Text(
                        'Reset local account?',
                        style: TextStyle(color: context.appText),
                      ),
                      content: Text(
                        'This will delete the local account and its data on this device.',
                        style: TextStyle(color: context.appMuted),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await widget.authRepository.resetLocalAccount();
                    await _checkExistingAccounts();
                    setState(() {
                      _localName = '';
                      _enteredPin = '';
                      _isConfirmingPin = false;
                    });
                  }
                },
                child: Text(
                  'Reset local account',
                  style: TextStyle(color: context.appMuted, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _openOldPocketdeskMigrationSheet,
                icon: const Icon(AppIcons.refresh, size: 16, color: AppColors.accentOrange),
                label: const Text(
                  'Log in with old Pocket Dex account',
                  style: TextStyle(color: AppColors.accentOrange, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // No local account yet -> Create account flow
      if (_localName.isEmpty) {
        // Step 1: Name input
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create local account',
              style: AppTypography.h2.copyWith(color: context.appText),
            ),
            const SizedBox(height: 4),
            Text(
              'Everything stays on this device. No email needed.',
              style: AppTypography.body.copyWith(color: context.appMuted),
            ),
            const SizedBox(height: 20),

            _buildField(
              label: 'Your name',
              controller: _localNameController,
              hint: 'Aaryan',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _continueToLocalPin(),
            ),

            const SizedBox(height: 12),
            _buildTermsCheckbox(),

            const SizedBox(height: 12),
            if (_localErrorMessage != null)
              Text(
                _localErrorMessage!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            const SizedBox(height: 14),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.isDarkMode ? AppColors.darkText : AppColors.lightText,
                foregroundColor: context.isDarkMode ? AppColors.darkBg : AppColors.lightBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _continueToLocalPin,
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.appText,
                side: BorderSide(color: context.appLine),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _openOldPocketdeskMigrationSheet,
              icon: const Icon(AppIcons.refresh, size: 18, color: AppColors.accentOrange),
              label: const Text(
                'Have an old Pocket Dex account? Log in & Import',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      } else {
        // Step 2 & 3: PIN Pad
        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              final keyChar = event.character;
              if (keyChar != null && RegExp(r'^[0-9]$').hasMatch(keyChar)) {
                _onKeypadTap(keyChar);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.backspace ||
                  event.logicalKey == LogicalKeyboardKey.delete) {
                _onKeypadTap('del');
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isConfirmingPin ? 'Confirm your PIN' : 'Create a PIN',
                style: AppTypography.h2.copyWith(color: context.appText),
              ),
              const SizedBox(height: 4),
              Text(
                _isConfirmingPin
                    ? 'Step 2 of 2: Re-enter your 4-digit PIN to confirm.'
                    : 'Step 1 of 2: Choose 4 digits to protect your data.',
                style: AppTypography.body.copyWith(color: context.appMuted),
              ),
              const SizedBox(height: 24),

              _buildPinDots(),
              const SizedBox(height: 24),

              if (_localErrorMessage != null) ...[
                Center(
                  child: Text(
                    _localErrorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              _buildKeypad(showBio: false),

              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_isConfirmingPin) {
                        _isConfirmingPin = false;
                        _enteredPin = '';
                        _pinConfirmation = '';
                        _localErrorMessage = null;
                      } else {
                        _localName = '';
                        _enteredPin = '';
                        _localErrorMessage = null;
                      }
                    });
                  },
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text(
                    _isConfirmingPin ? 'Change PIN' : 'Change Name',
                    style: TextStyle(color: context.appMuted, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 4; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _enteredPin.length
                  ? (_enteredPin.length == 4 && _isConfirmingPin && _enteredPin == _pinConfirmation
                      ? AppColors.success
                      : (context.isDarkMode ? AppColors.darkText : AppColors.lightText))
                  : Colors.transparent,
              border: Border.all(
                color: i < _enteredPin.length
                    ? (_enteredPin.length == 4 && _isConfirmingPin && _enteredPin == _pinConfirmation
                        ? AppColors.success
                        : (context.isDarkMode ? AppColors.darkText : AppColors.lightText))
                    : context.appMuted,
                width: 2.0,
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: 18),
        ],
      ],
    );
  }

  Widget _buildKeypad({required bool showBio}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        children: [
          for (int i = 1; i <= 9; i++) _buildKeyButton('$i'),
          // Bottom row
          if (showBio)
            GestureDetector(
              onTap: _onBiometricTap,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.appSurface,
                ),
                child: Center(
                  child: Icon(
                    AppIcons.fingerprint,
                    color: context.appText,
                    size: 26,
                  ),
                ),
              ),
            )
          else if (_isConfirmingPin)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isConfirmingPin = false;
                  _enteredPin = '';
                  _pinConfirmation = '';
                  _localErrorMessage = null;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.appSurface,
                ),
                child: Center(
                  child: Icon(
                    Icons.undo_rounded,
                    color: context.appMuted,
                    size: 22,
                  ),
                ),
              ),
            )
          else
            const SizedBox(),
          _buildKeyButton('0'),
          GestureDetector(
            onTap: () => _onKeypadTap('del'),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.appSurface,
              ),
              child: Center(
                child: Icon(
                  AppIcons.back,
                  color: context.appText,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyButton(String label) {
    return InkWell(
      onTap: () => _onKeypadTap(label),
      customBorder: const CircleBorder(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.appSurface,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.h2.copyWith(
              color: context.appText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.captionMuted.copyWith(color: context.appMuted),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: TextStyle(color: context.appText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.appMuted.withValues(alpha: 0.5)),
            filled: true,
            fillColor: context.appSurface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.appLine),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.appLine),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.appMuted),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _agreedToTerms,
              activeColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              onChanged: (val) {
                setState(() {
                  _agreedToTerms = val ?? false;
                  if (_agreedToTerms) {
                    _cloudErrorMessage = null;
                    _localErrorMessage = null;
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'I agree to the ',
                  style: TextStyle(fontSize: 12, color: context.appMuted),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const TermsAndConditionsPage()),
                    );
                  },
                  child: const Text(
                    'Terms of Service',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  ' and ',
                  style: TextStyle(fontSize: 12, color: context.appMuted),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyPage()),
                    );
                  },
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalFooter() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TermsAndConditionsPage()),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 12,
                color: context.appMuted,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          Text(
            '•',
            style: TextStyle(fontSize: 12, color: context.appMuted),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyPage()),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 12,
                color: context.appMuted,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

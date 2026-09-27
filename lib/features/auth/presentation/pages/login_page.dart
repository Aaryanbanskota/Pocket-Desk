import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_notifier.dart';
import '../widgets/auth_logo_header.dart';
import '../widgets/pd_text_field.dart';
import '../../data/services/biometric_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _submitting = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _biometricLoading = false;
  String? _lastUsername;
  final _biometricService = BiometricService();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _initBiometricAndUsername();
  }

  Future<void> _initBiometricAndUsername() async {
    final available = await _biometricService.isBiometricAvailable();
    final notifier = ref.read(authNotifierProvider.notifier);
    final enabled = await notifier.getBiometricEnabled();
    final lastUser = await notifier.getLastUsername();

    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _lastUsername = lastUser;
      if (lastUser != null && _userCtrl.text.isEmpty) {
        _userCtrl.text = lastUser;
      }
    });

    // Auto-trigger biometric login if enabled
    if (available && enabled) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) _biometricLogin();
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    await ref.read(authNotifierProvider.notifier).login(
          username: _userCtrl.text.trim(),
          password: _passCtrl.text,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    final authState = ref.read(authNotifierProvider).valueOrNull;
    if (authState is AuthError) {
      _showError(authState.failure.message);
    }
    // If authenticated, router redirect handles navigation automatically.
  }

  Future<void> _biometricLogin() async {
    setState(() => _biometricLoading = true);
    final authenticated = await _biometricService.authenticate();
    if (!mounted) return;
    if (authenticated) {
      // Restore session — if a session exists the user is logged in.
      await ref.read(authNotifierProvider.notifier).restoreSession();
      if (!mounted) return;
      final authState = ref.read(authNotifierProvider).valueOrNull;
      if (authState is! AuthAuthenticated) {
        _showError('No saved session. Please sign in with your password first.');
      }
    } else {
      _showError('Biometric authentication failed or was cancelled.');
    }
    if (mounted) setState(() => _biometricLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final resetUserCtrl = TextEditingController(text: _userCtrl.text.trim());
    final answerCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    String? foundQuestion;
    bool checkingUser = false;
    bool resetting = false;
    String? dialogError;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Reset Password'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dialogError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Text(
                        dialogError!,
                        style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  if (foundQuestion == null) ...[
                    const Text('Enter your username to look up your security question:'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: resetUserCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                  ] else ...[
                    Text('User: ${resetUserCtrl.text.trim()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (foundQuestion!.contains(' | ')) ...[
                      // 2 Questions
                      Builder(builder: (context) {
                        final qList = foundQuestion!.split(' | ');
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Question 1:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(qList[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: answerCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Answer 1',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.verified_user_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Question 2:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(qList[1], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: confirmPassCtrl, // reused for Answer 2 in 2-Q mode
                              decoration: const InputDecoration(
                                labelText: 'Answer 2',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.verified_user_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: newPassCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'New Password',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                            ),
                          ],
                        );
                      }),
                    ] else ...[
                      // Single Question legacy
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Security Question:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(foundQuestion!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: answerCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Your Answer',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.verified_user_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: newPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm New Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              if (foundQuestion == null)
                FilledButton(
                  onPressed: checkingUser
                      ? null
                      : () async {
                          final user = resetUserCtrl.text.trim();
                          if (user.isEmpty) {
                            setDialogState(() => dialogError = 'Please enter username');
                            return;
                          }
                          setDialogState(() {
                            checkingUser = true;
                            dialogError = null;
                          });
                          final q = await ref.read(authNotifierProvider.notifier).getSecurityQuestion(user);
                          setDialogState(() {
                            checkingUser = false;
                            if (q == null || q.isEmpty) {
                              dialogError = 'No security question found for user "$user".';
                            } else {
                              foundQuestion = q;
                            }
                          });
                        },
                  child: checkingUser
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Next'),
                )
              else
                FilledButton(
                  onPressed: resetting
                      ? null
                      : () async {
                          final isMulti = foundQuestion!.contains(' | ');
                          final ans1 = answerCtrl.text.trim();
                          final ans2 = confirmPassCtrl.text.trim();
                          final newP = newPassCtrl.text;

                          if (isMulti) {
                            if (ans1.isEmpty || ans2.isEmpty) {
                              setDialogState(() => dialogError = 'Both security answers are required.');
                              return;
                            }
                          } else {
                            if (ans1.isEmpty) {
                              setDialogState(() => dialogError = 'Security answer is required.');
                              return;
                            }
                          }

                          if (newP.length < 6) {
                            setDialogState(() => dialogError = 'Password must be at least 6 characters.');
                            return;
                          }

                          final combinedAns = isMulti ? '$ans1 | $ans2' : ans1;

                          setDialogState(() {
                            resetting = true;
                            dialogError = null;
                          });

                          final err = await ref.read(authNotifierProvider.notifier).resetPasswordWithSecurityAnswer(
                                username: resetUserCtrl.text.trim(),
                                securityAnswer: combinedAns,
                                newPassword: newP,
                              );

                          if (ctx.mounted) {
                            if (err != null) {
                              setDialogState(() {
                                resetting = false;
                                dialogError = err.message;
                              });
                            } else {
                              Navigator.pop(ctx);
                              if (context.mounted) {
                                setState(() {
                                  _userCtrl.text = resetUserCtrl.text.trim();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password reset successfully! Please sign in with your new password.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: resetting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Reset Password'),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 700;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              AppColors.primary.withAlpha(15),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? size.width * 0.3 : AppSpacing.xl,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthLogoHeader(
                        subtitle: 'Welcome back',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildCard(theme, colorScheme),
                      const SizedBox(height: AppSpacing.lg),
                      _buildRegisterLink(theme, colorScheme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(80),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sign In',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Enter your credentials to continue',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PDTextField(
              controller: _userCtrl,
              label: 'Username',
              prefixIcon: Icons.person_outline_rounded,
              validator: Validators.username,
              textInputAction: TextInputAction.next,
              autocorrect: false,
            ),
            // --- Last-username suggestion chip ---
            if (_lastUsername != null &&
                _lastUsername!.isNotEmpty &&
                _userCtrl.text != _lastUsername)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    Text(
                      'Last used:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() => _userCtrl.text = _lastUsername!);
                      },
                      child: Chip(
                        avatar: Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        label: Text(_lastUsername!),
                        labelStyle: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor:
                            colorScheme.primary.withAlpha(20),
                        side: BorderSide(
                          color: colorScheme.primary.withAlpha(60),
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            PDTextField(
              controller: _passCtrl,
              label: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePass,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _obscurePass = !_obscurePass),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Password is required' : null,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showForgotPasswordDialog(context),
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SubmitButton(
              submitting: _submitting,
              label: 'Sign In',
              onPressed: _submit,
            ),
            if (_biometricAvailable && _biometricEnabled) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _biometricLoading ? null : _biometricLogin,
                icon: _biometricLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fingerprint_rounded),
                label: const Text('Sign In with Biometrics'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              'Keep your data organized on the go',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink(ThemeData theme, ColorScheme colorScheme) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.register),
          child: const Text('Create one'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared submit button widget
// ---------------------------------------------------------------------------

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.submitting,
    required this.label,
    required this.onPressed,
  });

  final bool submitting;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: submitting
          ? const SizedBox(
              height: 60,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
    );
  }
}

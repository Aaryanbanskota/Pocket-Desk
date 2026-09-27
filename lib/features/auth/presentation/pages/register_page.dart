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

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  
  final _customQ1Ctrl = TextEditingController();
  final _ans1Ctrl = TextEditingController();
  final _customQ2Ctrl = TextEditingController();
  final _ans2Ctrl = TextEditingController();

  int _currentStep = 1; // 1: Account Info, 2: Security Recovery Questions
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  final List<String> _presetQuestions1 = [
    'What was the name of your first pet?',
    'What city were you born in?',
    'What is your mother\'s maiden name?',
    'What was the model of your first car?',
    'Write my own custom question...',
  ];

  final List<String> _presetQuestions2 = [
    'What is your favorite book or movie?',
    'What was the name of your primary school?',
    'What is your favorite food?',
    'What was your childhood nickname?',
    'Write my own custom question...',
  ];

  late String _selectedQ1;
  late String _selectedQ2;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _selectedQ1 = _presetQuestions1.first;
    _selectedQ2 = _presetQuestions2.first;

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _customQ1Ctrl.dispose();
    _ans1Ctrl.dispose();
    _customQ2Ctrl.dispose();
    _ans2Ctrl.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (!(_step1FormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _currentStep = 2;
    });
  }

  void _backToStep1() {
    setState(() {
      _currentStep = 1;
    });
  }

  Future<void> _submit() async {
    if (!(_step2FormKey.currentState?.validate() ?? false)) return;

    final finalQ1 = _selectedQ1 == 'Write my own custom question...'
        ? _customQ1Ctrl.text.trim()
        : _selectedQ1;
    final finalQ2 = _selectedQ2 == 'Write my own custom question...'
        ? _customQ2Ctrl.text.trim()
        : _selectedQ2;

    final combinedQuestion = '$finalQ1 | $finalQ2';
    final combinedAnswer = '${_ans1Ctrl.text.trim()} | ${_ans2Ctrl.text.trim()}';

    setState(() => _submitting = true);

    await ref.read(authNotifierProvider.notifier).register(
          username: _userCtrl.text.trim(),
          password: _passCtrl.text,
          displayName:
              _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
          securityQuestion: combinedQuestion,
          securityAnswer: combinedAnswer,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    final authState = ref.read(authNotifierProvider).valueOrNull;
    if (authState is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.failure.message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
    }
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
                  horizontal: isWide ? size.width * 0.28 : AppSpacing.xl,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthLogoHeader(subtitle: 'Create your account'),
                      const SizedBox(height: AppSpacing.xl),
                      _buildCard(theme, colorScheme),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.login),
                            child: const Text('Sign in'),
                          ),
                        ],
                      ),
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
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentStep == 1
            ? _buildStep1(theme, colorScheme)
            : _buildStep2(theme, colorScheme),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme, ColorScheme colorScheme) {
    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Create Account',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Step 1 of 2',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your data stays on your device — always.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PDTextField(
            controller: _nameCtrl,
            label: 'Display Name',
            prefixIcon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          PDTextField(
            controller: _userCtrl,
            label: 'Username',
            prefixIcon: Icons.person_outline_rounded,
            validator: Validators.username,
            textInputAction: TextInputAction.next,
            autocorrect: false,
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
            validator: Validators.password,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          PDTextField(
            controller: _confirmCtrl,
            label: 'Confirm Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) =>
                Validators.confirmPassword(v, _passCtrl.text),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _goToStep2(),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PasswordStrengthIndicator(password: _passCtrl),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.primary,
            ),
            onPressed: _goToStep2,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Continue', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme, ColorScheme colorScheme) {
    final isCustom1 = _selectedQ1 == 'Write my own custom question...';
    final isCustom2 = _selectedQ2 == 'Write my own custom question...';

    return Form(
      key: _step2FormKey,
      child: Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Security Recovery Questions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Step 2 of 2',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Set up 2 security questions to recover your password if forgotten.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Question 1
          Text('Question 1', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<String>(
            value: _selectedQ1,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.help_outline_rounded, size: 20),
            ),
            items: _presetQuestions1
                .map((q) => DropdownMenuItem(
                      value: q,
                      child: Text(q, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedQ1 = val);
            },
          ),
          if (isCustom1) ...[
            const SizedBox(height: AppSpacing.sm),
            PDTextField(
              controller: _customQ1Ctrl,
              label: 'Enter your custom Question 1',
              prefixIcon: Icons.create_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please write your custom question' : null,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          PDTextField(
            controller: _ans1Ctrl,
            label: 'Answer 1',
            prefixIcon: Icons.verified_user_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Answer 1 is required' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.lg),

          // Question 2
          Text('Question 2', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<String>(
            value: _selectedQ2,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.help_outline_rounded, size: 20),
            ),
            items: _presetQuestions2
                .map((q) => DropdownMenuItem(
                      value: q,
                      child: Text(q, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedQ2 = val);
            },
          ),
          if (isCustom2) ...[
            const SizedBox(height: AppSpacing.sm),
            PDTextField(
              controller: _customQ2Ctrl,
              label: 'Enter your custom Question 2',
              prefixIcon: Icons.create_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please write your custom question' : null,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          PDTextField(
            controller: _ans2Ctrl,
            label: 'Answer 2',
            prefixIcon: Icons.verified_user_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Answer 2 is required' : null,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.xl),

          Row(
            children: [
              OutlinedButton(
                onPressed: _submitting ? null : _backToStep1,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 18),
                    SizedBox(width: 4),
                    Text('Back'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SubmitButton(
                  submitting: _submitting,
                  label: 'Create Account',
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Password strength indicator
// ---------------------------------------------------------------------------

class _PasswordStrengthIndicator extends StatefulWidget {
  const _PasswordStrengthIndicator({required this.password});
  final TextEditingController password;

  @override
  State<_PasswordStrengthIndicator> createState() =>
      _PasswordStrengthIndicatorState();
}

class _PasswordStrengthIndicatorState
    extends State<_PasswordStrengthIndicator> {
  @override
  void initState() {
    super.initState();
    widget.password.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.password.removeListener(_rebuild);
    super.dispose();
  }

  int _strength(String p) {
    if (p.isEmpty) return 0;
    var score = 0;
    if (p.length >= 8) score++;
    if (p.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$%^&*]').hasMatch(p)) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final s = _strength(widget.password.text);
    if (s == 0) return const SizedBox.shrink();

    final labels = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong'];
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.lightGreen,
      Colors.green,
    ];
    final idx = (s - 1).clamp(0, 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: i <= idx
                      ? colors[idx]
                      : Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          labels[idx],
          style: TextStyle(
            fontSize: 12,
            color: colors[idx],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

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

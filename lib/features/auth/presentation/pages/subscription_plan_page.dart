import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/services/account_plan_service.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_notifier.dart';

class SubscriptionPlanPage extends ConsumerStatefulWidget {
  const SubscriptionPlanPage({super.key});

  @override
  ConsumerState<SubscriptionPlanPage> createState() =>
      _SubscriptionPlanPageState();
}

class _SubscriptionPlanPageState extends ConsumerState<SubscriptionPlanPage> {
  CloudPlan _selectedPlan = CloudPlan.free;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Storage Plans'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? size.width * 0.2 : AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Your Supabase Cloud Plan',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a plan to continue to online Supabase authentication.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildPlanOption(
                plan: CloudPlan.free,
                title: 'Free Plan',
                price: '\$0 / month',
                storageText: '500 MB Free Cloud Storage',
                featuresText: 'Text-only storage (Notes, Tasks, Calendar & Settings)',
                badge: 'Popular Free',
                badgeColor: Colors.green,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildPlanOption(
                plan: CloudPlan.pro,
                title: 'Pro Plan (Text + Video)',
                price: '\$5 / month',
                storageText: '10 GB Cloud Storage',
                featuresText:
                    'Text + Video & High-res Media attachments with priority Supabase sync',
                badge: 'Pro Upgrade',
                badgeColor: Colors.amber.shade800,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () async {
                  final authState = ref.read(authNotifierProvider).valueOrNull;
                  final isAuthenticated = authState is AuthAuthenticated;
                  final planState = ref.read(accountPlanProvider);

                  // If user is logged into local account, prompt for Gmail email and password for Supabase conversion
                  if (isAuthenticated && planState.accountType == AccountType.local) {
                    final emailCtrl = TextEditingController();
                    final passCtrl = TextEditingController();
                    final formKey = GlobalKey<FormState>();

                    final converted = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (bottomCtx) {
                        final bottomInset = MediaQuery.of(bottomCtx).viewInsets.bottom;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
                          child: Form(
                            key: formKey,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Drag indicator handle
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.cloud_upload_rounded, color: colorScheme.primary, size: 24),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Cloud Account Setup',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: () => Navigator.pop(bottomCtx, false),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enter your Gmail address & password to convert your local account into a synced Supabase Cloud account:',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Gmail / Email Address',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                    validator: (v) => v == null || !v.contains('@')
                                        ? 'Enter a valid email address'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: passCtrl,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Cloud Account Password',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.lock_outline_rounded),
                                    ),
                                    validator: (v) => v == null || v.length < 6
                                        ? 'Password must be at least 6 characters'
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(bottomCtx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton.icon(
                                        onPressed: () async {
                                          if (!formKey.currentState!.validate()) return;
                                          Navigator.pop(bottomCtx, true);
                                        },
                                        icon: const Icon(Icons.cloud_done_rounded, size: 18),
                                        label: const Text('Convert Account'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );

                    if (converted != true || !context.mounted) return;

                    final userEmail = emailCtrl.text.trim();
                    final userPass = passCtrl.text;

                    // Show loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Connecting to Supabase Auth & sending confirmation email...'),
                          ],
                        ),
                        duration: Duration(seconds: 10),
                      ),
                    );

                    // Execute real Supabase Auth signup call
                    final authRes = await SupabaseAuthService.signUp(
                      email: userEmail,
                      password: userPass,
                    );

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();

                    if (!authRes.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Supabase Cloud Registration Error: ${authRes.errorMessage}'),
                          backgroundColor: Colors.red.shade700,
                          duration: const Duration(seconds: 6),
                        ),
                      );
                      return;
                    }

                    // If Pro plan selected, create record in pro_requests database table
                    if (_selectedPlan == CloudPlan.pro) {
                      await SupabaseAuthService.createProRequest(
                        email: userEmail,
                        userId: authRes.userId,
                      );
                    }

                    await ref
                        .read(accountPlanProvider.notifier)
                        .convertToCloudAccount(email: userEmail, plan: _selectedPlan);

                    if (!context.mounted) return;

                    if (_selectedPlan == CloudPlan.pro) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Confirmation email sent to $userEmail! Please check your inbox and click the link to confirm your account.\n\n'
                            'Your Pro request has been registered. Text data storage is active. Administrator will email payment link & activate Pro Image/Audio buckets manually upon payment.',
                          ),
                          duration: const Duration(seconds: 10),
                          backgroundColor: Colors.indigo,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Confirmation email sent to $userEmail! Please check your inbox and click the link to activate Free Cloud sync (500 MB Text).',
                          ),
                          duration: const Duration(seconds: 8),
                          backgroundColor: Colors.green.shade800,
                        ),
                      );
                    }

                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.dashboard);
                    }
                    return;
                  }

                  await ref
                      .read(accountPlanProvider.notifier)
                      .selectCloudPlan(_selectedPlan);
                  if (!context.mounted) return;

                  if (_selectedPlan == CloudPlan.pro) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Pro upgrade request recorded! Text data storage is active. Payment link will be emailed to activate media buckets.',
                        ),
                        duration: Duration(seconds: 6),
                        backgroundColor: Colors.indigo,
                      ),
                    );
                  }
                  if (context.canPop()) {
                    context.pop();
                  } else if (isAuthenticated) {
                    context.go(AppRoutes.dashboard);
                  } else {
                    context.push(AppRoutes.login);
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _selectedPlan == CloudPlan.free
                      ? 'Continue with Free Plan (500MB)'
                      : 'Continue with Pro Plan (\$5/mo)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanOption({
    required CloudPlan plan,
    required String title,
    required String price,
    required String storageText,
    required String featuresText,
    required String badge,
    required Color badgeColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedPlan == plan;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(15)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isSelected ? AppColors.primary : colorScheme.outlineVariant,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withAlpha(25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Radio<CloudPlan>(
                  value: plan,
                  groupValue: _selectedPlan,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPlan = val);
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        price,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(Icons.cloud_done_outlined,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  storageText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    featuresText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

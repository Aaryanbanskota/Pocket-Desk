import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_mode_notifier.dart';
import '../../../dashboard/presentation/widgets/app_hamburger_drawer.dart';

class AboutAppPage extends ConsumerStatefulWidget {
  const AboutAppPage({super.key});

  @override
  ConsumerState<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends ConsumerState<AboutAppPage> {
  bool _isOnline = false;
  bool _checkingOnline = true;
  int _versionClickCount = 0;

  static const String _logsUrl =
      'https://raw.githubusercontent.com/Aaryanbanskota/Pocket-Desk/refs/heads/main/website/logs.html?token=GHSAT0AAAAAAEIYBMYEOAP22DFD5JVV4HIE2VYUQBA';
  @override
  void initState() {
    super.initState();
    _checkOnlineStatus();
  }

  Future<void> _checkOnlineStatus() async {
    try {
      final res = await http.get(Uri.parse('https://github.com')).timeout(
            const Duration(seconds: 3),
            onTimeout: () => http.Response('', 408),
          );
      if (mounted) {
        setState(() {
          _isOnline = res.statusCode == 200;
          _checkingOnline = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isOnline = false;
          _checkingOnline = false;
        });
      }
    }
  }

  Future<void> _openWebUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnlocked = ref.watch(shareTabUnlockedProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About PocketDesk'),
        elevation: 0,
      ),
      drawer: const AppHamburgerDrawer(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Brand Logo Container
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(50),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          ),
                          child: const Icon(
                            Icons.table_rows_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // App Title
                  Text(
                    'PocketDesk',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  GestureDetector(
                    onTap: () {
                      if (isUnlocked) return;
                      setState(() => _versionClickCount++);
                      if (_versionClickCount >= 10) {
                        ref.read(shareTabUnlockedProvider.notifier).unlockShareTab();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 Share & Transfer Settings Unlocked!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else if (_versionClickCount >= 5) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tap ${10 - _versionClickCount} more times to unlock Share features.'),
                            duration: const Duration(milliseconds: 1000),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isUnlocked
                            ? 'v1.2.0 • Offline-First Ecosystem (Share Unlocked)'
                            : 'v1.2.0 • Offline-First Ecosystem',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'PocketDesk is a privacy-first, offline-first productivity hub made for people who want to plan, track, and organize their life online or offline.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Policy section header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Our Policy & Terms',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Policy Items Card Container
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                    ),
                    child: Column(
                      children: [
                        _buildPolicyTile(
                          context,
                          '1',
                          'Terms of Service',
                          icon: Icons.description_outlined,
                          onTap: () => context.push(AppRoutes.termsAndConditions),
                        ),
                        Divider(height: 1, color: colorScheme.outlineVariant.withAlpha(80)),
                        _buildPolicyTile(
                          context,
                          '2',
                          'Privacy Policy',
                          icon: Icons.shield_outlined,
                          onTap: () => context.push(AppRoutes.privacyPolicy),
                        ),
                        Divider(height: 1, color: colorScheme.outlineVariant.withAlpha(80)),
                        _buildPolicyTile(
                          context,
                          '3',
                          'Open Source Licenses',
                          icon: Icons.code_rounded,
                          trailingIcon: Icons.arrow_forward_ios_rounded,
                          onTap: () => context.push(AppRoutes.licenses),
                        ),
                      ],
                    ),
                  ),

                  // Online-only Logs Button
                  if (!_checkingOnline && _isOnline) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                        onPressed: () => _openWebUrl(_logsUrl),
                        icon: const Icon(Icons.receipt_long_rounded, size: 20),
                        label: const Text(
                          'View Live System Logs',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    '© 2026 PocketDesk — All Data Stored Locally',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyTile(
    BuildContext context,
    String number,
    String title, {
    required IconData icon,
    IconData? trailingIcon,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                trailingIcon ?? Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

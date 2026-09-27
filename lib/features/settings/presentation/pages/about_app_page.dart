import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file_plus/open_file_plus.dart';

import '../../../../core/theme/app_spacing.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  bool _isOnline = false;
  bool _checkingOnline = true;

  static const String _logsUrl =
      'https://raw.githubusercontent.com/Aaryanbanskota/Pocket-Desk/refs/heads/main/website/logs.html?token=GHSAT0AAAAAAEIYBMYEOAP22DFD5JVV4HIE2VYUQBA';
  static const String _termsUrl =
      'https://raw.githubusercontent.com/Aaryanbanskota/Pocket-Desk/main/TERMS_OF_SERVICE.md';
  static const String _privacyUrl =
      'https://raw.githubusercontent.com/Aaryanbanskota/Pocket-Desk/main/PRIVACY_POLICY.md';

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
      if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      } else {
        await OpenFile.open(url);
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            label: const Text('Back', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'App',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.send_rounded, color: Colors.white, size: 28),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Big App Brand Logo (Gi Icon)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withAlpha(50),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'P',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Title
                  Text(
                    'PocketDesk',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'PocketDesk is a privacy-first, offline-first productivity hub made for people who want to plan, track, and organize their life online or offline.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withAlpha(200),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Policy section header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Our policy and terms',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Policy Items
                  _buildPolicyTile('1', 'Terms of Service', onTap: () => _openWebUrl(_termsUrl)),
                  const SizedBox(height: 12),
                  _buildPolicyTile('2', 'Privacy Policy', onTap: () => _openWebUrl(_privacyUrl)),
                  const SizedBox(height: 12),
                  _buildPolicyTile(
                    '3',
                    'Open Source Licenses',
                    trailingIcon: Icons.send_rounded,
                    onTap: () => showLicensePage(context: context),
                  ),

                  // Online-only Logs Button
                  if (!_checkingOnline && _isOnline) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(30),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _openWebUrl(_logsUrl),
                        icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                        label: const Text('Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  Text(
                    '© 2026 PocketDesk — Built Offline-First',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withAlpha(140),
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

  Widget _buildPolicyTile(String number, String title, {IconData? trailingIcon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: trailingIcon != null ? Colors.white.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: trailingIcon == null ? Border.all(color: Colors.white.withAlpha(40)) : null,
        ),
        child: Row(
          children: [
            Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) => const _LegalDocumentPage(
        title: 'Terms and Conditions',
        sections: [
          (
            heading: 'Offline-first data ownership',
            body:
                'Your calendars, tasks, notes, wallets, AI API keys, and settings are stored locally on your device. PocketDesk does not host your personal data on cloud servers. You are responsible for preserving your data and credentials. Account deletion permanently removes local app data.',
          ),
          (
            heading: 'Device sync and local sharing',
            body:
                'Device-to-device synchronization uses encrypted connections over your local network. File sharing may start a temporary local network server; protect any PIN codes used to access shared files.',
          ),
          (
            heading: 'AI services and API keys',
            body:
                'Optional AI features send prompts directly from your device to the AI provider you configure, such as OpenRouter. You are responsible for following that provider’s terms. API keys are stored locally; PocketDesk does not proxy AI conversations.',
          ),
          (
            heading: 'Software license and updates',
            body:
                'PocketDesk is distributed under the MIT License. In-app update checks retrieve public release information and binaries from GitHub.',
          ),
          (
            heading: 'Support',
            body:
                'For questions or issue reporting, visit github.com/Aaryanbanskota/Pocket-Desk.',
          ),
        ],
      );
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) => const _LegalDocumentPage(
        title: 'Privacy Policy',
        sections: [
          (
            heading: 'Information collection',
            body:
                'PocketDesk does not collect, track, or sell personal data or usage analytics. Passwords and security recovery answers are hashed locally using Argon2id; plaintext passwords are not stored.',
          ),
          (
            heading: 'Network communication',
            body:
                'Update checks request public release information without sending personal identification data. Device synchronization takes place over your local network using encrypted connections.',
          ),
          (
            heading: 'AI and external services',
            body:
                'AI assistance is optional. When used, your prompt is sent directly from your device to the AI provider configured in the app. PocketDesk does not intercept or proxy those conversations.',
          ),
          (
            heading: 'Account deletion',
            body:
                'Settings → Privacy → Delete Account starts a two-step deletion process that removes local database data, encryption keys, and secure storage items.',
          ),
          (
            heading: 'Policy updates and contact',
            body:
                'This policy may change with future releases. Questions and issues can be raised at github.com/Aaryanbanskota/Pocket-Desk.',
          ),
        ],
      );
}

class PocketDeskLicensesPage extends StatelessWidget {
  const PocketDeskLicensesPage({super.key});

  @override
  Widget build(BuildContext context) => const LicensePage(
        applicationName: 'PocketDesk',
        applicationVersion: '1.2.0',
      );
}

class _LegalDocumentPage extends StatelessWidget {
  const _LegalDocumentPage({required this.title, required this.sections});

  final String title;
  final List<({String heading, String body})> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Last updated: September 27, 2026',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          for (final section in sections) ...[
            Text(
              section.heading,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(section.body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

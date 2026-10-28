import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) => const _LegalDocumentPage(
        title: 'Terms of Service',
        sections: [
          (
            heading: '1. Acceptance of Terms',
            body:
                'By creating an account (Local or Cloud) or using MyDay (v1.2.2), you agree to these Terms of Service. If you do not agree with any part of these terms, you may not use the application.',
          ),
          (
            heading: '2. Offline-First Data & User Ownership',
            body:
                'MyDay is designed offline-first. Your personal calendars, tasks, notes, documents, voice memos, and settings are saved securely on your local device. In Cloud Mode, your account credentials and encrypted data are synced using Supabase. You maintain full ownership of all data you create.',
          ),
          (
            heading: '3. System Permissions & Device Access',
            body:
                'MyDay requests device permissions strictly to power specific user features:\n'
                '• Microphone: Used for recording Voice to Notes, voice memos, and live calling features. Spoken audio is never recorded in the background.\n'
                '• Camera: Used for scanning login/pairing QR codes and capturing photos to attach to notes and feeds.\n'
                '• Storage & Photos: Used for selecting and attaching documents, images, and audio files to your notes and tasks.\n'
                '• Location: Used solely for retrieving local weather information and location tagging if chosen by the user.\n'
                '• Notifications & Alarms: Used for timely alerts, reminders, calendar notifications, and incoming call rings.\n'
                'Permissions are requested explicitly and can be revoked at any time in your system settings.',
          ),
          (
            heading: '4. Voice-to-Note & Speech Recognition',
            body:
                'The Voice to Note tool transcribes spoken words directly into text. It operates without requiring third-party AI LLMs. Transcription audio is processed ephemerally and is not permanently stored or monetized on any external servers.',
          ),
          (
            heading: '5. Calling & Messaging Services',
            body:
                'MyDay offers real-time calling and messaging capabilities powered by Socket.io and Supabase signaling. Communication signals are transmitted ephemerally to connect peer calls. MyDay does not wiretap, record, or store private phone conversations.',
          ),
          (
            heading: '6. Account Security & Responsibilities',
            body:
                'You are responsible for safeguarding your 4-digit PIN, passwords, and biometric credentials. Resetting or deleting your local account permanently erases the local cryptographic keys and databases from your device.',
          ),
          (
            heading: '7. Software License & Support',
            body:
                'MyDay is open-source productivity software distributed under the MIT License. For updates, support, or bug reports, please visit github.com/Aaryanbanskota/Pocket-Desk.',
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
            heading: '1. No Personal Data Selling or Tracking',
            body:
                'MyDay is built with privacy as a foundational principle. We do not track user behavior, run analytics, build advertising profiles, or sell any personal data.',
          ),
          (
            heading: '2. Local-First Storage & Encryption',
            body:
                'Your notes, tasks, finances, and voice memos are stored on your local device storage. Sensitive authentication credentials like local PINs and passwords are protected using industry-standard Argon2id hashing and PBKDF2 cryptography; plaintext passwords are never stored.',
          ),
          (
            heading: '3. Audio & Voice Data Privacy',
            body:
                'Microphone access is active only while you are explicitly recording a voice memo or during an active voice call. Voice audio is not sent to AI models for profiling or training. When Voice to Note converts speech to text, audio transmission is ephemeral solely for the transcription request.',
          ),
          (
            heading: '4. Location & Sensor Privacy',
            body:
                'Location coordinates are queried only upon request (e.g. for fetching weather reports or user-initiated post tags). Location data is never broadcast, logged in background trackers, or sold to third parties.',
          ),
          (
            heading: '5. Real-Time Calling & Socket Signals',
            body:
                'When you place or receive a call in MyDay, call signaling messages (such as ring invites and end-call signals) are transmitted over secure WebSockets. No audio streams are recorded or stored on any server.',
          ),
          (
            heading: '6. Data Deletion & Export',
            body:
                'You have the complete right to delete your data at any time. Under Settings → Privacy, you can reset your local database, remove all cached audio, or delete your account with immediate and irreversible effect.',
          ),
          (
            heading: '7. Privacy Inquiries & Policy Changes',
            body:
                'We may update this policy to reflect new capabilities. Transparent change logs and source code remain publicly available at github.com/Aaryanbanskota/Pocket-Desk.',
          ),
        ],
      );
}

class PocketDeskLicensesPage extends StatelessWidget {
  const PocketDeskLicensesPage({super.key});

  @override
  Widget build(BuildContext context) => const LicensePage(
        applicationName: 'MyDay',
        applicationVersion: '1.2.2',
      );
}

class _LegalDocumentPage extends StatelessWidget {
  const _LegalDocumentPage({required this.title, required this.sections});

  final String title;
  final List<({String heading, String body})> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'MyDay v1.2.2 • Last updated: October 2026',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            for (final section in sections) ...[
              Text(
                section.heading,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                section.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}


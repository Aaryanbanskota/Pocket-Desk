import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../chat/presentation/widgets/ai_chef_mascot_widget.dart';

class OnboardingStep {
  OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.featureHighlights,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<String> featureHighlights;
}

class SetupOnboardingPage extends StatefulWidget {
  const SetupOnboardingPage({super.key});

  @override
  State<SetupOnboardingPage> createState() => _SetupOnboardingPageState();
}

class _SetupOnboardingPageState extends State<SetupOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Welcome to Pocketdesk! ✨',
      subtitle: 'Your All-in-One Productivity & Workspace Hub',
      description: 'Pocketdesk brings together your Clock, Tasks, Calendar, Notes, Money Tracker, P2P File Sharing, and AI Companion in one place.',
      icon: Icons.auto_awesome_rounded,
      featureHighlights: [
        'Organize your day with responsive Calendar & Tasks',
        'Track daily expenses with instant AI Money Health reports',
        'Share files directly peer-to-peer across your devices',
      ],
    ),
    OnboardingStep(
      title: 'Clock & Timers ⏰',
      subtitle: 'Alarms, World Clock, Timers & Stopwatch',
      description: 'Set custom alarms, countdown timers with notifications, and track elapsed time with high accuracy on Mobile & Desktop.',
      icon: Icons.access_time_filled_rounded,
      featureHighlights: [
        'Add alarms with custom labels and repeat schedules',
        'Set minute/second countdown timers with audio & push alerts',
        'Use stopwatch for productivity and sprint timing',
      ],
    ),
    OnboardingStep(
      title: 'Money Tracker 💰',
      subtitle: 'Smart Finances & AI Health Reports',
      description: 'Manage your monthly budget, record expenses by category, and view styled AI Money Reports.',
      icon: Icons.account_balance_wallet_rounded,
      featureHighlights: [
        'Track spent vs. remaining starting balance',
        'View spending score out of 100 and spending status',
        'Get automated AI suggestions to optimize next month\'s savings',
      ],
    ),
    OnboardingStep(
      title: 'P2P File Share 📁',
      subtitle: 'Direct Offline & Online File Transfer',
      description: 'Transfer photos, documents, and archives directly between your phones, tablets, and laptops without cloud limits.',
      icon: Icons.folder_shared_rounded,
      featureHighlights: [
        'Connect via local Wi-Fi pairing or P2P Device ID',
        'High-speed encrypted file sending',
        'Access system file manager anytime',
      ],
    ),
    OnboardingStep(
      title: 'AI Companion & Chat 🤖',
      subtitle: 'Ask Pocketdesk AI for Help Anytime!',
      description: 'You can chat 24/7 with Pocketdesk AI! Ask it for help finding features, managing your calendar, analyzing spending, or summarizing notes.',
      icon: Icons.chat_rounded,
      featureHighlights: [
        'Chat with AI companion anytime in the Chat tab',
        'Ask how to use any feature or locate app tools',
        'Get instant intelligent answers across your workspace',
      ],
    ),
    OnboardingStep(
      title: 'Enable AI Feature 🔑',
      subtitle: 'Step-by-Step OpenRouter Setup',
      description: 'Follow these quick steps to get your free API key and activate Pocketdesk AI:',
      icon: Icons.vpn_key_rounded,
      featureHighlights: [
        '1. Go to https://openrouter.ai/ and login or register',
        '2. Click "Get API" → "Create Key"',
        '3. Fill in Key Name & Expiration Date (leave rest blank) → click Create',
        '4. Copy the API key, go to Settings → AI in Pocketdesk',
        '5. Paste the key into OpenRouter Key field & click Save Key',
        'Hooray! 🎉 You are now 100% ready to use Pocketdesk AI!',
      ],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const AiChefMascotWidget(size: 28, animate: true),
                      const SizedBox(width: 8),
                      Text('Pocketdesk Setup', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.dashboard),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Skip Setup'),
                  ),
                ],
              ),
            ),

            // Main Page Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(step.icon, size: 54, color: cs.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step.title,
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          step.subtitle,
                          style: theme.textTheme.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step.description,
                          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Feature bullet highlights
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: step.featureHighlights.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Indicators & Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots indicator
                  Row(
                    children: List.generate(_steps.length, (idx) {
                      final isActive = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? cs.primary : cs.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started Button
                  FilledButton.icon(
                    onPressed: _nextPage,
                    icon: Icon(_currentPage == _steps.length - 1 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded),
                    label: Text(_currentPage == _steps.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketdesk/features/settings/presentation/providers/ai_settings_notifier.dart';

/// A custom mascot widget representing the Pocket AI Chef/Cloud mascot.
/// Inspired by the vibrant scalloped mascot silhouette with twin vertical capsule eyes.
class AiChefMascotWidget extends StatefulWidget {
  final double size;
  final Color? color;
  final Color? eyeColor;
  final bool animate;

  const AiChefMascotWidget({
    super.key,
    this.size = 32,
    this.color,
    this.eyeColor,
    this.animate = true,
  });

  @override
  State<AiChefMascotWidget> createState() => _AiChefMascotWidgetState();
}

class _AiChefMascotWidgetState extends State<AiChefMascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (widget.animate && !isTest) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AiChefMascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      final isTest = Platform.environment.containsKey('FLUTTER_TEST');
      if (widget.animate && !isTest) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mascotColor = widget.color ?? const Color(0xFF00E676);
    final eyeColor = widget.eyeColor ?? theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatOffset = widget.animate
            ? math.sin(_controller.value * math.pi) * (widget.size * 0.04)
            : 0.0;
        final scalePulse = widget.animate
            ? 1.0 + math.sin(_controller.value * math.pi) * 0.02
            : 1.0;

        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: Transform.scale(
            scale: scalePulse,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _AiChefMascotPainter(
                mascotColor: mascotColor,
                eyeColor: eyeColor,
                animValue: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AiChefMascotPainter extends CustomPainter {
  final Color mascotColor;
  final Color eyeColor;
  final double animValue;

  _AiChefMascotPainter({
    required this.mascotColor,
    required this.eyeColor,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Paints
    final bodyPaint = Paint()
      ..color = mascotColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Draw Bottom Stand / Base Bar
    final baseBarHeight = h * 0.10;
    final baseBarWidth = w * 0.55;
    final baseBarRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.92),
        width: baseBarWidth,
        height: baseBarHeight,
      ),
      Radius.circular(baseBarHeight / 2),
    );
    canvas.drawRRect(baseBarRRect, bodyPaint);

    // 2. Draw Chef / Cloud Scalloped Head
    final headPath = Path();
    final center = Offset(w * 0.5, h * 0.44);

    // Head base boundary
    final headRect = Rect.fromCenter(
      center: center,
      width: w * 0.88,
      height: h * 0.72,
    );

    // Main rounded head base
    headPath.addRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.28)),
    );

    // Top cloud puffy lobes (Scalloped chef hat shape)
    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.50, h * 0.22),
      radius: w * 0.26,
    ));

    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.28, h * 0.28),
      radius: w * 0.22,
    ));

    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.72, h * 0.28),
      radius: w * 0.22,
    ));

    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.18, h * 0.48),
      radius: w * 0.18,
    ));

    headPath.addOval(Rect.fromCircle(
      center: Offset(w * 0.82, h * 0.48),
      radius: w * 0.18,
    ));

    canvas.drawPath(headPath, bodyPaint);

    // 3. Draw Vertical Capsule Eyes
    final eyeWidth = w * 0.12;
    final eyeHeight = h * 0.26;
    final eyeY = h * 0.42;

    final leftEyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.38, eyeY),
        width: eyeWidth,
        height: eyeHeight,
      ),
      Radius.circular(eyeWidth / 2),
    );

    final rightEyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.62, eyeY),
        width: eyeWidth,
        height: eyeHeight,
      ),
      Radius.circular(eyeWidth / 2),
    );

    canvas.drawRRect(leftEyeRect, eyePaint);
    canvas.drawRRect(rightEyeRect, eyePaint);
  }

  @override
  bool shouldRepaint(_AiChefMascotPainter oldDelegate) {
    return oldDelegate.mascotColor != mascotColor ||
        oldDelegate.eyeColor != eyeColor ||
        oldDelegate.animValue != animValue;
  }
}

/// Helper to trigger the interactive Pocket AI Mascot dialog anywhere in desktop or mobile.
void showPocketAiMascotDialog(BuildContext context, WidgetRef ref, {String? initialText}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => PocketAiMascotDialog(initialText: initialText),
  );
}

/// Helper function to construct a custom text selection menu item for "Call Pocket AI"
Widget buildPocketAiSelectionToolbar(
  BuildContext context,
  SelectableRegionState selectableRegionState,
  WidgetRef ref,
) {
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: selectableRegionState.contextMenuAnchors,
    buttonItems: [
      ...selectableRegionState.contextMenuButtonItems,
      ContextMenuButtonItem(
        label: 'Call Pocket AI 🤖',
        onPressed: () {
          selectableRegionState.hideToolbar();
          showPocketAiMascotDialog(context, ref);
        },
      ),
    ],
  );
}

class PocketAiMascotDialog extends ConsumerStatefulWidget {
  final String? initialText;

  const PocketAiMascotDialog({super.key, this.initialText});

  @override
  ConsumerState<PocketAiMascotDialog> createState() => _PocketAiMascotDialogState();
}

class _PocketAiMascotDialogState extends ConsumerState<PocketAiMascotDialog> {
  final TextEditingController _promptCtrl = TextEditingController();
  final List<({String sender, String message})> _conversation = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final text = widget.initialText?.trim();
    if (text != null && text.isNotEmpty) {
      _conversation.add((
        sender: 'mascot',
        message: 'Yo! I see you selected:\n"$text"\n\nWhat can I help you explain or do with this?'
      ));
    } else {
      _conversation.add((
        sender: 'mascot',
        message: 'Yo! I\'m your Pocket AI mascot! 🤖 What can I help you with today?'
      ));
    }
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _promptCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _conversation.add((sender: 'user', message: text));
      _promptCtrl.clear();
      _isLoading = true;
    });

    const systemPrompt =
        'You are Pocketdesk Mascot AI 🤖. You are a friendly, fun, super helpful companion inspired by Duolingo mascot. Keep your responses engaging, clear, concise (2-4 sentences), and friendly!';

    final fullPrompt = widget.initialText != null && widget.initialText!.isNotEmpty
        ? 'Selected text context: "${widget.initialText}"\nUser question: $text'
        : text;

    final response = await ref
        .read(aiSettingsProvider.notifier)
        .generateCompletion(prompt: fullPrompt, systemPrompt: systemPrompt);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response != null && response.isNotEmpty) {
        _conversation.add((sender: 'mascot', message: response));
      } else {
        _conversation.add((
          sender: 'mascot',
          message:
              'Oops! Pocket AI is disabled or needs an API key in Settings → AI. Turn it on to chat!'
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: math.min(MediaQuery.of(context).size.width * 0.9, 440),
        padding: const EdgeInsets.all(20),
        child: SelectionArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with animated Mascot
              Row(
                children: [
                  const AiChefMascotWidget(size: 48, animate: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pocket AI Mascot 🤖',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Your instant desktop & mobile assistant',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Chat conversation box
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final msg in _conversation)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Align(
                            alignment: msg.sender == 'user'
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: msg.sender == 'user'
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                msg.message,
                                style: TextStyle(
                                  color: msg.sender == 'user'
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              AiChefMascotWidget(size: 20, animate: true),
                              SizedBox(width: 8),
                              Text('Mascot is thinking...'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Input Field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promptCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ask Pocket AI mascot anything...',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

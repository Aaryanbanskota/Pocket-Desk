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
  late String _speechText;
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    final text = widget.initialText?.trim();
    if (text != null && text.isNotEmpty) {
      _speechText = 'Yo! I see you selected:\n"$text"\n\nWhat can I help you with?';
    } else {
      _speechText = 'Yo! I\'m your Pocket Assistant! 🤖 What can I help you with today?';
    }
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final userText = _promptCtrl.text.trim();
    if (userText.isEmpty || _isThinking) return;

    setState(() {
      _promptCtrl.clear();
      _isThinking = true;
    });

    const systemPrompt =
        'You are Pocket Assistant 🤖. You are a friendly, fun, super helpful companion inspired by Duolingo mascot. Keep your responses engaging, clear, concise (2-3 sentences), and friendly!';

    final fullPrompt = widget.initialText != null && widget.initialText!.isNotEmpty
        ? 'Selected text context: "${widget.initialText}"\nUser question: $userText'
        : userText;

    final response = await ref
        .read(aiSettingsProvider.notifier)
        .generateCompletion(prompt: fullPrompt, systemPrompt: systemPrompt);

    if (!mounted) return;

    setState(() {
      _isThinking = false;
      if (response != null && response.isNotEmpty) {
        _speechText = response;
      } else {
        _speechText =
            'Pocket AI is currently turned off or needs an API key in Settings → AI. Turn it on to chat!';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SelectionArea(
        child: Container(
          width: math.min(MediaQuery.of(context).size.width * 0.9, 400),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button top right
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              // Mascot Avatar (Profile Picture standing cleanly)
              const AiChefMascotWidget(size: 76, animate: true),
              const SizedBox(height: 16),
              // Speech Box containing Mascot speech or "Pocket Assistant is thinking..."
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isThinking
                      ? Row(
                          key: const ValueKey('thinking'),
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Pocket Assistant is thinking...',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _speechText,
                          key: ValueKey(_speechText),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Input Field (click and type, clears after submitting)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promptCtrl,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        isDense: true,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
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

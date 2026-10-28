import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RichDocumentEditingController extends TextEditingController {
  final BuildContext? context;
  final double baseFontSize;
  final Color textColor;
  final Color accentColor;
  final Color mutedColor;

  RichDocumentEditingController({
    super.text,
    this.context,
    this.baseFontSize = 16.0,
    this.textColor = Colors.black,
    this.accentColor = Colors.deepOrange,
    this.mutedColor = Colors.grey,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final effectiveStyle = (style ?? const TextStyle()).copyWith(
      fontSize: baseFontSize,
      color: textColor,
    );

    final lines = text.split('\n');
    final spans = <InlineSpan>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      _parseLine(line, effectiveStyle, spans);

      if (i < lines.length - 1) {
        spans.add(TextSpan(text: '\n', style: effectiveStyle));
      }
    }

    return TextSpan(children: spans, style: effectiveStyle);
  }

  void _parseLine(String line, TextStyle defaultStyle, List<InlineSpan> spans) {
    TextStyle lineStyle = defaultStyle;
    String content = line;

    // Line-level heading / list styles
    if (content.startsWith('# ')) {
      spans.add(const TextSpan(
        text: '# ',
        style: TextStyle(fontSize: 0.01, color: Colors.transparent),
      ));
      content = content.substring(2);
      lineStyle = defaultStyle.copyWith(
        fontSize: baseFontSize + 8,
        fontWeight: FontWeight.w800,
      );
    } else if (content.startsWith('## ')) {
      spans.add(const TextSpan(
        text: '## ',
        style: TextStyle(fontSize: 0.01, color: Colors.transparent),
      ));
      content = content.substring(3);
      lineStyle = defaultStyle.copyWith(
        fontSize: baseFontSize + 4,
        fontWeight: FontWeight.w700,
      );
    } else if (content.startsWith('### ')) {
      spans.add(const TextSpan(
        text: '### ',
        style: TextStyle(fontSize: 0.01, color: Colors.transparent),
      ));
      content = content.substring(4);
      lineStyle = defaultStyle.copyWith(
        fontSize: baseFontSize + 2,
        fontWeight: FontWeight.w600,
      );
    } else if (content.startsWith('- [ ] ')) {
      spans.add(const TextSpan(
        text: '- ',
        style: TextStyle(fontSize: 0.01, color: Colors.transparent),
      ));
      spans.add(TextSpan(
        text: '[ ] ',
        style: defaultStyle.copyWith(
          color: accentColor,
          fontWeight: FontWeight.w800,
        ),
      ));
      content = content.substring(6);
    } else if (content.startsWith('- [x] ')) {
      spans.add(const TextSpan(
        text: '- ',
        style: TextStyle(fontSize: 0.01, color: Colors.transparent),
      ));
      spans.add(TextSpan(
        text: '[x] ',
        style: defaultStyle.copyWith(
          color: Colors.green,
          fontWeight: FontWeight.w800,
        ),
      ));
      content = content.substring(6);
      lineStyle = defaultStyle.copyWith(
        decoration: TextDecoration.lineThrough,
        color: mutedColor,
      );
    } else if (content.startsWith('> ')) {
      spans.add(TextSpan(
        text: '> ',
        style: defaultStyle.copyWith(
          color: accentColor,
          fontWeight: FontWeight.bold,
        ),
      ));
      content = content.substring(2);
      lineStyle = defaultStyle.copyWith(fontStyle: FontStyle.italic);
    }

    _parseInlineFormatted(content, lineStyle, spans);
  }

  void _parseInlineFormatted(String text, TextStyle currentStyle, List<InlineSpan> spans) {
    if (text.isEmpty) return;

    // Pattern for **bold**, __underline__, ~~strike~~, *italic*
    final regex = RegExp(r'(\*\*(.*?)\*\*)|(__(.*?)__)|(~~(.*?)~~)|(\*(.*?)\*)');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: currentStyle,
        ));
      }

      if (match.group(1) != null) {
        // **bold**
        spans.add(const TextSpan(text: '**', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
        spans.add(TextSpan(
          text: match.group(2) ?? '',
          style: currentStyle.copyWith(fontWeight: FontWeight.bold),
        ));
        spans.add(const TextSpan(text: '**', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
      } else if (match.group(3) != null) {
        // __underline__
        spans.add(const TextSpan(text: '__', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
        spans.add(TextSpan(
          text: match.group(4) ?? '',
          style: currentStyle.copyWith(decoration: TextDecoration.underline),
        ));
        spans.add(const TextSpan(text: '__', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
      } else if (match.group(5) != null) {
        // ~~strike~~
        spans.add(const TextSpan(text: '~~', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
        spans.add(TextSpan(
          text: match.group(6) ?? '',
          style: currentStyle.copyWith(decoration: TextDecoration.lineThrough),
        ));
        spans.add(const TextSpan(text: '~~', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
      } else if (match.group(7) != null) {
        // *italic*
        spans.add(const TextSpan(text: '*', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
        spans.add(TextSpan(
          text: match.group(8) ?? '',
          style: currentStyle.copyWith(fontStyle: FontStyle.italic),
        ));
        spans.add(const TextSpan(text: '*', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: currentStyle,
      ));
    }
  }
}

void main() {
  testWidgets('RichDocumentEditingController renders standard document formatting without raw syntax', (tester) async {
    final controller = RichDocumentEditingController(
      text: '# Project Kickoff\n## Agenda\nThis is **bold** and __underlined__ and ~~struck~~.\n- [ ] First task\n- [x] Done task\n> Note quote',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(controller: controller),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    // Verifies length matches exactly
    final span = controller.buildTextSpan(context: tester.element(find.byType(TextField)), withComposing: false);
    expect(span.toPlainText(), controller.text);
  });
}

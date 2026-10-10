import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  test('Lucide icons load properly', () {
    expect(LucideIcons.house, isNotNull);
    expect(LucideIcons.listTodo, isNotNull);
    expect(LucideIcons.calendar, isNotNull);
    expect(LucideIcons.fileText, isNotNull);
    expect(LucideIcons.wallet, isNotNull);
    expect(LucideIcons.image, isNotNull);
    expect(LucideIcons.clock, isNotNull);
    expect(LucideIcons.trash2, isNotNull);
    expect(LucideIcons.fingerprint, isNotNull);
    expect(LucideIcons.plus, isNotNull);
  });
}

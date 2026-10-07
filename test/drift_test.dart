import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

void main() {
  test('Drift in-memory sqlite test', () async {
    final db = NativeDatabase.memory();
    expect(db, isNotNull);
  });
}

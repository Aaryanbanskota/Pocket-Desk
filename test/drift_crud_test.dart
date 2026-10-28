import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';

class TestDb extends GeneratedDatabase {
  TestDb(QueryExecutor e) : super(e);
  
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => [];
  
  @override
  int get schemaVersion => 1;

  Future<void> initSchema() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS my_tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0,
        due_date TEXT NOT NULL
      );
    ''');
  }
}

void main() {
  test('Drift custom schema and statements execute reliably', () async {
    final db = TestDb(NativeDatabase.memory());
    await db.initSchema();
    
    // Insert
    await db.customInsert(
      'INSERT INTO my_tasks (id, title, is_done, due_date) VALUES (?, ?, ?, ?)',
      variables: [Variable('1'), Variable('Buy milk'), Variable(0), Variable('2026-10-18')],
    );

    // Query
    final rows = await db.customSelect('SELECT * FROM my_tasks WHERE id = ?', variables: [Variable('1')]).get();
    expect(rows.length, 1);
    expect(rows.first.read<String>('title'), 'Buy milk');
    expect(rows.first.read<int>('is_done'), 0);

    // Update
    await db.customUpdate(
      'UPDATE my_tasks SET is_done = 1 WHERE id = ?',
      variables: [Variable('1')],
    );
    final updated = await db.customSelect('SELECT is_done FROM my_tasks WHERE id = ?', variables: [Variable('1')]).getSingle();
    expect(updated.read<int>('is_done'), 1);

    await db.close();
  });
}

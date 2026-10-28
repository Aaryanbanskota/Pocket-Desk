import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketdesk/core/database/myday_database.dart';
import 'package:pocketdesk/features/auth/data/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('MyDayDatabase initializes and executes queries without error', () async {
    final db = MyDayDatabase.create(inMemory: true);
    await db.initDatabase();

    final repo = AuthRepository(db);
    final existing = await repo.getExistingLocalAccount();
    expect(existing, isNull);

    final lastCloud = await repo.getLastCloudSession();
    expect(lastCloud, isNull);

    await db.close();
  });
}

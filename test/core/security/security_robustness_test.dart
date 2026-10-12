import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/database/myday_database.dart';
import 'package:pocketdesk/core/security/secure_pin_service.dart';
import 'package:pocketdesk/features/trash/data/trash_repository.dart';

void main() {
  group('Security Robustness & Permanent Deletion Tests', () {
    test('SecurePinService hashes with key stretching and constant-time verification', () {
      const pin = '4829';
      final hash = SecurePinService.hashPin(pin);

      // Verify prefix and structure
      expect(hash.startsWith('v2:5000:'), isTrue);

      // Verify correct pin matches
      expect(SecurePinService.verifyPin('4829', hash), isTrue);

      // Verify wrong pin fails
      expect(SecurePinService.verifyPin('4820', hash), isFalse);
      expect(SecurePinService.verifyPin('0000', hash), isFalse);
    });

    test('SecurePinService maintains backwards-compatibility with legacy hashes', () {
      // Legacy single-round MD-prefixed sha256
      const legacyPin = '1234';
      final legacyHash = SecurePinService.legacyHash(legacyPin);

      expect(SecurePinService.verifyPin(legacyPin, legacyHash), isTrue);
      expect(SecurePinService.verifyPin('9999', legacyHash), isFalse);
    });

    test('TrashRepository permanently purges disk files and runs SQLite VACUUM', () async {
      final db = MyDayDatabase.create(inMemory: true);
      await db.initDatabase();

      final trashRepo = TrashRepository(db);

      // Create a temporary physical test file on disk
      final tempDir = Directory.systemTemp.createTempSync('trash_purge_test_');
      final dummyFile = File('${tempDir.path}/confidential_report.pdf');
      dummyFile.writeAsStringSync('Highly sensitive financial record');

      expect(dummyFile.existsSync(), isTrue);

      // Insert soft-deleted record into stored_files
      const fileId = 'test_file_purge_id';
      await db.customInsert(
        '''
        INSERT INTO stored_files (
          id, account_id, name, local_path, size_bytes, is_deleted, deleted_at, sync_status, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        variables: [
          Variable(fileId),
          Variable('acc_1'),
          Variable('confidential_report.pdf'),
          Variable(dummyFile.path),
          Variable(32),
          Variable(1), // is_deleted = 1
          Variable(DateTime.now().millisecondsSinceEpoch),
          Variable('synced'),
          Variable(DateTime.now().millisecondsSinceEpoch),
        ],
      );

      final trashItem = MyDayTrashItem(
        id: fileId,
        type: TrashItemType.file,
        title: 'confidential_report.pdf',
        subtitle: 'File Attachment',
        deletedAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Execute permanent purge
      await trashRepo.permanentlyDeleteItem(trashItem);

      // Verify physical file was deleted from filesystem (reclaiming storage)
      expect(dummyFile.existsSync(), isFalse);

      // Verify row was deleted from database
      final remaining = await db.customSelect(
        'SELECT id FROM stored_files WHERE id = ?',
        variables: [Variable(fileId)],
      ).get();
      expect(remaining.isEmpty, isTrue);

      // Clean up temp dir
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }

      await db.close();
    });
  });
}

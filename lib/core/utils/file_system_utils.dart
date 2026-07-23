import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../logging/app_logger.dart';

/// File system helper utilities for PocketDesk.
abstract final class FileSystemUtils {
  /// Returns the app's documents directory (persistent user data).
  static Future<Directory> getAppDocumentsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/pocketdesk');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Returns the app's cache directory (temporary files).
  static Future<Directory> getAppCacheDir() async {
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/pocketdesk');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Returns a sub-directory within app documents, creating it if needed.
  static Future<Directory> getSubDir(String name) async {
    final base = await getAppDocumentsDir();
    final dir = Directory('${base.path}/$name');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Writes [bytes] to a file, creating parent directories as needed.
  static Future<File> writeBytes(String path, List<int> bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    return file.writeAsBytes(bytes);
  }

  /// Reads a file as bytes. Returns null if the file doesn't exist.
  static Future<List<int>?> readBytes(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsBytes();
  }

  /// Safely deletes a file, logging any errors.
  static Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (e, st) {
      AppLogger.w('Failed to delete file: $path', error: e, st: st);
    }
  }

  /// Returns file size in bytes, or 0 if the file doesn't exist.
  static int fileSize(String path) {
    final file = File(path);
    return file.existsSync() ? file.lengthSync() : 0;
  }

  /// Returns human-readable file size string.
  static String readableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

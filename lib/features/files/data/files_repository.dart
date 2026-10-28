import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/myday_database.dart';

class MyDayFile {
  final String id;
  final String accountId;
  final String uploaderName;
  final String uploaderPhone;
  final String name;
  final int sizeBytes;
  final String localPath;
  final String fileUrl;
  final String shareType; // 'everyone', 'private', 'friends'
  final String pin;
  final String friendPhoneNumber;
  final String? sharePassword;
  final List<String> sharedWith;
  final int createdAt;

  const MyDayFile({
    required this.id,
    required this.accountId,
    this.uploaderName = 'Me',
    this.uploaderPhone = '',
    required this.name,
    required this.sizeBytes,
    required this.localPath,
    this.fileUrl = '',
    this.shareType = 'everyone',
    this.pin = '',
    this.friendPhoneNumber = '',
    this.sharePassword,
    this.sharedWith = const [],
    required this.createdAt,
  });

  bool get isEveryone => shareType == 'everyone' || shareType == 'public';
  bool get isPrivate => shareType == 'private';
  bool get isFriends => shareType == 'friends';
  bool get isPublic => isEveryone;
  bool get hasPassword => pin.isNotEmpty || (sharePassword != null && sharePassword!.isNotEmpty);

  factory MyDayFile.fromRow(QueryRow row) {
    List<String> friends = [];
    try {
      final jsonStr = row.readNullable<String>('shared_with_json');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          friends = decoded.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}

    final rawShare = row.readNullable<String>('share_type') ?? 'everyone';
    final normalizedShare = rawShare == 'public' ? 'everyone' : rawShare;

    return MyDayFile(
      id: row.read<String>('id'),
      accountId: row.read<String>('account_id'),
      uploaderName: row.readNullable<String>('uploader_name') ?? 'Me',
      uploaderPhone: row.readNullable<String>('uploader_phone') ?? '',
      name: row.read<String>('name'),
      sizeBytes: row.read<int>('size_bytes'),
      localPath: row.read<String>('local_path'),
      fileUrl: row.readNullable<String>('file_url') ?? '',
      shareType: normalizedShare,
      pin: row.readNullable<String>('pin') ?? (row.readNullable<String>('share_password') ?? ''),
      friendPhoneNumber: row.readNullable<String>('friend_phone_number') ?? '',
      sharePassword: row.readNullable<String>('share_password'),
      sharedWith: friends,
      createdAt: row.read<int>('created_at'),
    );
  }

  factory MyDayFile.fromSupabase(Map<String, dynamic> json) {
    int createdMs = DateTime.now().millisecondsSinceEpoch;
    if (json['created_at'] != null) {
      try {
        createdMs = DateTime.parse(json['created_at'].toString()).millisecondsSinceEpoch;
      } catch (_) {}
    }

    final rawShare = json['share_type']?.toString() ?? 'everyone';
    final normalizedShare = rawShare == 'public' ? 'everyone' : rawShare;

    return MyDayFile(
      id: json['id']?.toString() ?? '',
      accountId: json['user_id']?.toString() ?? '',
      uploaderName: json['uploader_name']?.toString() ?? 'Pocketdesk User',
      uploaderPhone: json['uploader_phone']?.toString() ?? '',
      name: json['name']?.toString() ?? 'File',
      sizeBytes: (json['size_bytes'] is num) ? (json['size_bytes'] as num).toInt() : 0,
      localPath: '',
      fileUrl: json['file_url']?.toString() ?? '',
      shareType: normalizedShare,
      pin: json['pin']?.toString() ?? '',
      friendPhoneNumber: json['friend_phone_number']?.toString() ?? '',
      createdAt: createdMs,
    );
  }
}

class FilesRepository {
  final MyDayDatabase db;
  static const _uuid = Uuid();
  static const String bucketName = 'files_bucket';

  FilesRepository(this.db);

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password.trim())).toString();
  }

  bool verifyFilePassword(MyDayFile file, String enteredPassword) {
    if (!file.hasPassword) return true;
    final clean = enteredPassword.trim();
    if (file.pin.isNotEmpty && file.pin == clean) return true;
    final hashed = hashPassword(clean);
    return file.sharePassword == hashed || file.sharePassword == clean;
  }

  /// Get local user's own uploaded files
  Future<List<MyDayFile>> getFiles(String accountId) async {
    final rows = await db.customSelect(
      'SELECT * FROM stored_files WHERE account_id = ? AND is_deleted = 0 ORDER BY created_at DESC',
      variables: [Variable(accountId)],
    ).get();

    return rows.map(MyDayFile.fromRow).toList();
  }

  /// Fetch Everyone (Public) files from Supabase cloud
  Future<List<MyDayFile>> getEveryoneFiles() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('stored_files')
          .select()
          .eq('share_type', 'everyone')
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(60);

      final list = (response as List)
          .map((e) => MyDayFile.fromSupabase(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      // Fallback to local SQLite if offline
      final rows = await db.customSelect(
        "SELECT * FROM stored_files WHERE share_type IN ('everyone', 'public') AND is_deleted = 0 ORDER BY created_at DESC",
      ).get();
      return rows.map(MyDayFile.fromRow).toList();
    }
  }

  /// Fetch Friends Shared files sent specifically to user's phone number
  Future<List<MyDayFile>> getFriendsFiles(String myPhoneNumber) async {
    final cleanPhone = myPhoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) return [];

    final target10 = cleanPhone.length >= 10
        ? cleanPhone.substring(cleanPhone.length - 10)
        : cleanPhone;

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('stored_files')
          .select()
          .eq('share_type', 'friends')
          .eq('is_deleted', false)
          .ilike('friend_phone_number', '%$target10%')
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((e) => MyDayFile.fromSupabase(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      final rows = await db.customSelect(
        "SELECT * FROM stored_files WHERE share_type = 'friends' AND friend_phone_number LIKE ? AND is_deleted = 0 ORDER BY created_at DESC",
        variables: [Variable('%$target10%')],
      ).get();
      return rows.map(MyDayFile.fromRow).toList();
    }
  }

  /// Retrieve a private PIN-locked file from Supabase by entering PIN
  Future<MyDayFile?> getFileByPin(String pin) async {
    final cleanPin = pin.trim();
    if (cleanPin.isEmpty) return null;

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('stored_files')
          .select()
          .eq('share_type', 'private')
          .eq('pin', cleanPin)
          .eq('is_deleted', false)
          .limit(1);

      final list = response as List;
      if (list.isEmpty) return null;
      return MyDayFile.fromSupabase(list.first as Map<String, dynamic>);
    } catch (e) {
      final rows = await db.customSelect(
        "SELECT * FROM stored_files WHERE share_type = 'private' AND (pin = ? OR share_password = ?) AND is_deleted = 0 LIMIT 1",
        variables: [Variable(cleanPin), Variable(cleanPin)],
      ).get();
      if (rows.isEmpty) return null;
      return MyDayFile.fromRow(rows.first);
    }
  }

  /// Backward-compatible alias for QuickActions / file picker
  Future<MyDayFile?> pickAndSaveFile(
    String accountId, {
    String shareType = 'everyone',
    String? password,
    List<String>? sharedWith,
  }) {
    return pickAndUploadFile(
      accountId: accountId,
      uploaderName: 'Me',
      uploaderPhone: '',
      shareType: shareType,
      pin: password ?? '',
      friendPhoneNumber: (sharedWith != null && sharedWith.isNotEmpty) ? sharedWith.first : '',
    );
  }

  /// Upload file to Supabase Storage bucket and create metadata entry
  Future<MyDayFile?> pickAndUploadFile({
    required String accountId,
    required String uploaderName,
    required String uploaderPhone,
    required String shareType, // 'everyone', 'private', 'friends'
    String pin = '',
    String friendPhoneNumber = '',
  }) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.first;
    final path = picked.path;
    if (path == null) return null;

    final originalFile = File(path);
    final size = await originalFile.length();

    // 15 MB limit
    if (size > 15 * 1024 * 1024) {
      throw Exception('File is larger than 15 MB limit');
    }

    final id = _uuid.v4().substring(0, 8);
    final ext = picked.name.contains('.') ? '.${picked.name.split('.').last}' : '';
    final safeName = picked.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = '$accountId/${id}_$safeName';

    // Local copy
    final docsDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${docsDir.path}/files');
    await targetDir.create(recursive: true);
    final targetPath = '${targetDir.path}/$id$ext';
    await originalFile.copy(targetPath);

    String fileUrl = '';
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // 1. Upload to Supabase Storage bucket if client is available
    try {
      final client = Supabase.instance.client;
      final fileBytes = await originalFile.readAsBytes();
      await client.storage.from(bucketName).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      fileUrl = client.storage.from(bucketName).getPublicUrl(storagePath);

      // 2. Insert metadata row into Supabase stored_files
      await client.from('stored_files').insert({
        'id': id,
        'user_id': accountId,
        'uploader_name': uploaderName,
        'uploader_phone': uploaderPhone,
        'name': picked.name,
        'size_bytes': size,
        'file_url': fileUrl,
        'storage_path': storagePath,
        'share_type': shareType,
        'pin': pin.trim(),
        'friend_phone_number': friendPhoneNumber.trim(),
        'is_deleted': false,
      });
    } catch (e) {
      // Local fallback
      fileUrl = targetPath;
    }

    // 3. Save locally to SQLite database
    await db.customInsert(
      '''
      INSERT INTO stored_files (
        id, account_id, name, size_bytes, local_path, file_url,
        share_type, pin, friend_phone_number, uploader_name, uploader_phone,
        is_deleted, sync_status, created_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 'synced', ?)
      ''',
      variables: [
        Variable(id),
        Variable(accountId),
        Variable(picked.name),
        Variable(size),
        Variable(targetPath),
        Variable(fileUrl),
        Variable(shareType),
        Variable(pin.trim()),
        Variable(friendPhoneNumber.trim()),
        Variable(uploaderName),
        Variable(uploaderPhone),
        Variable(nowMs),
      ],
    );

    return MyDayFile(
      id: id,
      accountId: accountId,
      uploaderName: uploaderName,
      uploaderPhone: uploaderPhone,
      name: picked.name,
      sizeBytes: size,
      localPath: targetPath,
      fileUrl: fileUrl,
      shareType: shareType,
      pin: pin.trim(),
      friendPhoneNumber: friendPhoneNumber.trim(),
      createdAt: nowMs,
    );
  }

  /// Download file from Supabase storage / fileUrl to device
  Future<File?> downloadFile(MyDayFile file) async {
    if (file.localPath.isNotEmpty && File(file.localPath).existsSync()) {
      return File(file.localPath);
    }

    if (file.fileUrl.isEmpty) {
      throw Exception('File download URL is not available');
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${docsDir.path}/files');
    await targetDir.create(recursive: true);
    final ext = file.name.contains('.') ? '.${file.name.split('.').last}' : '';
    final targetPath = '${targetDir.path}/${file.id}$ext';

    final targetFile = File(targetPath);
    if (targetFile.existsSync()) return targetFile;

    final response = await http.get(Uri.parse(file.fileUrl)).timeout(const Duration(seconds: 40));
    if (response.statusCode != 200) {
      throw Exception('Failed to download file: HTTP ${response.statusCode}');
    }

    await targetFile.writeAsBytes(response.bodyBytes);

    // Update local database with local path
    try {
      await db.customUpdate(
        'UPDATE stored_files SET local_path = ? WHERE id = ?',
        variables: [Variable(targetPath), Variable(file.id)],
      );
    } catch (_) {}

    return targetFile;
  }

  /// Delete file both locally and from Supabase
  Future<void> deleteFile(String fileId, {String? accountId}) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customUpdate(
      'UPDATE stored_files SET is_deleted = 1, deleted_at = ?, sync_status = "pending" WHERE id = ?',
      variables: [Variable(nowMs), Variable(fileId)],
    );

    try {
      final client = Supabase.instance.client;
      await client.from('stored_files').update({
        'is_deleted': true,
      }).eq('id', fileId);
    } catch (_) {}
  }

  Future<void> restoreFile(String fileId) async {
    await db.customUpdate(
      'UPDATE stored_files SET is_deleted = 0, deleted_at = NULL, sync_status = "pending" WHERE id = ?',
      variables: [Variable(fileId)],
    );

    try {
      final client = Supabase.instance.client;
      await client.from('stored_files').update({
        'is_deleted': false,
      }).eq('id', fileId);
    } catch (_) {}
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../features/calendar/data/models/calendar_event_model.dart';
import '../../../../features/calendar/data/models/calendar_model.dart';
import '../../../../features/money_tracker/data/models/expense_model.dart';
import '../../../../features/money_tracker/data/models/wallet_model.dart';
import '../../../../features/notes/data/models/note_model.dart';
import '../../../../features/posts/data/models/instant_model.dart';
import '../../../../features/posts/data/models/post_model.dart';
import '../../../../features/settings/data/models/ai_settings_model.dart';
import '../../../../features/tasks/data/models/task_model.dart';
import '../../../../features/trash/data/models/trash_item_model.dart';
import '../models/user_model.dart';

bool _isPrivateIpv4(String address) =>
    address == '127.0.0.1' ||
    address.startsWith('127.') ||
    address.startsWith('10.') ||
    address.startsWith('192.168.') ||
    RegExp(r'^172\.(1[6-9]|2[0-9]|3[01])\.').hasMatch(address);

class QrLoginQr {
  const QrLoginQr({
    required this.url,
    required this.sessionId,
    required this.key,
    required this.deviceName,
  });

  final String url;
  final String sessionId;
  final List<int> key;
  final String deviceName;

  static QrLoginQr? parse(String value) {
    try {
      final payload = jsonDecode(value) as Map<String, dynamic>;
      if (payload['protocol'] != 'pocketdesk-login-v1') return null;
      final url = Uri.parse(payload['url'] as String);
      final address = InternetAddress.tryParse(url.host);
      if (url.scheme != 'http' ||
          !url.hasPort ||
          !url.hasAuthority ||
          address == null ||
          address.type != InternetAddressType.IPv4 ||
          !_isPrivateIpv4(url.host)) {
        return null;
      }
      final key = base64Url.decode(payload['key'] as String);
      if (key.length != 32) return null;
      return QrLoginQr(
        url: url.toString().replaceAll(RegExp(r'/$'), ''),
        sessionId: payload['sessionId'] as String,
        key: key,
        deviceName: payload['deviceName'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}

class QrLoginRequest {
  const QrLoginRequest({
    required this.deviceName,
    required this.deviceId,
    required this.address,
  });

  final String deviceName;
  final String deviceId;
  final String address;
}

class QrLoginService {
  QrLoginService();

  static const _sessionLifetime = Duration(minutes: 5);
  static const _maximumRequestBytes = 1024 * 1024;
  static const _maximumAttachmentBytes = 64 * 1024 * 1024;
  static const _maximumResponseBytes = 128 * 1024 * 1024;
  static const _filePathKeys = {'imagePath', 'imagePaths', 'attachmentPaths'};
  static final _cipher = AesGcm.with256bits();

  final _random = Random.secure();
  final _requests = StreamController<QrLoginRequest>.broadcast();
  final _completedDevices = StreamController<QrLoginRequest>.broadcast();
  HttpServer? _server;
  Timer? _expiryTimer;
  Isar? _isar;
  UserModel? _user;
  List<int>? _key;
  String? _sessionId;
  String? _pin;
  String? _deviceName;
  String? _hostUrl;
  String? _state;
  String? _guestDeviceName;
  String? _guestDeviceId;
  String? _guestAddress;
  String? _guestToken;
  Map<String, dynamic>? _transfer;
  String? _failureMessage;
  int _failedAttempts = 0;
  bool _disposed = false;

  Stream<QrLoginRequest> get requests => _requests.stream;
  Stream<QrLoginRequest> get completedDevices => _completedDevices.stream;
  String? get pin => _pin;
  String? get deviceName => _deviceName;

  Future<String> startHost({
    required Isar isar,
    required UserModel user,
    required String deviceName,
  }) async {
    await stop();
    final address = await _getLocalAddress();
    final secretKey = await _cipher.newSecretKey();
    _key = await secretKey.extractBytes();
    _sessionId = const Uuid().v4();
    _deviceName =
        deviceName.trim().isEmpty ? 'PocketDesk device' : deviceName.trim();
    _pin = _random.nextInt(10000).toString().padLeft(4, '0');
    _isar = isar;
    _user = user;
    _state = 'idle';
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _hostUrl = 'http://$address:${_server!.port}';
    _server!.listen(_handleRequest);
    _expiryTimer = Timer(_sessionLifetime, stop);

    return jsonEncode({
      'protocol': 'pocketdesk-login-v1',
      'url': _hostUrl,
      'sessionId': _sessionId,
      'key': base64Url.encode(_key!),
      'deviceName': _deviceName,
    });
  }

  Future<void> approveRequest() async {
    if (_state != 'pending') {
      throw StateError('There is no pending login request to approve.');
    }
    _state = 'preparing';
    try {
      _transfer = await _exportAccount(_isar!, _user!);
      _state = 'approved';
    } catch (e, st) {
      _state = 'failed';
      _failureMessage = e.toString();
      AppLogger.e('Failed to prepare QR login transfer',
          tag: 'QrLogin', error: e, st: st);
      rethrow;
    }
  }

  void rejectRequest() {
    if (_state == 'pending') _state = 'rejected';
  }

  Future<void> stop() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    await _server?.close(force: true);
    _server = null;
    _state = 'cancelled';
    _transfer = null;
    _guestToken = null;
    _key = null;
    _pin = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _requests.close();
    await _completedDevices.close();
  }

  Future<void> sendLoginRequest({
    required QrLoginQr qr,
    required String deviceName,
    required String deviceId,
    required String pin,
  }) async {
    _guestToken = base64Url.encode(
      List<int>.generate(32, (_) => _random.nextInt(256)),
    );
    late final Map<String, dynamic> response;
    try {
      response = await _post(
        qr,
        '/request',
        {
          'sessionId': qr.sessionId,
          'deviceName': deviceName.trim(),
          'deviceId': deviceId,
          'pin': pin,
          'authorization': _guestToken,
        },
      );
    } catch (_) {
      _guestToken = null;
      rethrow;
    }
    if (response['status'] == 'invalid_pin') {
      _guestToken = null;
      throw const QrLoginException(
          'Incorrect PIN. Check the code on the signed-in device.');
    }
    if (response['status'] == 'blocked') {
      _guestToken = null;
      throw const QrLoginException(
          'Too many incorrect PIN attempts. Generate a new QR code.');
    }
    if (response['status'] != 'pending') {
      _guestToken = null;
      throw const QrLoginException(
          'This login QR code is no longer available.');
    }
  }

  Future<Map<String, dynamic>> poll(QrLoginQr qr) {
    return _post(qr, '/status', {'sessionId': qr.sessionId});
  }

  Future<Map<String, dynamic>> downloadTransfer(QrLoginQr qr) {
    return _post(qr, '/transfer', {'sessionId': qr.sessionId});
  }

  Future<void> complete(QrLoginQr qr) async {
    await _post(qr, '/complete', {'sessionId': qr.sessionId});
  }

  Future<void> cancelGuest(QrLoginQr qr) async {
    try {
      await _post(qr, '/cancel', {'sessionId': qr.sessionId});
    } catch (_) {
      // The host may have stopped the session already.
    }
  }

  Future<UserModel> importAccount(
    Isar isar,
    Map<String, dynamic> transfer, {
    required String deviceId,
  }) async {
    final collectionData = transfer['collections'];
    final assets = transfer['assets'];
    final ownerId = transfer['userId'];
    if (transfer['version'] != 1 ||
        ownerId is! int ||
        collectionData is! Map ||
        assets is! Map<String, dynamic>) {
      throw const QrLoginException('The account transfer data is invalid.');
    }

    if (!await _isDatabaseEmpty(isar)) {
      throw const QrLoginException(
        'This device already has local data. QR login only works on an empty device.',
      );
    }

    final documents = await getApplicationDocumentsDirectory();
    final importDirectory =
        Directory('${documents.path}/PocketDeskLogin/${const Uuid().v4()}');
    final filePaths = <String, String>{};
    try {
      await importDirectory.create(recursive: true);
      for (final entry in assets.entries) {
        if (!RegExp(r'^asset_\d+\.[a-zA-Z0-9]{1,8}$').hasMatch(entry.key) ||
            entry.value is! String) {
          throw const QrLoginException(
              'The account contains an invalid attachment.');
        }
        final token = entry.key;
        final encodedFile = entry.value as String;
        final bytes = base64Decode(encodedFile);
        final target = File('${importDirectory.path}/$token');
        await target.writeAsBytes(bytes, flush: true);
        filePaths[token] = target.path;
      }

      List<Map<String, dynamic>> rows(String name) {
        final value = collectionData[name];
        if (value is! List) {
          throw QrLoginException('The account transfer is missing $name data.');
        }
        return value.map<Map<String, dynamic>>((dynamic row) {
          if (row is! Map) {
            throw QrLoginException(
                'The account transfer contains invalid $name data.');
          }
          return _restorePaths(Map<String, dynamic>.from(row), filePaths)
              as Map<String, dynamic>;
        }).toList();
      }

      await isar.userModels.importJson(rows('users'));
      await isar.calendarModels.importJson(rows('calendars'));
      await isar.taskModels.importJson(rows('tasks'));
      await isar.noteModels.importJson(rows('notes'));
      await isar.walletModels.importJson(rows('wallets'));
      await isar.expenseModels.importJson(rows('expenses'));
      await isar.calendarEventModels.importJson(rows('events'));
      await isar.postModels.importJson(rows('posts'));
      await isar.instantModels.importJson(rows('instants'));
      await isar.aISettingsModels.importJson(rows('aiSettings'));
      await isar.trashItemModels.importJson(rows('trash'));

      final user = await isar.userModels.get(ownerId);
      if (user == null) {
        throw const QrLoginException(
            'The transferred account could not be opened.');
      }
      user
        ..deviceId = deviceId
        ..lastLoginAt = DateTime.now();
      await isar.writeTxn(() => isar.userModels.put(user));
      return user;
    } catch (_) {
      await isar.clear();
      if (await importDirectory.exists()) {
        await importDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (request.method != 'POST' ||
          !{'/request', '/status', '/transfer', '/complete', '/cancel'}
              .contains(request.uri.path)) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final body = await _readBody(request);
      final message = await _decryptJson(
        jsonDecode(utf8.decode(body)) as Map<String, dynamic>,
        _key!,
      );
      if (message['sessionId'] != _sessionId) {
        throw const QrLoginException('Invalid session.');
      }
      if (request.uri.path != '/request' &&
          (_guestToken == null || message['authorization'] != _guestToken)) {
        throw const QrLoginException('Unauthorized login request.');
      }

      late Map<String, dynamic> response;
      switch (request.uri.path) {
        case '/request':
          response = await _acceptRequest(message,
              request.connectionInfo?.remoteAddress.address ?? 'Unknown');
        case '/status':
          response = {
            'status': _state ?? 'expired',
            if (_failureMessage != null) 'error': _failureMessage,
          };
        case '/transfer':
          if (_state != 'approved' || _transfer == null) {
            response = {'status': _state ?? 'expired'};
          } else {
            response = {'status': 'approved', 'transfer': _transfer};
          }
        case '/complete':
          if (_state == 'approved') {
            _state = 'complete';
            if (!_disposed) {
              _completedDevices.add(QrLoginRequest(
                deviceName: _guestDeviceName ?? 'New device',
                deviceId: _guestDeviceId ?? '',
                address: _guestAddress ?? '',
              ));
            }
          }
          response = {'status': _state ?? 'expired'};
        case '/cancel':
          if (_state == 'pending' || _state == 'preparing') {
            _state = 'cancelled';
          }
          response = {'status': _state ?? 'expired'};
      }

      await _writeEncrypted(request.response, response, _key!);
    } catch (e, st) {
      AppLogger.e('QR login request failed', tag: 'QrLogin', error: e, st: st);
      request.response.statusCode = HttpStatus.badRequest;
      request.response.headers.contentType = ContentType.json;
      request.response
          .write(jsonEncode({'error': 'Invalid or expired login request.'}));
      await request.response.close();
    }
  }

  Future<Map<String, dynamic>> _acceptRequest(
    Map<String, dynamic> message,
    String address,
  ) async {
    if (_failedAttempts >= 5) return {'status': 'blocked'};
    if (message['pin'] != _pin) {
      _failedAttempts++;
      return {'status': _failedAttempts >= 5 ? 'blocked' : 'invalid_pin'};
    }
    if (_state != 'idle' &&
        _state != 'rejected' &&
        _state != 'cancelled' &&
        _state != 'failed') {
      return {'status': 'busy'};
    }

    final deviceName = (message['deviceName'] as String? ?? '').trim();
    final deviceId = message['deviceId'] as String? ?? '';
    final token = message['authorization'] as String? ?? '';
    if (deviceName.isEmpty ||
        deviceName.length > 32 ||
        deviceId.isEmpty ||
        token.length != 44) {
      throw const QrLoginException('Invalid device details.');
    }
    _state = 'pending';
    _guestDeviceName = deviceName;
    _guestDeviceId = deviceId;
    _guestAddress = address;
    _guestToken = token;
    _transfer = null;
    _failureMessage = null;
    if (!_disposed) {
      _requests.add(QrLoginRequest(
        deviceName: deviceName,
        deviceId: deviceId,
        address: address,
      ));
    }
    return {'status': 'pending'};
  }

  Future<Map<String, dynamic>> _exportAccount(Isar isar, UserModel user) async {
    final assets = <String, String>{};
    final pathsToTokens = <String, String>{};
    var totalAssetBytes = 0;

    Future<String> preparePath(String path) async {
      final parsedPath = Uri.tryParse(path);
      final sourcePath =
          parsedPath?.scheme == 'file' ? parsedPath!.toFilePath() : path;
      if (path.isEmpty ||
          (parsedPath?.hasScheme == true && parsedPath?.scheme != 'file')) {
        return path;
      }
      final existingToken = pathsToTokens[path];
      if (existingToken != null) return existingToken;
      final file = File(sourcePath);
      if (!await file.exists()) {
        throw const QrLoginException(
          'A saved attachment is missing on the signed-in device. Restore it before transferring the account.',
        );
      }
      totalAssetBytes += await file.length();
      if (totalAssetBytes > _maximumAttachmentBytes) {
        throw const QrLoginException(
          'Attachments exceed the 64 MB QR login transfer limit.',
        );
      }
      final token = 'asset_${assets.length}${_assetExtension(sourcePath)}';
      assets[token] = base64Encode(await file.readAsBytes());
      pathsToTokens[path] = token;
      return token;
    }

    Future<dynamic> prepare(dynamic value) async {
      if (value is Map) {
        final prepared = <String, dynamic>{};
        for (final entry in value.entries) {
          final key = entry.key as String;
          if (_filePathKeys.contains(key)) {
            if (entry.value is String) {
              prepared[key] = await preparePath(entry.value as String);
            } else if (entry.value is List) {
              final paths = entry.value as List;
              prepared[key] = await Future.wait<String>(
                paths.map((dynamic path) {
                  if (path is! String) {
                    throw const QrLoginException('Invalid attachment path.');
                  }
                  return preparePath(path);
                }),
              );
            } else {
              prepared[key] = entry.value;
            }
          } else {
            prepared[key] = await prepare(entry.value);
          }
        }
        return prepared;
      }
      if (value is List) {
        return Future.wait<dynamic>(
          value.map((dynamic item) => prepare(item)),
        );
      }
      return value;
    }

    Future<List<Map<String, dynamic>>> exportUserRows(
      Future<List<Map<String, dynamic>>> Function() export,
    ) async =>
        (await export()).map((row) => row).toList();

    final collections = <String, List<Map<String, dynamic>>>{
      'users': await exportUserRows(
        () => isar.userModels.where().idEqualTo(user.id).exportJson(),
      ),
      'calendars': await exportUserRows(
        () => isar.calendarModels.filter().userIdEqualTo(user.id).exportJson(),
      ),
      'tasks': await exportUserRows(
        () => isar.taskModels.filter().userIdEqualTo(user.id).exportJson(),
      ),
      'notes': await exportUserRows(
        () => isar.noteModels.filter().userIdEqualTo(user.id).exportJson(),
      ),
      'wallets': await exportUserRows(
        () => isar.walletModels.filter().userIdEqualTo(user.id).exportJson(),
      ),
      'expenses': await exportUserRows(
        () => isar.expenseModels.filter().userIdEqualTo(user.id).exportJson(),
      ),
      'events': await exportUserRows(
        () => isar.calendarEventModels
            .filter()
            .userIdEqualTo(user.id)
            .exportJson(),
      ),
      'posts': await exportUserRows(
        () => isar.postModels.filter().userIdEqualTo(user.id).exportJson(),
      ),
      'instants': await exportUserRows(
        () => isar.instantModels.filter().userIdEqualTo(user.id).exportJson(),
      ),
      'aiSettings': await exportUserRows(
        () =>
            isar.aISettingsModels.filter().userIdEqualTo(user.id).exportJson(),
      ),
      'trash': await exportUserRows(
        () => isar.trashItemModels.filter().userIdEqualTo(user.id).exportJson(),
      ),
    };

    final preparedCollections = <String, List<Map<String, dynamic>>>{};
    for (final entry in collections.entries) {
      preparedCollections[entry.key] = await Future.wait(
        entry.value
            .map((row) async => await prepare(row) as Map<String, dynamic>),
      );
    }
    return {
      'version': 1,
      'userId': user.id,
      'collections': preparedCollections,
      'assets': assets,
    };
  }

  static dynamic _restorePaths(dynamic value, Map<String, String> paths) {
    if (value is Map) {
      final restored = <String, dynamic>{};
      for (final entry in value.entries) {
        final key = entry.key as String;
        final item = entry.value;
        if (_filePathKeys.contains(key)) {
          if (item is String) {
            restored[key] = paths[item] ?? item;
          } else if (item is List) {
            restored[key] = item
                .map((path) => path is String ? paths[path] ?? path : path)
                .toList();
          } else {
            restored[key] = item;
          }
        } else {
          restored[key] = _restorePaths(item, paths);
        }
      }
      return restored;
    }
    if (value is List) {
      return value.map((item) => _restorePaths(item, paths)).toList();
    }
    return value;
  }

  Future<Map<String, dynamic>> _post(
    QrLoginQr qr,
    String path,
    Map<String, dynamic> message,
  ) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.postUrl(Uri.parse('${qr.url}$path'));
      request.headers.contentType = ContentType.json;
      final requestMessage = path == '/request'
          ? message
          : {...message, 'authorization': _guestToken};
      request.write(jsonEncode(await _encryptJson(requestMessage, qr.key)));
      final response =
          await request.close().timeout(const Duration(seconds: 30));
      final bodyBytes = BytesBuilder(copy: false);
      var bodyLength = 0;
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        bodyLength += chunk.length;
        if (bodyLength > _maximumResponseBytes) {
          throw const QrLoginException(
              'The account transfer exceeds the 128 MB transfer limit.');
        }
        bodyBytes.add(chunk);
      }
      final body = utf8.decode(bodyBytes.takeBytes());
      if (response.statusCode != HttpStatus.ok) {
        throw const QrLoginException(
            'Could not connect to the signed-in device.');
      }
      return _decryptJson(jsonDecode(body) as Map<String, dynamic>, qr.key);
    } finally {
      client.close(force: true);
    }
  }

  static Future<Uint8List> _readBody(HttpRequest request) async {
    final builder = BytesBuilder(copy: false);
    var length = 0;
    await for (final chunk in request) {
      length += chunk.length;
      if (length > _maximumRequestBytes) {
        throw const QrLoginException('Request is too large.');
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  static Future<Map<String, dynamic>> _encryptJson(
    Map<String, dynamic> value,
    List<int> key,
  ) async {
    final secretBox = await _cipher.encrypt(
      gzip.encode(utf8.encode(jsonEncode(value))),
      secretKey: SecretKey(key),
    );
    return {
      'nonce': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  static Future<Map<String, dynamic>> _decryptJson(
    Map<String, dynamic> value,
    List<int> key,
  ) async {
    final secretBox = SecretBox(
      base64Decode(value['ciphertext'] as String),
      nonce: base64Decode(value['nonce'] as String),
      mac: Mac(base64Decode(value['mac'] as String)),
    );
    final cleartext = await _cipher.decrypt(
      secretBox,
      secretKey: SecretKey(key),
    );
    final decoded = jsonDecode(utf8.decode(gzip.decode(cleartext)));
    if (decoded is! Map<String, dynamic>) {
      throw const QrLoginException('Invalid encrypted login data.');
    }
    return decoded;
  }

  static Future<void> _writeEncrypted(
    HttpResponse response,
    Map<String, dynamic> value,
    List<int> key,
  ) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(await _encryptJson(value, key)));
    await response.close();
  }

  static String _assetExtension(String token) {
    final match = RegExp(r'\.([a-zA-Z0-9]{1,8})$')
        .firstMatch(token.split(Platform.pathSeparator).last);
    return match == null ? '.bin' : '.${match.group(1)}';
  }

  static Future<String> _getLocalAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      ).timeout(const Duration(seconds: 3));
      final candidates = interfaces.where((interface) {
        final name = interface.name.toLowerCase();
        return !name.contains('docker') &&
            !name.contains('veth') &&
            !name.contains('bridge') &&
            !name.contains('virbr') &&
            !name.contains('tun') &&
            !name.contains('tap');
      }).toList()
        ..sort((a, b) =>
            _interfacePriority(a.name).compareTo(_interfacePriority(b.name)));
      for (final interface in candidates) {
        for (final address in interface.addresses) {
          if (_isPrivateIpv4(address.address)) return address.address;
        }
      }
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) return address.address;
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  static int _interfacePriority(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('wlan') ||
        normalized.contains('wifi') ||
        normalized.contains('wlp')) {
      return 0;
    }
    if (normalized.startsWith('en') || normalized.startsWith('eth')) return 1;
    return 2;
  }

  static Future<bool> isDatabaseEmpty(Isar isar) => _isDatabaseEmpty(isar);

  static Future<bool> _isDatabaseEmpty(Isar isar) async {
    final counts = await Future.wait<int>([
      isar.userModels.count(),
      isar.calendarModels.count(),
      isar.taskModels.count(),
      isar.noteModels.count(),
      isar.walletModels.count(),
      isar.expenseModels.count(),
      isar.calendarEventModels.count(),
      isar.postModels.count(),
      isar.instantModels.count(),
      isar.aISettingsModels.count(),
      isar.trashItemModels.count(),
    ]);
    return counts.every((count) => count == 0);
  }
}

class QrLoginException implements Exception {
  const QrLoginException(this.message);

  final String message;

  @override
  String toString() => message;
}

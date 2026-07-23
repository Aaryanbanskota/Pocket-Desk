import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/logging/app_logger.dart';

/// Keys used in secure storage.
abstract final class _Keys {
  static const activeUserId = 'pocket_desk_active_user_id';
  static const sessionToken = 'pocket_desk_session_token';
}

/// Manages secure persistence of auth-related values (active user ID,
/// session tokens) using platform keychain/keystore via flutter_secure_storage.
///
/// On Linux: uses libsecret (GNOME Keyring / KWallet).
/// On Android: uses Android Keystore.
class SecureAuthStorage {
  SecureAuthStorage() : _storage = const FlutterSecureStorage(
    // Android options: encrypted shared prefs backed by Keystore
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    // Linux: use libsecret
    lOptions: LinuxOptions(),
  );

  final FlutterSecureStorage _storage;

  // --------------------------------------------------------------------------
  // Active user
  // --------------------------------------------------------------------------

  Future<void> saveActiveUserId(int userId) async {
    try {
      await _storage.write(
        key: _Keys.activeUserId,
        value: userId.toString(),
      );
      AppLogger.d('Saved active user ID: $userId', tag: 'SecureAuthStorage');
    } catch (e, st) {
      AppLogger.e('Failed to save active user ID',
          tag: 'SecureAuthStorage', error: e, st: st);
      rethrow;
    }
  }

  Future<int?> getActiveUserId() async {
    try {
      final value = await _storage.read(key: _Keys.activeUserId);
      return value != null ? int.tryParse(value) : null;
    } catch (e, st) {
      AppLogger.e('Failed to read active user ID',
          tag: 'SecureAuthStorage', error: e, st: st);
      return null;
    }
  }

  Future<void> clearActiveUserId() async {
    await _storage.delete(key: _Keys.activeUserId);
  }

  // --------------------------------------------------------------------------
  // Session token (used in sync handshake)
  // --------------------------------------------------------------------------

  Future<void> saveSessionToken(String token) async {
    await _storage.write(key: _Keys.sessionToken, value: token);
  }

  Future<String?> getSessionToken() async {
    return _storage.read(key: _Keys.sessionToken);
  }

  Future<void> clearSessionToken() async {
    await _storage.delete(key: _Keys.sessionToken);
  }

  // --------------------------------------------------------------------------
  // Clear all (logout / factory reset)
  // --------------------------------------------------------------------------

  Future<void> clearAll() async {
    await _storage.deleteAll();
    AppLogger.i('Secure storage cleared', tag: 'SecureAuthStorage');
  }
}

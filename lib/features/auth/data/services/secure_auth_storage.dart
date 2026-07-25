import 'dart:io' show Platform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/logging/app_logger.dart';

/// Keys used in secure storage.
abstract final class _Keys {
  static const activeUserId = 'pocket_desk_active_user_id';
  static const sessionToken = 'pocket_desk_session_token';
}

final bool _isTest = Platform.environment.containsKey('FLUTTER_TEST');

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
      final Future<void> writeFuture = _storage.write(
        key: _Keys.activeUserId,
        value: userId.toString(),
      );
      await (_isTest ? writeFuture : writeFuture.timeout(const Duration(seconds: 1)));
      AppLogger.d('Saved active user ID: $userId', tag: 'SecureAuthStorage');
    } catch (e, st) {
      AppLogger.e('Failed to save active user ID',
          tag: 'SecureAuthStorage', error: e, st: st);
      // Fallback: do not rethrow to avoid blocking initialization/actions
    }
  }

  Future<int?> getActiveUserId() async {
    try {
      final Future<String?> readFuture = _storage.read(key: _Keys.activeUserId);
      final value = await (_isTest ? readFuture : readFuture.timeout(const Duration(seconds: 1)));
      return value != null ? int.tryParse(value) : null;
    } catch (e, st) {
      AppLogger.e('Failed to read active user ID',
          tag: 'SecureAuthStorage', error: e, st: st);
      return null;
    }
  }

  Future<void> clearActiveUserId() async {
    try {
      final Future<void> deleteFuture = _storage.delete(key: _Keys.activeUserId);
      await (_isTest ? deleteFuture : deleteFuture.timeout(const Duration(seconds: 1)));
    } catch (e, st) {
      AppLogger.e('Failed to delete active user ID',
          tag: 'SecureAuthStorage', error: e, st: st);
    }
  }

  // --------------------------------------------------------------------------
  // Session token (used in sync handshake)
  // --------------------------------------------------------------------------

  Future<void> saveSessionToken(String token) async {
    try {
      final Future<void> writeFuture = _storage.write(key: _Keys.sessionToken, value: token);
      await (_isTest ? writeFuture : writeFuture.timeout(const Duration(seconds: 1)));
    } catch (e, st) {
      AppLogger.e('Failed to save session token',
          tag: 'SecureAuthStorage', error: e, st: st);
    }
  }

  Future<String?> getSessionToken() async {
    try {
      final Future<String?> readFuture = _storage.read(key: _Keys.sessionToken);
      return await (_isTest ? readFuture : readFuture.timeout(const Duration(seconds: 1)));
    } catch (e, st) {
      AppLogger.e('Failed to read session token',
          tag: 'SecureAuthStorage', error: e, st: st);
      return null;
    }
  }

  Future<void> clearSessionToken() async {
    try {
      final Future<void> deleteFuture = _storage.delete(key: _Keys.sessionToken);
      await (_isTest ? deleteFuture : deleteFuture.timeout(const Duration(seconds: 1)));
    } catch (e, st) {
      AppLogger.e('Failed to delete session token',
          tag: 'SecureAuthStorage', error: e, st: st);
    }
  }

  // --------------------------------------------------------------------------
  // Clear all (logout / factory reset)
  // --------------------------------------------------------------------------

  Future<void> clearAll() async {
    try {
      final Future<void> deleteAllFuture = _storage.deleteAll();
      await (_isTest ? deleteAllFuture : deleteAllFuture.timeout(const Duration(seconds: 1)));
      AppLogger.i('Secure storage cleared', tag: 'SecureAuthStorage');
    } catch (e, st) {
      AppLogger.e('Failed to clear secure storage',
          tag: 'SecureAuthStorage', error: e, st: st);
    }
  }
}

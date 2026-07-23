import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../../../../core/logging/app_logger.dart';

/// Password hashing service using Argon2id.
///
/// Argon2id is the recommended password hashing algorithm per OWASP 2024.
/// Parameters chosen per OWASP minimum recommendation:
///   memory: 19 MiB, iterations: 2, parallelism: 1
///
/// Usage:
///   final result = await PasswordHasher.hash('myPassword');
///   final ok     = await PasswordHasher.verify('myPassword', result.hash, result.salt);
abstract final class PasswordHasher {
  static final _argon2id = Argon2id(
    memory: 19456, // 19 MiB
    parallelism: 1,
    iterations: 2,
    hashLength: 32,
  );

  static const _saltLength = 16; // 128-bit salt

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  /// Hashes [password] with a fresh random salt.
  ///
  /// Returns a [HashResult] containing hex-encoded hash and salt.
  static Future<HashResult> hash(String password) async {
    final salt = _generateSalt();
    final hash = await _derive(password, salt);
    return HashResult(
      hash: _bytesToHex(hash),
      salt: _bytesToHex(salt),
    );
  }

  /// Verifies [password] against the stored [hashHex] and [saltHex].
  ///
  /// Uses a constant-time comparison to prevent timing attacks.
  static Future<bool> verify(
    String password,
    String hashHex,
    String saltHex,
  ) async {
    try {
      final salt = _hexToBytes(saltHex);
      final derived = await _derive(password, salt);
      final stored = _hexToBytes(hashHex);
      return _constantTimeEquals(derived, stored);
    } catch (e, st) {
      AppLogger.e('Password verification failed', tag: 'PasswordHasher',
          error: e, st: st);
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  static Future<List<int>> _derive(String password, List<int> salt) async {
    final secretKey = SecretKey(utf8.encode(password));
    final output = await _argon2id.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );
    return output.extractBytes();
  }

  static List<int> _generateSalt() {
    final rng = Random.secure();
    return List<int>.generate(_saltLength, (_) => rng.nextInt(256));
  }

  static String _bytesToHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  /// Constant-time byte comparison to prevent timing attacks.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

/// Result of a password hashing operation.
final class HashResult {
  const HashResult({required this.hash, required this.salt});

  /// Hex-encoded Argon2id hash.
  final String hash;

  /// Hex-encoded random salt.
  final String salt;
}

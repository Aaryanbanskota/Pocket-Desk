import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Robust Secure PIN Service with multi-round key stretching and constant-time verification
class SecurePinService {
  SecurePinService._();

  static const String _saltPrefix = 'myday_sec_v2_salt_';
  static const int _iterations = 5000;

  /// Hashes a 4-digit PIN with multi-round SHA-256 key stretching
  static String hashPin(String pin) {
    List<int> current = utf8.encode('$_saltPrefix$pin');
    for (int i = 0; i < _iterations; i++) {
      current = sha256.convert(current).bytes;
    }
    return 'v2:$_iterations:${sha256.convert(current)}';
  }

  /// Legacy prototype hash matching: 'md:' + pin
  static String legacyHash(String pin) {
    final bytes = utf8.encode('md:$pin');
    return sha256.convert(bytes).toString();
  }

  /// Constant-time comparison to prevent side-channel timing attacks
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Verifies a 4-digit PIN against the stored hash (supporting both modern multi-round and legacy format)
  static bool verifyPin(String enteredPin, String storedHash) {
    final modernComputed = hashPin(enteredPin);
    if (_constantTimeEquals(modernComputed, storedHash)) {
      return true;
    }
    final legacyComputed = legacyHash(enteredPin);
    return _constantTimeEquals(legacyComputed, storedHash);
  }
}

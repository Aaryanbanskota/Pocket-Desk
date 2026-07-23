import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// Cryptographic wrapper to encrypt and decrypt WebSocket message payloads.
/// Uses AES-GCM (128-bit) symmetric encryption with a shared key.
class SyncEncryptor {
  SyncEncryptor({required List<int> sharedKeyBytes})
      : _secretKey = SecretKey(sharedKeyBytes),
        _algorithm = AesGcm.with128bits();

  final SecretKey _secretKey;
  final AesGcm _algorithm;

  /// Encrypts plain text string payload.
  Future<String> encrypt(String plaintext) async {
    final cleartextBytes = utf8.encode(plaintext);
    final secretBox = await _algorithm.encrypt(
      cleartextBytes,
      secretKey: _secretKey,
    );
    // Format: IV(nonce) + Ciphertext + Mac concat encoded as base64
    final payload = {
      'iv': base64.encode(secretBox.nonce),
      'cipher': base64.encode(secretBox.cipherText),
      'mac': base64.encode(secretBox.mac.bytes),
    };
    return jsonEncode(payload);
  }

  /// Decrypts encrypted string payload.
  Future<String> decrypt(String encryptedJson) async {
    final payload = jsonDecode(encryptedJson) as Map<String, dynamic>;
    final nonce = base64.decode(payload['iv'] as String);
    final ciphertext = base64.decode(payload['cipher'] as String);
    final macBytes = base64.decode(payload['mac'] as String);

    final secretBox = SecretBox(
      ciphertext,
      nonce: nonce,
      mac: Mac(macBytes),
    );
    final cleartextBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: _secretKey,
    );
    return utf8.decode(cleartextBytes);
  }
}

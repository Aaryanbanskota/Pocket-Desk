import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Generates and validates signed pairing tokens.
///
/// Token format (base64url-encoded JSON):
///   { "deviceId": "...", "userId": 1, "exp": <unix-ms>, "sig": "<hmac-sha256>" }
///
/// The HMAC is computed over "deviceId:userId:exp" using the shared secret.
class PairingTokenService {
  PairingTokenService({String? secret})
      : _secret = secret ?? const Uuid().v4();

  final String _secret;

  /// Issues a new token valid for [ttl] (default 5 minutes).
  String issueToken({
    required String deviceId,
    required int userId,
    Duration ttl = const Duration(minutes: 5),
  }) {
    final exp = DateTime.now().add(ttl).millisecondsSinceEpoch;
    final sig = _sign(deviceId, userId, exp);
    final payload = {
      'deviceId': deviceId,
      'userId': userId,
      'exp': exp,
      'sig': sig,
    };
    return base64Url.encode(utf8.encode(jsonEncode(payload)));
  }

  /// Returns the decoded payload if valid, null otherwise.
  Map<String, dynamic>? verifyToken(String token) {
    try {
      final json = jsonDecode(utf8.decode(base64Url.decode(token)))
          as Map<String, dynamic>;
      final exp = json['exp'] as int;
      if (DateTime.now().millisecondsSinceEpoch > exp) return null; // expired
      final expected = _sign(
        json['deviceId'] as String,
        json['userId'] as int,
        exp,
      );
      if (json['sig'] != expected) return null; // tampered
      return json;
    } catch (_) {
      return null;
    }
  }

  String _sign(String deviceId, int userId, int exp) {
    final msg = '$deviceId:$userId:$exp';
    final hmac = Hmac(sha256, utf8.encode(_secret));
    return hmac.convert(utf8.encode(msg)).toString();
  }
}

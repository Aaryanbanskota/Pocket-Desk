import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/auth/data/services/qr_login_service.dart';

void main() {
  group('QrLoginQr.parse', () {
    String payload(String url) => jsonEncode({
          'protocol': 'pocketdesk-login-v1',
          'url': url,
          'sessionId': 'session',
          'key': base64Url.encode(List<int>.filled(32, 1)),
          'deviceName': 'My device',
        });

    test('accepts private IPv4 QR payloads', () {
      final qr = QrLoginQr.parse(payload('http://192.168.1.4:4321'));

      expect(qr, isNotNull);
      expect(qr!.url, 'http://192.168.1.4:4321');
      expect(qr.sessionId, 'session');
      expect(qr.key, List<int>.filled(32, 1));
    });

    test('rejects public, non-IPv4, and malformed payloads', () {
      expect(QrLoginQr.parse(payload('http://8.8.8.8:4321')), isNull);
      expect(QrLoginQr.parse(payload('http://localhost:4321')), isNull);
      expect(QrLoginQr.parse('not json'), isNull);
    });
  });
}

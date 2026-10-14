import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/auth/data/auth_repository.dart';

void main() {
  group('UserSession & Backend Phone Number Tests', () {
    test('UserSession phoneNumber uses backend customPhoneNumber', () {
      const session = UserSession(
        accountId: '5fe24e44-034c-4e66-8849-fc6e927f65d5',
        name: 'Aaryan Banskota',
        handle: 'aaryan',
        bio: 'Developer',
        email: 'aaryan.banskota@gmail.com',
        isCloud: true,
        isBioEnabled: true,
        customPhoneNumber: '9841928374',
      );

      expect(session.phoneNumber, equals('9841928374'));
      expect(session.identityKey, equals('9841928374'));
    });

    test('UserSession phoneNumber extracts last 10 digits if country code present', () {
      const session = UserSession(
        accountId: '5fe24e44-034c-4e66-8849-fc6e927f65d5',
        name: 'Aaryan Banskota',
        handle: 'aaryan',
        bio: '',
        email: 'aaryan@gmail.com',
        isCloud: true,
        isBioEnabled: true,
        customPhoneNumber: '+9779898209375',
      );

      expect(session.phoneNumber, equals('9898209375'));
      expect(session.identityKey, equals('9898209375'));
    });

    test('UserSession copyWith updates session and preserves backend phone number', () {
      const session = UserSession(
        accountId: 'user_123',
        name: 'Original',
        handle: 'original',
        bio: '',
        isCloud: true,
        isBioEnabled: false,
        customPhoneNumber: '9812345678',
      );

      final updated = session.copyWith(
        name: 'Updated Name',
        isBioEnabled: true,
      );

      expect(updated.name, equals('Updated Name'));
      expect(updated.isBioEnabled, isTrue);
      expect(updated.phoneNumber, equals('9812345678'));
    });

    test('UserSession serializes and deserializes customPhoneNumber correctly', () {
      const original = UserSession(
        accountId: 'cloud_user_456',
        name: 'Cloud User',
        handle: 'clouduser',
        bio: 'Hello cloud',
        email: 'cloud@example.com',
        isCloud: true,
        isBioEnabled: true,
        customPhoneNumber: '9841928374',
        customIdentityKey: '9841928374',
      );

      final json = original.toJson();
      final restored = UserSession.fromJson(json);

      expect(restored.accountId, equals(original.accountId));
      expect(restored.customPhoneNumber, equals('9841928374'));
      expect(restored.phoneNumber, equals('9841928374'));
      expect(restored.identityKey, equals('9841928374'));
    });
  });

  group('Cloud Conversion Exception & Result Types', () {
    test('EmailConfirmationRequiredException stores email and message', () {
      const ex = EmailConfirmationRequiredException(
        email: 'test@gmail.com',
      );

      expect(ex.email, equals('test@gmail.com'));
      expect(ex.toString(), contains('confirmation email has been sent'));
    });

    test('LocalToCloudInitiationResult represents pending confirmation state', () {
      const result = LocalToCloudInitiationResult(
        isCompleted: false,
        needsEmailConfirmation: true,
        email: 'test@gmail.com',
        message: 'Confirmation link sent to test@gmail.com.',
      );

      expect(result.isCompleted, isFalse);
      expect(result.needsEmailConfirmation, isTrue);
      expect(result.email, equals('test@gmail.com'));
      expect(result.session, isNull);
    });

    test('LocalToCloudInitiationResult represents completed state', () {
      const session = UserSession(
        accountId: 'supabase_uuid_789',
        name: 'Confirmed User',
        handle: 'confirmed',
        bio: '',
        email: 'confirmed@gmail.com',
        isCloud: true,
        isBioEnabled: true,
        customPhoneNumber: '9860124892',
      );

      const result = LocalToCloudInitiationResult(
        isCompleted: true,
        needsEmailConfirmation: false,
        session: session,
        email: 'confirmed@gmail.com',
      );

      expect(result.isCompleted, isTrue);
      expect(result.needsEmailConfirmation, isFalse);
      expect(result.session?.phoneNumber, equals('9860124892'));
    });
  });
}

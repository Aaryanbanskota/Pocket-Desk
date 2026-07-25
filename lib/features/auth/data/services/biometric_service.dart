import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

import '../../../../core/logging/app_logger.dart';

/// Wraps [LocalAuthentication] with a clean API for biometric login.
///
/// Call [isBiometricAvailable] first to check hardware + enrolled biometrics.
/// Then call [authenticate] — returns true on success, false on cancel/failure.
class BiometricService {
  BiometricService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  static const _tag = 'BiometricService';

  /// Returns true if the device supports biometrics AND has enrolled credentials.
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;

      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (e) {
      AppLogger.w('Biometric availability check failed: $e', tag: _tag);
      return false;
    }
  }

  /// Prompts the user for biometric authentication.
  ///
  /// Returns true on successful authentication.
  /// Returns false if cancelled, not available, or an error occurs.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access PocketDesk',
        options: const AuthenticationOptions(
          biometricOnly: false, // also allows device PIN as fallback
          stickyAuth: true,     // keep dialog alive if user backgrounds app
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled ||
          e.code == auth_error.passcodeNotSet) {
        AppLogger.w('Biometric not configured: ${e.code}', tag: _tag);
      } else if (e.code != auth_error.lockedOut &&
                 e.code != auth_error.permanentlyLockedOut) {
        AppLogger.e('Biometric auth error: ${e.code}', tag: _tag, error: e);
      }
      return false;
    } catch (e) {
      AppLogger.e('Unexpected biometric error', tag: _tag, error: e);
      return false;
    }
  }
}

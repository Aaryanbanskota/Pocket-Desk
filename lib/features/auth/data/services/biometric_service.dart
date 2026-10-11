import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

import '../../../../core/logging/app_logger.dart';

class BiometricService {
  BiometricService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  static const _tag = 'BiometricService';
  static bool isAuthenticating = false;
  static DateTime? lastSuccessfulAuthTime;

  Future<bool> isBiometricAvailable() async {
    if (Platform.isLinux) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (canCheck) return true;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (isDeviceSupported) {
        final enrolled = await _auth.getAvailableBiometrics();
        return enrolled.isNotEmpty;
      }
      return false;
    } catch (e) {
      AppLogger.w('Biometric availability check failed: $e', tag: _tag);
      return false;
    }
  }

  Future<bool> authenticate({
    String localizedReason = 'Authenticate to access MyDay',
  }) async {
    if (Platform.isLinux) {
      throw const BiometricAuthenticationException(
        'Biometric authentication is not supported on Linux.',
      );
    }
    isAuthenticating = true;
    try {
      final result = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
      if (result) {
        lastSuccessfulAuthTime = DateTime.now();
      }
      return result;
    } on PlatformException catch (e) {
      final message = switch (e.code) {
        auth_error.notAvailable =>
          'Biometric authentication is not available on this device.',
        auth_error.notEnrolled =>
          'Set up a fingerprint or face unlock in Android Settings first.',
        auth_error.passcodeNotSet =>
          'Set a screen lock on this device before using biometrics.',
        auth_error.lockedOut =>
          'Biometrics are temporarily locked. Unlock your device and try again.',
        auth_error.permanentlyLockedOut =>
          'Biometrics are locked. Unlock your device with its screen lock and try again.',
        _ => e.message ?? 'Biometric authentication could not be completed.',
      };
      AppLogger.e('Biometric auth error: ${e.code}', tag: _tag, error: e);
      throw BiometricAuthenticationException(message);
    } finally {
      Future.delayed(const Duration(milliseconds: 1500), () {
        isAuthenticating = false;
      });
    }
  }
}

class BiometricAuthenticationException implements Exception {
  const BiometricAuthenticationException(this.message);

  final String message;

  @override
  String toString() => message;
}

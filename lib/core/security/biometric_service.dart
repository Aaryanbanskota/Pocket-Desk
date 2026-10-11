import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  static bool isAuthenticating = false;
  static DateTime? lastSuccessfulAuthTime;

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (canCheck) return true;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (isDeviceSupported) {
        final enrolled = await _auth.getAvailableBiometrics();
        return enrolled.isNotEmpty;
      }
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Unlock MyDay'}) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) {
        return false;
      }
      isAuthenticating = true;
      final result = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
      if (result) {
        lastSuccessfulAuthTime = DateTime.now();
      }
      return result;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    } finally {
      Future.delayed(const Duration(milliseconds: 1500), () {
        isAuthenticating = false;
      });
    }
  }
}

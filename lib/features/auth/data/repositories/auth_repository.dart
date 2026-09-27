import 'dart:math';

import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/user_model.dart';
import '../services/password_hasher.dart';
import '../services/secure_auth_storage.dart';

/// Data access layer for authentication operations.
///
/// All methods return typed results — never throw into the UI layer.
class AuthRepository {
  AuthRepository({
    required Isar isar,
    required SecureAuthStorage secureStorage,
  })  : _isar = isar,
        _secureStorage = secureStorage;

  final Isar _isar;
  final SecureAuthStorage _secureStorage;
  static const _uuid = Uuid();

  // --------------------------------------------------------------------------
  // Registration
  // --------------------------------------------------------------------------

  /// Creates a new local user account with optional security question.
  Future<({UserModel user, AppFailure? error})> register({
    required String username,
    required String password,
    String? displayName,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    try {
      // Check uniqueness
      final existing = await _isar.userModels
          .where()
          .usernameEqualTo(username.trim())
          .findFirst();

      if (existing != null) {
        return (
          user: UserModel(),
          error: const AuthFailure('Username already taken'),
        );
      }

      final hashResult = await PasswordHasher.hash(password);
      final now = DateTime.now();

      final user = UserModel()
        ..username = username.trim()
        ..passwordHash = hashResult.hash
        ..passwordSalt = hashResult.salt
        ..displayName = displayName?.trim()
        ..themePreference = 'system'
        ..notificationsEnabled = true
        ..createdAt = now
        ..lastLoginAt = now
        ..deviceId = _generateDeviceId();

      if (securityQuestion != null &&
          securityAnswer != null &&
          securityAnswer.trim().isNotEmpty) {
        final answerHashResult =
            await PasswordHasher.hash(securityAnswer.toLowerCase().trim());
        user
          ..securityQuestion = securityQuestion
          ..securityAnswerHash = answerHashResult.hash
          ..securityAnswerSalt = answerHashResult.salt;
      }

      await _isar.writeTxn(() async {
        await _isar.userModels.put(user);
      });

      await _secureStorage.saveActiveUserId(user.id);
      AppLogger.i('User registered: ${user.username}', tag: 'AuthRepository');
      return (user: user, error: null);
    } catch (e, st) {
      AppLogger.e('Registration failed',
          tag: 'AuthRepository', error: e, st: st);
      return (
        user: UserModel(),
        error:
            UnexpectedFailure('Registration failed', error: e, stackTrace: st),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Password Recovery via Security Question
  // --------------------------------------------------------------------------

  Future<String?> getSecurityQuestion(String username) async {
    try {
      final user = await _isar.userModels
          .where()
          .usernameEqualTo(username.trim())
          .findFirst();
      return user?.securityQuestion;
    } catch (e) {
      return null;
    }
  }

  Future<AppFailure?> resetPasswordWithSecurityAnswer({
    required String username,
    required String securityAnswer,
    required String newPassword,
  }) async {
    try {
      final user = await _isar.userModels
          .where()
          .usernameEqualTo(username.trim())
          .findFirst();
      if (user == null) return const AuthFailure('User not found');
      if (user.securityAnswerHash == null || user.securityAnswerSalt == null) {
        return const AuthFailure(
            'No security question was set for this account');
      }

      final valid = await PasswordHasher.verify(
        securityAnswer.toLowerCase().trim(),
        user.securityAnswerHash!,
        user.securityAnswerSalt!,
      );

      if (!valid) return const AuthFailure('Incorrect security answer');

      final hashResult = await PasswordHasher.hash(newPassword);
      await _isar.writeTxn(() async {
        user
          ..passwordHash = hashResult.hash
          ..passwordSalt = hashResult.salt;
        await _isar.userModels.put(user);
      });

      AppLogger.i('Password reset via security question for ${user.username}',
          tag: 'AuthRepository');
      return null;
    } catch (e, st) {
      return UnexpectedFailure('Password reset failed',
          error: e, stackTrace: st);
    }
  }

  // --------------------------------------------------------------------------
  // Full Account Deletion (Wipe All Data)
  // --------------------------------------------------------------------------

  Future<AppFailure?> deleteAccount(int userId) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.clear();
      });
      await _secureStorage.clearAll();
      AppLogger.i('Account and all database records wiped completely',
          tag: 'AuthRepository');
      return null;
    } catch (e, st) {
      AppLogger.e('Failed to delete account',
          tag: 'AuthRepository', error: e, st: st);
      return UnexpectedFailure('Account deletion failed',
          error: e, stackTrace: st);
    }
  }

  // --------------------------------------------------------------------------
  // Login
  // --------------------------------------------------------------------------

  /// Authenticates a user by username + password.
  ///
  /// Returns [AuthFailure] for invalid credentials.
  Future<({UserModel? user, AppFailure? error})> login({
    required String username,
    required String password,
  }) async {
    try {
      final user = await _isar.userModels
          .where()
          .usernameEqualTo(username.trim())
          .findFirst();

      if (user == null) {
        // Constant-time: still run hash to prevent username enumeration timing
        await PasswordHasher.hash(password);
        return (user: null, error: const AuthFailure('Invalid credentials'));
      }

      final valid = await PasswordHasher.verify(
        password,
        user.passwordHash,
        user.passwordSalt,
      );

      if (!valid) {
        return (user: null, error: const AuthFailure('Invalid credentials'));
      }

      // Update last login timestamp
      await _isar.writeTxn(() async {
        user.lastLoginAt = DateTime.now();
        await _isar.userModels.put(user);
      });

      await _secureStorage.saveActiveUserId(user.id);
      await _secureStorage.saveLastUsername(user.username);
      AppLogger.i('User logged in: ${user.username}', tag: 'AuthRepository');
      return (user: user, error: null);
    } catch (e, st) {
      AppLogger.e('Login failed', tag: 'AuthRepository', error: e, st: st);
      return (
        user: null,
        error: UnexpectedFailure('Login failed', error: e, stackTrace: st),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Session restore
  // --------------------------------------------------------------------------

  /// Restores the previously active user session on app start.
  Future<UserModel?> restoreSession() async {
    try {
      final userId = await _secureStorage.getActiveUserId();
      if (userId == null) return null;
      return _isar.userModels.get(userId);
    } catch (e, st) {
      AppLogger.w('Session restore failed',
          tag: 'AuthRepository', error: e, st: st);
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Logout
  // --------------------------------------------------------------------------

  Future<void> logout() async {
    await _secureStorage.clearActiveUserId();
    await _secureStorage.saveBiometricEnabled(false);
    // Note: we intentionally keep lastUsername so the login page can still
    // suggest the username after logout.
    AppLogger.i('User logged out', tag: 'AuthRepository');
  }

  Future<void> saveTransferredSession(UserModel user) async {
    await _secureStorage.saveActiveUserId(user.id);
    await _secureStorage.saveLastUsername(user.username);
  }

  // --------------------------------------------------------------------------
  // Last username
  // --------------------------------------------------------------------------

  Future<String?> getLastUsername() => _secureStorage.getLastUsername();

  // --------------------------------------------------------------------------
  // Biometric preference
  // --------------------------------------------------------------------------

  Future<bool> getBiometricEnabled() => _secureStorage.getBiometricEnabled();
  Future<void> saveBiometricEnabled(bool enabled) =>
      _secureStorage.saveBiometricEnabled(enabled);

  // --------------------------------------------------------------------------
  // Profile update
  // --------------------------------------------------------------------------

  Future<({UserModel? user, AppFailure? error})> updateProfile({
    required int userId,
    String? displayName,
    String? avatarBase64,
    String? themePreference,
    bool? notificationsEnabled,
  }) async {
    try {
      final user = await _isar.userModels.get(userId);
      if (user == null) {
        return (user: null, error: const AuthFailure('User not found'));
      }

      await _isar.writeTxn(() async {
        if (displayName != null) user.displayName = displayName.trim();
        if (avatarBase64 != null) user.avatarBase64 = avatarBase64;
        if (themePreference != null) user.themePreference = themePreference;
        if (notificationsEnabled != null) {
          user.notificationsEnabled = notificationsEnabled;
        }
        await _isar.userModels.put(user);
      });

      return (user: user, error: null);
    } catch (e, st) {
      AppLogger.e('Profile update failed',
          tag: 'AuthRepository', error: e, st: st);
      return (
        user: null,
        error: UnexpectedFailure('Profile update failed',
            error: e, stackTrace: st),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Password change
  // --------------------------------------------------------------------------

  Future<AppFailure?> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = await _isar.userModels.get(userId);
      if (user == null) return const AuthFailure('User not found');

      final valid = await PasswordHasher.verify(
        currentPassword,
        user.passwordHash,
        user.passwordSalt,
      );
      if (!valid) return const AuthFailure('Current password is incorrect');

      final hashResult = await PasswordHasher.hash(newPassword);
      await _isar.writeTxn(() async {
        user
          ..passwordHash = hashResult.hash
          ..passwordSalt = hashResult.salt;
        await _isar.userModels.put(user);
      });

      AppLogger.i('Password changed for user ${user.username}',
          tag: 'AuthRepository');
      return null;
    } catch (e, st) {
      AppLogger.e('Password change failed',
          tag: 'AuthRepository', error: e, st: st);
      return UnexpectedFailure('Password change failed',
          error: e, stackTrace: st);
    }
  }

  Future<bool> verifyUserPassword(int userId, String password) async {
    try {
      final user = await _isar.userModels.get(userId);
      if (user == null) return false;
      return PasswordHasher.verify(
          password, user.passwordHash, user.passwordSalt);
    } catch (e) {
      return false;
    }
  }

  Future<AppFailure?> updateSecurityQuestions({
    required int userId,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    try {
      final user = await _isar.userModels.get(userId);
      if (user == null) return const AuthFailure('User not found');

      final valid = await PasswordHasher.verify(
        password,
        user.passwordHash,
        user.passwordSalt,
      );
      if (!valid) return const AuthFailure('Password is incorrect');

      final answerHashResult =
          await PasswordHasher.hash(securityAnswer.toLowerCase().trim());
      await _isar.writeTxn(() async {
        user
          ..securityQuestion = securityQuestion
          ..securityAnswerHash = answerHashResult.hash
          ..securityAnswerSalt = answerHashResult.salt;
        await _isar.userModels.put(user);
      });

      AppLogger.i('Security questions updated for ${user.username}',
          tag: 'AuthRepository');
      return null;
    } catch (e, st) {
      AppLogger.e('Failed to update security questions',
          tag: 'AuthRepository', error: e, st: st);
      return UnexpectedFailure('Failed to update security questions',
          error: e, stackTrace: st);
    }
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  String _generateDeviceId() {
    // UUID v4 prefixed with a short random suffix for readability
    final suffix = Random.secure().nextInt(9999).toString().padLeft(4, '0');
    return '${_uuid.v4()}-$suffix';
  }
}

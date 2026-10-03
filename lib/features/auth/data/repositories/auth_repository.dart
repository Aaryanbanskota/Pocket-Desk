import 'dart:math';

import 'package:isar/isar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../../features/calendar/data/models/calendar_event_model.dart';
import '../../../../features/calendar/data/models/calendar_model.dart';
import '../../../../features/money_tracker/data/models/expense_model.dart';
import '../../../../features/money_tracker/data/models/wallet_model.dart';
import '../../../../features/notes/data/models/note_model.dart';
import '../../../../features/posts/data/models/instant_model.dart';
import '../../../../features/posts/data/models/post_model.dart';
import '../../../../features/settings/data/models/ai_settings_model.dart';
import '../../../../features/tasks/data/models/task_model.dart';
import '../../../../features/trash/data/models/trash_item_model.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/supabase_auth_service.dart';
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

  /// Creates a new user account with optional security question.
  Future<({UserModel user, AppFailure? error})> register({
    required String username,
    required String password,
    String? email,
    String? displayName,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    try {
      final trimmedUser = username.trim();
      final trimmedEmail = email?.trim().toLowerCase();

      // Check username uniqueness
      final existingUser = await _isar.userModels
          .where()
          .usernameEqualTo(trimmedUser)
          .findFirst();

      if (existingUser != null) {
        return (
          user: UserModel(),
          error: const AuthFailure('Username already taken'),
        );
      }

      // Check email uniqueness if provided
      if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
        final existingEmail = await _isar.userModels
            .filter()
            .emailEqualTo(trimmedEmail)
            .findFirst();
        if (existingEmail != null) {
          return (
            user: UserModel(),
            error: const AuthFailure('Email address is already registered'),
          );
        }
      }

      final hashResult = await PasswordHasher.hash(password);
      final now = DateTime.now();

      final user = UserModel()
        ..username = trimmedUser
        ..email = trimmedEmail
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
      AppLogger.i('User registered: ${user.username} (${user.email})', tag: 'AuthRepository');
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

  /// Converts a local account into a Cloud Account by attaching Gmail and Cloud Master Password.
  Future<AppFailure?> convertLocalToCloudAccount({
    required int userId,
    required String email,
    required String cloudPassword,
  }) async {
    try {
      final user = await _isar.userModels.get(userId);
      if (user == null) return const AuthFailure('User account not found');

      final hashResult = await PasswordHasher.hash(cloudPassword);
      await _isar.writeTxn(() async {
        user.email = email.trim().toLowerCase();
        user.cloudPasswordHash = hashResult.hash;
        user.cloudPasswordSalt = hashResult.salt;
        await _isar.userModels.put(user);
      });

      AppLogger.i('Local account converted to Cloud for ${user.username} with email $email',
          tag: 'AuthRepository');
      return null;
    } catch (e, st) {
      AppLogger.e('Failed to convert account',
          tag: 'AuthRepository', error: e, st: st);
      return UnexpectedFailure('Failed to convert account',
          error: e, stackTrace: st);
    }
  }

  // --------------------------------------------------------------------------
  // Password Recovery via Security Question
  // --------------------------------------------------------------------------

  Future<String?> getSecurityQuestion(String usernameOrEmail) async {
    try {
      final term = usernameOrEmail.trim().toLowerCase();
      var user = await _isar.userModels
          .where()
          .usernameEqualTo(term)
          .findFirst();
      user ??= await _isar.userModels
          .filter()
          .emailEqualTo(term)
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
      // 1. Fetch cloud email from secure storage or user model to wipe cloud profiles & requests
      const rawStorage = FlutterSecureStorage();
      var cloudEmail = await rawStorage.read(key: 'cloud_email');
      
      final user = await _isar.userModels.get(userId);
      if (user?.email != null && user!.email!.isNotEmpty) {
        cloudEmail = user.email;
      }

      if (cloudEmail != null && cloudEmail.isNotEmpty) {
        await SupabaseAuthService.deleteUserData(email: cloudEmail);
      }

      // 2. Clear all local database records across all Isar schemas
      await _isar.writeTxn(() async {
        await _isar.clear();
      });

      // 3. Clear all secure storage credentials and state keys
      await _secureStorage.clearAll();
      AppLogger.i('Account and all database records (cloud profiles, requests, local Isar tables) wiped completely',
          tag: 'AuthRepository');
      return null;
    } catch (e, st) {
      AppLogger.e('Failed to delete account',
          tag: 'AuthRepository', error: e, st: st);
      return UnexpectedFailure('Account deletion failed',
          error: e, stackTrace: st);
    }
  }

  Future<List<UserModel>> getStoredAccounts() async {
    final accounts = await _isar.userModels.where().findAll();
    accounts.sort((a, b) => a.username.compareTo(b.username));
    return accounts;
  }

  Future<void> deleteStoredAccount(int userId) async {
    final account = await _isar.userModels.get(userId);
    if (account == null) {
      throw StateError('The stored account no longer exists.');
    }

    if (account.email != null && account.email!.isNotEmpty) {
      await SupabaseAuthService.deleteUserData(email: account.email!);
    }

    await _isar.writeTxn(() async {
      await _isar.calendarEventModels
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();
      await _isar.calendarModels.filter().userIdEqualTo(userId).deleteAll();
      await _isar.taskModels.filter().userIdEqualTo(userId).deleteAll();
      await _isar.noteModels.filter().userIdEqualTo(userId).deleteAll();
      await _isar.walletModels.filter().userIdEqualTo(userId).deleteAll();
      await _isar.expenseModels.filter().userIdEqualTo(userId).deleteAll();
      await _isar.postModels.filter().userIdEqualTo(userId).deleteAll();
      await _isar.instantModels.filter().userIdEqualTo(userId).deleteAll();
      await _isar.aISettingsModels.filter().userIdEqualTo(userId).deleteAll();
      await _isar.trashItemModels.filter().userIdEqualTo(userId).deleteAll();
      await _isar.userModels.delete(userId);
    });
  }

  // --------------------------------------------------------------------------
  // Login
  // --------------------------------------------------------------------------

  /// Authenticates a user by (username or email) + (primary password or master cloud password).
  /// Works seamlessly for both Local and Cloud accounts.
  Future<({UserModel? user, AppFailure? error})> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final input = usernameOrEmail.trim().toLowerCase();
      var user = await _isar.userModels
          .where()
          .usernameEqualTo(usernameOrEmail.trim())
          .findFirst();

      user ??= await _isar.userModels
          .filter()
          .emailEqualTo(input)
          .findFirst();

      if (user != null) {
        // Check primary password
        var valid = await PasswordHasher.verify(
          password,
          user.passwordHash,
          user.passwordSalt,
        );

        // Check secondary master cloud password if primary didn't match
        if (!valid && user.cloudPasswordHash != null && user.cloudPasswordSalt != null) {
          valid = await PasswordHasher.verify(
            password,
            user.cloudPasswordHash!,
            user.cloudPasswordSalt!,
          );
        }

        if (valid) {
          await _isar.writeTxn(() async {
            user!.lastLoginAt = DateTime.now();
            await _isar.userModels.put(user);
          });

          await _secureStorage.saveActiveUserId(user.id);
          await _secureStorage.saveLastUsername(user.username);
          AppLogger.i('User logged in locally: ${user.username}', tag: 'AuthRepository');
          return (user: user, error: null);
        }
      }

      // If local lookup failed or password didn't match local hash, try Supabase Cloud Auth login (if input is email or username)
      if (input.contains('@')) {
        final cloudRes = await SupabaseAuthService.signInWithPassword(
          email: input,
          password: password,
        );

        if (cloudRes.success) {
          final profileRes = await SupabaseAuthService.syncProfileFromSupabase(email: input);
          final hashResult = await PasswordHasher.hash(password);
          final now = DateTime.now();
          final username = profileRes.username ?? input.split('@').first;
          final displayName = profileRes.displayName ?? username;

          final newUser = UserModel()
            ..username = username
            ..email = input
            ..passwordHash = hashResult.hash
            ..passwordSalt = hashResult.salt
            ..displayName = displayName
            ..themePreference = 'system'
            ..notificationsEnabled = true
            ..createdAt = now
            ..lastLoginAt = now
            ..deviceId = _generateDeviceId();

          await _isar.writeTxn(() async {
            await _isar.userModels.put(newUser);
          });

          await _secureStorage.saveActiveUserId(newUser.id);
          await _secureStorage.saveLastUsername(newUser.username);
          AppLogger.i('User logged in via Supabase Cloud Auth: ${newUser.username}', tag: 'AuthRepository');
          return (user: newUser, error: null);
        }
      }

      // If neither local nor cloud auth matched
      await PasswordHasher.hash(password);
      return (user: null, error: const AuthFailure('Invalid email/username or password'));
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
    if (!await _secureStorage.getBiometricEnabled()) {
      await _secureStorage.clearActiveUserId();
    }
    // Note: we intentionally keep lastUsername so the login page can still
    // suggest the username and preserve the biometric preference after logout.
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/isar_provider.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/secure_auth_storage.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final _secureAuthStorageProvider = Provider<SecureAuthStorage>(
  (_) => SecureAuthStorage(),
);

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final secureStorage = ref.watch(_secureAuthStorageProvider);
  return AuthRepository(isar: isar, secureStorage: secureStorage);
});

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------

/// Possible states for the auth flow.
sealed class AuthState {
  const AuthState();
}

/// App is checking stored session.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// No active session — show login/register.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User is authenticated.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user, {this.isNewRegistration = false});
  final UserModel user;
  final bool isNewRegistration;
}

/// An auth operation failed.
final class AuthError extends AuthState {
  const AuthError(this.failure);
  final AppFailure failure;
}

// ---------------------------------------------------------------------------
// Auth notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    return _restoreSession();
  }

  // --------------------------------------------------------------------------
  // Session restore
  // --------------------------------------------------------------------------

  Future<AuthState> _restoreSession(
      {bool biometricAuthenticated = false}) async {
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      final user = await repo.restoreSession();
      if (user != null) {
        if (!biometricAuthenticated && await repo.getBiometricEnabled()) {
          return const AuthUnauthenticated();
        }
        AppLogger.i('Session restored for ${user.username}',
            tag: 'AuthNotifier');
        return AuthAuthenticated(user);
      }
      return const AuthUnauthenticated();
    } catch (e, st) {
      AppLogger.e('Session restore error',
          tag: 'AuthNotifier', error: e, st: st);
      return const AuthUnauthenticated();
    }
  }

  /// Public entry-point for biometric login — re-checks the stored session.
  Future<void> restoreSession({bool biometricAuthenticated = false}) async {
    state = const AsyncValue.loading();
    final result = await _restoreSession(
      biometricAuthenticated: biometricAuthenticated,
    );
    state = AsyncValue.data(result);
  }

  // --------------------------------------------------------------------------
  // Register
  // --------------------------------------------------------------------------

  Future<void> register({
    required String username,
    required String password,
    String? email,
    String? displayName,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      final result = await repo.register(
        username: username,
        password: password,
        email: email,
        displayName: displayName,
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer,
      );
      if (result.error != null) {
        state = AsyncValue.data(AuthError(result.error!));
      } else {
        state = AsyncValue.data(
            AuthAuthenticated(result.user, isNewRegistration: true));
      }
    } catch (e, st) {
      state = AsyncValue.data(
        AuthError(
            UnexpectedFailure('Registration failed', error: e, stackTrace: st)),
      );
    }
  }

  Future<AppFailure?> convertLocalToCloudAccount({
    required String email,
    required String cloudPassword,
  }) async {
    final current = state.valueOrNull;
    if (current is! AuthAuthenticated) {
      return const AuthFailure('Not logged in');
    }
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      final err = await repo.convertLocalToCloudAccount(
        userId: current.user.id,
        email: email,
        cloudPassword: cloudPassword,
      );
      if (err == null) {
        // Refresh authenticated state with updated user record
        final updatedUser = await repo.restoreSession();
        if (updatedUser != null) {
          state = AsyncValue.data(AuthAuthenticated(updatedUser));
        }
      }
      return err;
    } catch (e, st) {
      return UnexpectedFailure('Account conversion failed', error: e, stackTrace: st);
    }
  }

  Future<AppFailure?> deleteAccount() async {
    final current = state.valueOrNull;
    if (current is! AuthAuthenticated) {
      return const AuthFailure('Not logged in');
    }
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      final err = await repo.deleteAccount(current.user.id);
      if (err == null) {
        state = const AsyncValue.data(AuthUnauthenticated());
      }
      return err;
    } catch (e, st) {
      return UnexpectedFailure('Account deletion failed',
          error: e, stackTrace: st);
    }
  }

  Future<String?> getSecurityQuestion(String usernameOrEmail) async {
    final repo = await ref.read(authRepositoryProvider.future);
    return repo.getSecurityQuestion(usernameOrEmail);
  }

  Future<AppFailure?> resetPasswordWithSecurityAnswer({
    required String username,
    required String securityAnswer,
    required String newPassword,
  }) async {
    final repo = await ref.read(authRepositoryProvider.future);
    return repo.resetPasswordWithSecurityAnswer(
      username: username,
      securityAnswer: securityAnswer,
      newPassword: newPassword,
    );
  }

  // --------------------------------------------------------------------------
  // Login
  // --------------------------------------------------------------------------

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      final result = await repo.login(usernameOrEmail: username, password: password);
      if (result.error != null) {
        state = AsyncValue.data(AuthError(result.error!));
      } else {
        state = AsyncValue.data(AuthAuthenticated(result.user!));
      }
    } catch (e, st) {
      state = AsyncValue.data(
        AuthError(UnexpectedFailure('Login failed', error: e, stackTrace: st)),
      );
    }
  }

  Future<void> loginWithTransferredUser(UserModel user) async {
    final repo = await ref.read(authRepositoryProvider.future);
    await repo.saveTransferredSession(user);
    state = AsyncValue.data(AuthAuthenticated(user));
  }

  Future<List<UserModel>> getStoredAccounts() async {
    final current = state.valueOrNull;
    if (current is! AuthAuthenticated) {
      throw StateError('Sign in to manage stored accounts.');
    }
    final repo = await ref.read(authRepositoryProvider.future);
    return repo.getStoredAccounts();
  }

  Future<void> deleteStoredAccount(int userId) async {
    final current = state.valueOrNull;
    if (current is! AuthAuthenticated) {
      throw StateError('Sign in to manage stored accounts.');
    }
    if (current.user.id == userId) {
      throw StateError('The account currently in use cannot be removed here.');
    }
    final repo = await ref.read(authRepositoryProvider.future);
    await repo.deleteStoredAccount(userId);
  }

  // --------------------------------------------------------------------------
  // Logout
  // --------------------------------------------------------------------------

  Future<void> logout() async {
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.logout();
      state = const AsyncValue.data(AuthUnauthenticated());
    } catch (e, st) {
      AppLogger.e('Logout error', tag: 'AuthNotifier', error: e, st: st);
      // Still move to unauthenticated even on error
      state = const AsyncValue.data(AuthUnauthenticated());
    }
  }

  // --------------------------------------------------------------------------
  // Profile update
  // --------------------------------------------------------------------------

  Future<AppFailure?> updateProfile({
    String? displayName,
    String? avatarBase64,
    String? themePreference,
    bool? notificationsEnabled,
  }) async {
    final current = state.valueOrNull;
    if (current is! AuthAuthenticated) {
      return const AuthFailure('Not logged in');
    }

    try {
      final repo = await ref.read(authRepositoryProvider.future);
      final result = await repo.updateProfile(
        userId: current.user.id,
        displayName: displayName,
        avatarBase64: avatarBase64,
        themePreference: themePreference,
        notificationsEnabled: notificationsEnabled,
      );
      if (result.error != null) return result.error;
      state = AsyncValue.data(AuthAuthenticated(result.user!));
      return null;
    } catch (e, st) {
      return UnexpectedFailure('Profile update failed',
          error: e, stackTrace: st);
    }
  }

  Future<bool> verifyPassword(String password) async {
    final current = state.valueOrNull;
    if (current is! AuthAuthenticated) return false;
    final repo = await ref.read(authRepositoryProvider.future);
    return repo.verifyUserPassword(current.user.id, password);
  }

  // --------------------------------------------------------------------------
  // Password change
  // --------------------------------------------------------------------------

  Future<AppFailure?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final current = state.valueOrNull;
    if (current is! AuthAuthenticated) {
      return const AuthFailure('Not logged in');
    }

    final repo = await ref.read(authRepositoryProvider.future);
    return repo.changePassword(
      userId: current.user.id,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
  // --------------------------------------------------------------------------
  // Biometric preference
  // --------------------------------------------------------------------------

  Future<bool> getBiometricEnabled() async {
    final repo = await ref.read(authRepositoryProvider.future);
    return repo.getBiometricEnabled();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final repo = await ref.read(authRepositoryProvider.future);
    await repo.saveBiometricEnabled(enabled);
  }

  // --------------------------------------------------------------------------
  // Last username
  // --------------------------------------------------------------------------

  Future<String?> getLastUsername() async {
    final repo = await ref.read(authRepositoryProvider.future);
    return repo.getLastUsername();
  }

  Future<AppFailure?> updateSecurityQuestions({
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    final current = state.valueOrNull;
    if (current is! AuthAuthenticated) {
      return const AuthFailure('Not logged in');
    }

    final repo = await ref.read(authRepositoryProvider.future);
    return repo.updateSecurityQuestions(
      userId: current.user.id,
      password: password,
      securityQuestion: securityQuestion,
      securityAnswer: securityAnswer,
    );
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

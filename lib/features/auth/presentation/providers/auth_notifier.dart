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
  const AuthAuthenticated(this.user);
  final UserModel user;
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

  Future<AuthState> _restoreSession() async {
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      final user = await repo.restoreSession();
      if (user != null) {
        AppLogger.i('Session restored for ${user.username}', tag: 'AuthNotifier');
        return AuthAuthenticated(user);
      }
      return const AuthUnauthenticated();
    } catch (e, st) {
      AppLogger.e('Session restore error', tag: 'AuthNotifier', error: e, st: st);
      return const AuthUnauthenticated();
    }
  }

  /// Public entry-point for biometric login — re-checks the stored session.
  Future<void> restoreSession() async {
    state = const AsyncValue.loading();
    final result = await _restoreSession();
    state = AsyncValue.data(result);
  }

  // --------------------------------------------------------------------------
  // Register
  // --------------------------------------------------------------------------

  Future<void> register({
    required String username,
    required String password,
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
        displayName: displayName,
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer,
      );
      if (result.error != null) {
        state = AsyncValue.data(AuthError(result.error!));
      } else {
        state = AsyncValue.data(AuthAuthenticated(result.user));
      }
    } catch (e, st) {
      state = AsyncValue.data(
        AuthError(UnexpectedFailure('Registration failed', error: e, stackTrace: st)),
      );
    }
  }

  Future<AppFailure?> deleteAccount() async {
    final current = state.valueOrNull;
    if (current is! AuthAuthenticated) return const AuthFailure('Not logged in');
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      final err = await repo.deleteAccount(current.user.id);
      if (err == null) {
        state = const AsyncValue.data(AuthUnauthenticated());
      }
      return err;
    } catch (e, st) {
      return UnexpectedFailure('Account deletion failed', error: e, stackTrace: st);
    }
  }

  Future<String?> getSecurityQuestion(String username) async {
    final repo = await ref.read(authRepositoryProvider.future);
    return repo.getSecurityQuestion(username);
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
      final result = await repo.login(username: username, password: password);
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
    if (current is! AuthAuthenticated) return const AuthFailure('Not logged in');

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
      return UnexpectedFailure('Profile update failed', error: e, stackTrace: st);
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
    if (current is! AuthAuthenticated) return const AuthFailure('Not logged in');

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
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

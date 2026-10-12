import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/myday_database.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/security/secure_pin_service.dart';

class UserSession {
  final String accountId;
  final String name;
  final String handle;
  final String bio;
  final String? email;
  final bool isCloud;
  final bool isBioEnabled;
  final String avatarPath;
  final String coverPath;

  final String? customIdentityKey;
  final String? customPhoneNumber;

  const UserSession({
    required this.accountId,
    required this.name,
    required this.handle,
    required this.bio,
    this.email,
    required this.isCloud,
    required this.isBioEnabled,
    this.avatarPath = '',
    this.coverPath = '',
    this.customIdentityKey,
    this.customPhoneNumber,
  });

  /// 10-digit SIM phone number (e.g. 98XXXXXXXX)
  String get phoneNumber {
    if (customPhoneNumber != null && customPhoneNumber!.trim().isNotEmpty) {
      final digits = customPhoneNumber!.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 10) return digits.substring(digits.length - 10);
      if (digits.isNotEmpty) return digits;
    }
    if (customIdentityKey != null) {
      final digits = customIdentityKey!.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 10) return digits.substring(digits.length - 10);
      if (digits.isNotEmpty) return digits;
    }
    final raw = accountId.toLowerCase().startsWith('local_')
        ? accountId.substring(6)
        : accountId;
    final hash = raw.hashCode.abs();
    final suffix = (hash % 100000000).toString().padLeft(8, '0');
    return '98$suffix';
  }

  String get identityKey {
    if (customPhoneNumber != null && customPhoneNumber!.trim().isNotEmpty) {
      final digits = customPhoneNumber!.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 10) return digits.substring(digits.length - 10);
    }
    if (customIdentityKey != null && customIdentityKey!.trim().isNotEmpty) {
      return customIdentityKey!;
    }
    final raw = accountId.toLowerCase().startsWith('local_')
        ? accountId.substring(6)
        : accountId;
    final clean = raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final suffix = clean.length >= 6 ? clean.substring(0, 6) : clean.padRight(6, '0');
    return 'desk-key-$suffix';
  }

  UserSession copyWith({
    String? accountId,
    String? name,
    String? handle,
    String? bio,
    String? email,
    bool? isCloud,
    bool? isBioEnabled,
    String? avatarPath,
    String? coverPath,
    String? customIdentityKey,
    String? customPhoneNumber,
  }) =>
      UserSession(
        accountId: accountId ?? this.accountId,
        name: name ?? this.name,
        handle: handle ?? this.handle,
        bio: bio ?? this.bio,
        email: email ?? this.email,
        isCloud: isCloud ?? this.isCloud,
        isBioEnabled: isBioEnabled ?? this.isBioEnabled,
        avatarPath: avatarPath ?? this.avatarPath,
        coverPath: coverPath ?? this.coverPath,
        customIdentityKey: customIdentityKey ?? this.customIdentityKey,
        customPhoneNumber: customPhoneNumber ?? this.customPhoneNumber,
      );

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'name': name,
        'handle': handle,
        'bio': bio,
        'email': email,
        'isCloud': isCloud,
        'isBioEnabled': isBioEnabled,
        'avatarPath': avatarPath,
        'coverPath': coverPath,
        'customIdentityKey': customIdentityKey,
        'customPhoneNumber': customPhoneNumber,
      };

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        accountId: json['accountId'] as String,
        name: json['name'] as String,
        handle: json['handle'] as String? ?? 'me',
        bio: json['bio'] as String? ?? '',
        email: json['email'] as String?,
        isCloud: json['isCloud'] as bool? ?? false,
        isBioEnabled: json['isBioEnabled'] as bool? ?? false,
        avatarPath: json['avatarPath'] as String? ?? '',
        coverPath: json['coverPath'] as String? ?? '',
        customIdentityKey: json['customIdentityKey'] as String?,
        customPhoneNumber: json['customPhoneNumber'] as String?,
      );
}

class EmailConfirmationRequiredException implements Exception {
  final String email;
  final String message;
  const EmailConfirmationRequiredException({
    required this.email,
    this.message = 'A confirmation email has been sent. Please confirm your email before signing in.',
  });

  @override
  String toString() => message;
}

class LocalToCloudInitiationResult {
  final bool isCompleted;
  final bool needsEmailConfirmation;
  final UserSession? session;
  final String email;
  final String? message;

  const LocalToCloudInitiationResult({
    required this.isCompleted,
    required this.needsEmailConfirmation,
    this.session,
    required this.email,
    this.message,
  });
}

class AuthRepository {
  final MyDayDatabase db;
  final BiometricService biometricService = BiometricService();
  static const String _sessionKey = 'myday_active_session';
  static const _uuid = Uuid();

  AuthRepository(this.db);

  Future<UserSession?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_sessionKey);
    if (jsonStr == null) return null;
    try {
      return UserSession.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    if (session.isCloud) {
      await prefs.setString('myday_last_cloud_session', jsonEncode(session.toJson()));
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  /// Checks if a local account exists on this device
  Future<Map<String, dynamic>?> getExistingLocalAccount() async {
    final rows = await db.customSelect(
      'SELECT * FROM local_accounts WHERE is_cloud = 0 LIMIT 1',
    ).get();

    if (rows.isEmpty) return null;
    final r = rows.first;
    return {
      'id': r.read<String>('id'),
      'name': r.read<String>('name'),
      'pin_hash': r.read<String>('pin_hash'),
      'bio_enabled': r.read<int>('bio_enabled') == 1,
      'handle': r.read<String>('handle'),
      'bio': r.read<String>('bio'),
    };
  }

  /// Creates a new local account with 4-digit PIN (biometric off by default)
  Future<UserSession> createLocalAccount({
    required String name,
    required String pin,
    bool bioEnabled = false,
  }) async {
    // 1. If an existing local account exists with the same name, update its credentials rather than erasing data
    final existingLocals = await db.customSelect(
      'SELECT id FROM local_accounts WHERE is_cloud = 0 AND name = ?',
      variables: [Variable(name)],
    ).get();
    if (existingLocals.isNotEmpty) {
      final existingId = existingLocals.first.read<String>('id');
      final pinHash = SecurePinService.hashPin(pin);
      await db.customUpdate(
        'UPDATE local_accounts SET pin_hash = ?, bio_enabled = ? WHERE id = ?',
        variables: [Variable(pinHash), Variable(bioEnabled ? 1 : 0), Variable(existingId)],
      );
      final session = UserSession(
        accountId: existingId,
        name: name,
        handle: name.replaceAll(RegExp(r'\W'), '').toLowerCase(),
        bio: '',
        isCloud: false,
        isBioEnabled: bioEnabled,
      );
      await saveSession(session);
      return session;
    }

    final accountId = 'local_${_uuid.v4().substring(0, 8)}';
    final pinHash = SecurePinService.hashPin(pin);
    final now = DateTime.now().millisecondsSinceEpoch;
    final cleanHandle = name.replaceAll(RegExp(r'\W'), '').toLowerCase();

    await db.customInsert(
      '''
      INSERT INTO local_accounts (id, name, pin_hash, bio_enabled, is_cloud, handle, bio, created_at)
      VALUES (?, ?, ?, ?, 0, ?, '', ?)
      ''',
      variables: [
        Variable(accountId),
        Variable(name),
        Variable(pinHash),
        Variable(bioEnabled ? 1 : 0),
        Variable(cleanHandle.isNotEmpty ? cleanHandle : 'me'),
        Variable(now),
      ],
    );

    // Seed default demo tasks, notes, wallets, transactions, budgets, feed
    await db.seedAccountData(accountId);

    final session = UserSession(
      accountId: accountId,
      name: name,
      handle: cleanHandle.isNotEmpty ? cleanHandle : 'me',
      bio: '',
      isCloud: false,
      isBioEnabled: bioEnabled,
    );

    await saveSession(session);
    return session;
  }

  /// Unlocks local account with 4-digit PIN
  Future<UserSession?> loginLocalWithPin(String pin) async {
    final local = await getExistingLocalAccount();
    if (local == null) return null;

    final storedHash = local['pin_hash'] as String;
    if (!SecurePinService.verifyPin(pin, storedHash)) {
      return null;
    }

    final session = UserSession(
      accountId: local['id'] as String,
      name: local['name'] as String,
      handle: local['handle'] as String,
      bio: local['bio'] as String,
      isCloud: false,
      isBioEnabled: local['bio_enabled'] as bool,
    );

    await saveSession(session);
    return session;
  }

  /// Unlocks local account with biometric sensor
  Future<UserSession?> loginLocalWithBiometrics() async {
    final local = await getExistingLocalAccount();
    if (local == null) return null;

    final authenticated = await biometricService.authenticate(
      reason: 'Scan your fingerprint or face to log in to MyDay',
    );
    if (!authenticated) return null;

    final isBio = local['bio_enabled'] as bool;
    if (!isBio) {
      await setBiometricEnabled(local['id'] as String, true);
    }

    final session = UserSession(
      accountId: local['id'] as String,
      name: local['name'] as String,
      handle: local['handle'] as String,
      bio: local['bio'] as String,
      isCloud: false,
      isBioEnabled: true,
    );

    await saveSession(session);
    return session;
  }

  /// Resets and wipes the local account entirely
  Future<void> resetLocalAccount() async {
    final locals = await db.customSelect('SELECT id FROM local_accounts WHERE is_cloud = 0;').get();
    for (final l in locals) {
      final id = l.read<String>('id');
      await db.clearAllUserData(id);
    }
    await clearSession();
    await db.customStatement('DELETE FROM local_accounts WHERE is_cloud = 0;');
  }
  /// Fetches or generates the user's phone number directly from Supabase backend.
  Future<String> fetchBackendPhoneNumber({
    required String userId,
    required String email,
  }) async {
    final client = Supabase.instance.client;

    // 1. Try calling the RPC function get_or_create_phone_number
    try {
      final rpcRes = await client.rpc<dynamic>('get_or_create_phone_number', params: {'p_user_id': userId});
      if (rpcRes != null && rpcRes.toString().trim().isNotEmpty) {
        return rpcRes.toString().trim();
      }
    } catch (_) {}

    // 2. Try selecting from public.profiles directly
    try {
      final row = await client
          .from('profiles')
          .select('phone_number')
          .eq('id', userId)
          .maybeSingle();
      final phone = row?['phone_number'] as String?;
      if (phone != null && phone.trim().isNotEmpty) {
        return phone.trim();
      }
    } catch (_) {}

    // 3. Try calling get_or_create_phone_by_email RPC
    try {
      final rpcRes = await client.rpc<dynamic>('get_or_create_phone_by_email', params: {'p_email': email});
      if (rpcRes != null && rpcRes.toString().trim().isNotEmpty) {
        return rpcRes.toString().trim();
      }
    } catch (_) {}

    // 4. Fallback if backend network is temporarily unreachable
    final digits = email.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 8) {
      return '98${digits.substring(0, 8)}';
    }
    final hash = email.hashCode.abs();
    final suffix = (hash % 100000000).toString().padLeft(8, '0');
    return '98$suffix';
  }

  /// Cloud Login / Register with Supabase
  Future<UserSession> authenticateCloud({
    required String email,
    required String password,
    String? name,
    bool isRegister = false,
  }) async {
    final client = Supabase.instance.client;

    if (isRegister) {
      // Step 1: Check if user already exists with this password first.
      // This saves email quota, avoids duplicate signups, and eliminates rate limits!
      try {
        final existingLogin = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (existingLogin.user != null) {
          final user = existingLogin.user!;
          final finalName = name ?? user.userMetadata?['name'] as String? ?? email.split('@')[0];
          final handle = finalName.replaceAll(RegExp(r'\W'), '').toLowerCase();
          final phone = await fetchBackendPhoneNumber(userId: user.id, email: email);

          final session = UserSession(
            accountId: user.id,
            name: finalName,
            handle: handle,
            bio: '',
            email: email,
            isCloud: true,
            isBioEnabled: true,
            customPhoneNumber: phone,
            customIdentityKey: phone,
          );

          try {
            await client.from('profiles').upsert({
              'id': user.id,
              'email': email,
              'username': handle,
              'display_name': finalName,
              'phone_number': phone,
              'identity_key': phone,
              'updated_at': DateTime.now().toIso8601String(),
            });
          } catch (_) {}

          await db.seedAccountData(session.accountId);
          await saveSession(session);
          return session;
        }
      } on AuthException catch (existingErr) {
        if (existingErr.message.toLowerCase().contains('email not confirmed')) {
          throw EmailConfirmationRequiredException(
            email: email,
            message: 'An account for $email is awaiting confirmation. Please check your inbox and verify your email.',
          );
        }
      }

      // Step 2: User is not yet signed up with this password, call signUp
      try {
        final res = await client.auth.signUp(
          email: email,
          password: password,
          data: {'name': name ?? email.split('@')[0]},
        );

        User? user = res.user;

        // In Supabase, if an account already exists with a different password,
        // GoTrue returns a user with empty identities list instead of throwing an error.
        if (user != null && (user.identities == null || user.identities!.isEmpty)) {
          throw const AuthException(
            'An account with this email already exists. Please sign in with your password, or use Forgot Password.',
          );
        }

        // If session is null (due to Supabase email confirmation settings),
        // try signing in immediately because auto_confirm trigger automatically confirms new users.
        if (res.session == null) {
          try {
            final loginRes = await client.auth.signInWithPassword(
              email: email,
              password: password,
            );
            if (loginRes.user != null) {
              user = loginRes.user;
            }
          } catch (_) {}
        }

        if (user == null) {
          throw const AuthException('Registration failed. Please check your email and password.');
        }

        // If user was created but session is still null and signIn failed, confirmation is pending
        if (client.auth.currentSession == null && res.session == null) {
          throw EmailConfirmationRequiredException(
            email: email,
            message: 'Confirmation link sent to $email. Please check your inbox and verify your email before logging in.',
          );
        }

        final finalName = name ?? email.split('@')[0];
        final handle = finalName.replaceAll(RegExp(r'\W'), '').toLowerCase();
        final phone = await fetchBackendPhoneNumber(userId: user.id, email: email);

        final session = UserSession(
          accountId: user.id,
          name: finalName,
          handle: handle,
          bio: '',
          email: email,
          isCloud: true,
          isBioEnabled: true,
          customPhoneNumber: phone,
          customIdentityKey: phone,
        );

        try {
          await client.from('profiles').upsert({
            'id': user.id,
            'email': email,
            'username': handle,
            'display_name': finalName,
            'phone_number': phone,
            'identity_key': phone,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}

        try {
          await db.customInsert(
            '''
            INSERT INTO local_accounts (id, name, email, pin_hash, bio_enabled, is_cloud, handle, bio, created_at)
            VALUES (?, ?, ?, '', 1, 1, ?, '', ?)
            ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email, name = EXCLUDED.name, handle = EXCLUDED.handle;
            ''',
            variables: [
              Variable(user.id),
              Variable(finalName),
              Variable(email),
              Variable(handle),
              Variable(DateTime.now().millisecondsSinceEpoch),
            ],
          );
        } catch (_) {}

        await db.seedAccountData(session.accountId);
        await saveSession(session);
        return session;
      } on AuthException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('already registered') ||
            msg.contains('already exists') ||
            msg.contains('user already exists')) {
          throw const AuthException(
            'An account with this email already exists. Please log in with your password or use Forgot Password.',
          );
        }
        if (msg.contains('rate limit') || msg.contains('security purposes')) {
          // Check if we can sign in right now in case user was confirmed in backend
          try {
            final loginRes = await client.auth.signInWithPassword(email: email, password: password);
            if (loginRes.user != null) {
              final user = loginRes.user!;
              final finalName = name ?? user.userMetadata?['name'] as String? ?? email.split('@')[0];
              final handle = finalName.replaceAll(RegExp(r'\W'), '').toLowerCase();
              final phone = await fetchBackendPhoneNumber(userId: user.id, email: email);
              final session = UserSession(
                accountId: user.id,
                name: finalName,
                handle: handle,
                bio: '',
                email: email,
                isCloud: true,
                isBioEnabled: true,
                customPhoneNumber: phone,
                customIdentityKey: phone,
              );
              await saveSession(session);
              return session;
            }
          } catch (_) {}
          throw const AuthException(
            'Email rate limit reached. Please wait a minute before requesting another confirmation email.',
          );
        }
        rethrow;
      }
    } else {
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw const AuthException('Login failed. Please check your credentials.');
      }

      final finalName =
          user.userMetadata?['name'] as String? ?? email.split('@')[0];
      final handle = finalName.replaceAll(RegExp(r'\W'), '').toLowerCase();
      final phone = await fetchBackendPhoneNumber(userId: user.id, email: email);

      final session = UserSession(
        accountId: user.id,
        name: finalName,
        handle: handle,
        bio: '',
        email: email,
        isCloud: true,
        isBioEnabled: true,
        customPhoneNumber: phone,
        customIdentityKey: phone,
      );

      try {
        await client.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'username': handle,
          'display_name': finalName,
          'phone_number': phone,
          'identity_key': phone,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      try {
        await db.customInsert(
          '''
          INSERT INTO local_accounts (id, name, email, pin_hash, bio_enabled, is_cloud, handle, bio, created_at)
          VALUES (?, ?, ?, '', 1, 1, ?, '', ?)
          ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email, name = EXCLUDED.name, handle = EXCLUDED.handle;
          ''',
          variables: [
            Variable(user.id),
            Variable(finalName),
            Variable(email),
            Variable(handle),
            Variable(DateTime.now().millisecondsSinceEpoch),
          ],
        );
      } catch (_) {}

      await db.seedAccountData(session.accountId);
      await saveSession(session);
      return session;
    }
  }

  /// Updates profile details (Name, Handle, Bio, Avatar, Cover)
  Future<UserSession> updateProfile({
    required UserSession currentSession,
    required String newName,
    required String newHandle,
    required String newBio,
    String? newAvatarPath,
    String? newCoverPath,
  }) async {
    final cleanHandle = newHandle.replaceAll(RegExp(r'\W'), '').toLowerCase();
    final avatar = newAvatarPath ?? currentSession.avatarPath;
    final cover = newCoverPath ?? currentSession.coverPath;

    await db.customUpdate(
      '''
      UPDATE local_accounts
      SET name = ?, handle = ?, bio = ?
      WHERE id = ?
      ''',
      variables: [
        Variable(newName),
        Variable(cleanHandle),
        Variable(newBio),
        Variable(currentSession.accountId),
      ],
    );

    final updated = UserSession(
      accountId: currentSession.accountId,
      name: newName,
      handle: cleanHandle,
      bio: newBio,
      email: currentSession.email,
      isCloud: currentSession.isCloud,
      isBioEnabled: currentSession.isBioEnabled,
      avatarPath: avatar,
      coverPath: cover,
      customPhoneNumber: currentSession.customPhoneNumber,
      customIdentityKey: currentSession.customIdentityKey,
    );

    await saveSession(updated);
    return updated;
  }

  /// Resends signup confirmation email
  Future<void> resendConfirmationEmail(String email) async {
    final client = Supabase.instance.client;
    await client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  /// Sends a password reset link to user email
  Future<void> sendPasswordResetEmail(String email) async {
    final client = Supabase.instance.client;
    await client.auth.resetPasswordForEmail(email);
  }

  /// Initiates converting a local account into a cloud account.
  /// Intelligently checks existing credentials first to avoid wasteful emails & rate limits.
  Future<LocalToCloudInitiationResult> initiateLocalToCloudConversion({
    required UserSession localSession,
    required String email,
    required String password,
  }) async {
    final client = Supabase.instance.client;

    // STEP 1: Attempt signInWithPassword FIRST.
    // If the account already exists (common when user re-enters or already registered):
    // signInWithPassword consumes ZERO email quota, does NOT trigger confirmation emails,
    // and immediately succeeds if confirmed!
    try {
      final loginRes = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (loginRes.user != null) {
        final session = await _finalizeLocalToCloudMigration(
          localSession: localSession,
          user: loginRes.user!,
          email: email,
        );
        return LocalToCloudInitiationResult(
          isCompleted: true,
          needsEmailConfirmation: false,
          session: session,
          email: email,
          message: 'Account successfully converted to Cloud!',
        );
      }
    } on AuthException catch (loginErr) {
      final loginMsg = loginErr.message.toLowerCase();
      if (loginMsg.contains('email not confirmed')) {
        // User exists and credentials are correct, but email is awaiting confirmation.
        // We do NOT call signUp or burn rate limit!
        return LocalToCloudInitiationResult(
          isCompleted: false,
          needsEmailConfirmation: true,
          email: email,
          message: 'A confirmation link was previously sent to $email. Please check your inbox.',
        );
      }
      // If error is invalid login credentials, fall through to step 2 to attempt signUp
    }

    // STEP 2: Only call signUp if user does not have an active confirmed session
    try {
      final res = await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': localSession.name},
      );

      // If auto-confirmed or session provided immediately
      if (res.session != null && res.user != null) {
        final session = await _finalizeLocalToCloudMigration(
          localSession: localSession,
          user: res.user!,
          email: email,
        );
        return LocalToCloudInitiationResult(
          isCompleted: true,
          needsEmailConfirmation: false,
          session: session,
          email: email,
          message: 'Account successfully converted to Cloud!',
        );
      }

      // If user was created, email confirmation was sent
      return LocalToCloudInitiationResult(
        isCompleted: false,
        needsEmailConfirmation: true,
        email: email,
        message: 'Confirmation link sent to $email.',
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();

      // If rate limited, check if we can still sign in
      if (msg.contains('rate limit') || msg.contains('security purposes')) {
        try {
          final loginRes = await client.auth.signInWithPassword(
            email: email,
            password: password,
          );
          if (loginRes.user != null) {
            final session = await _finalizeLocalToCloudMigration(
              localSession: localSession,
              user: loginRes.user!,
              email: email,
            );
            return LocalToCloudInitiationResult(
              isCompleted: true,
              needsEmailConfirmation: false,
              session: session,
              email: email,
              message: 'Account successfully converted to Cloud!',
            );
          }
        } catch (_) {}

        throw const AuthException(
          'Email rate limit reached. Please wait a minute before requesting another confirmation email.',
        );
      }

      if (msg.contains('already registered') ||
          msg.contains('already exists') ||
          msg.contains('user already exists')) {
        throw AuthException(
          'An account with $email already exists. Please verify your password or log in directly.',
        );
      }

      rethrow;
    }
  }

  /// Completes the cloud conversion after the user has confirmed their email.
  Future<UserSession> completeLocalToCloudConversion({
    required UserSession localSession,
    required String email,
    required String password,
  }) async {
    final client = Supabase.instance.client;

    try {
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw const AuthException('Could not verify login. Please check your credentials and try again.');
      }

      return await _finalizeLocalToCloudMigration(
        localSession: localSession,
        user: user,
        email: email,
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        throw const AuthException(
          'Email has not been confirmed yet. Please open the confirmation link sent to your email inbox, then tap here again.',
        );
      }
      rethrow;
    }
  }

  /// Finalizes the migration of local SQLite records to the cloud user ID
  Future<UserSession> _finalizeLocalToCloudMigration({
    required UserSession localSession,
    required User user,
    required String email,
  }) async {
    final client = Supabase.instance.client;
    final cloudAccountId = user.id;

    // 1. Fetch real backend phone number from Supabase
    final backendPhone = await fetchBackendPhoneNumber(
      userId: cloudAccountId,
      email: email,
    );

    // 2. Migrate all local Drift database records to the new Supabase cloud user ID
    final tables = [
      'tasks',
      'notes',
      'wallets',
      'transactions',
      'budgets',
      'feed_posts',
      'stories',
      'stored_files',
    ];

    for (final table in tables) {
      try {
        await db.customUpdate(
          'UPDATE $table SET account_id = ? WHERE account_id = ?',
          variables: [Variable(cloudAccountId), Variable(localSession.accountId)],
        );
      } catch (_) {}
    }

    // 3. Update local_accounts table
    try {
      await db.customUpdate(
        'UPDATE local_accounts SET id = ?, email = ?, is_cloud = 1 WHERE id = ?',
        variables: [
          Variable(cloudAccountId),
          Variable(email),
          Variable(localSession.accountId),
        ],
      );
    } catch (_) {}

    // 4. Construct updated cloud UserSession with real backend phone number
    final updated = UserSession(
      accountId: cloudAccountId,
      name: localSession.name,
      handle: localSession.handle,
      bio: localSession.bio,
      email: email,
      isCloud: true,
      isBioEnabled: localSession.isBioEnabled,
      avatarPath: localSession.avatarPath,
      coverPath: localSession.coverPath,
      customPhoneNumber: backendPhone,
      customIdentityKey: backendPhone,
    );

    // 5. Ensure public.profiles in Supabase has the phone number and user info
    try {
      await client.from('profiles').upsert({
        'id': cloudAccountId,
        'email': email,
        'username': localSession.handle,
        'display_name': localSession.name,
        'phone_number': backendPhone,
        'identity_key': backendPhone,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    await saveSession(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('myday_last_cloud_session', jsonEncode(updated.toJson()));

    return updated;
  }

  /// Converts a local account into a cloud account and migrates all existing records
  Future<UserSession> convertLocalToCloudAccount({
    required UserSession localSession,
    required String email,
    required String password,
  }) async {
    final result = await initiateLocalToCloudConversion(
      localSession: localSession,
      email: email,
      password: password,
    );

    if (result.isCompleted && result.session != null) {
      return result.session!;
    }

    if (result.needsEmailConfirmation) {
      throw EmailConfirmationRequiredException(
        email: email,
        message: 'Confirmation link sent to $email. Please check your inbox and verify your email to complete setup.',
      );
    }

    throw const AuthException('Cloud conversion failed. Please try again.');
  }

  /// Retrieves the last cloud session for biometric quick login
  Future<UserSession?> getLastCloudSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('myday_last_cloud_session');
    if (jsonStr == null) return null;
    try {
      return UserSession.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Unlocks last cloud session via biometric sensor
  Future<UserSession?> loginCloudWithBiometrics() async {
    final last = await getLastCloudSession();
    if (last == null) return null;
    final authenticated = await biometricService.authenticate();
    if (!authenticated) return null;
    await saveSession(last);
    return last;
  }

  /// Sets biometric enabled flag for the given account id
  Future<void> setBiometricEnabled(String accountId, bool enabled) async {
    await db.customUpdate(
      'UPDATE local_accounts SET bio_enabled = ? WHERE id = ?',
      variables: [Variable(enabled ? 1 : 0), Variable(accountId)],
    );
    final current = await getActiveSession();
    if (current != null && current.accountId == accountId) {
      await saveSession(current.copyWith(isBioEnabled: enabled));
    }
  }

  /// Toggles biometric setting for the local or cloud account
  Future<void> toggleBiometric(UserSession session, bool enabled) async {
    if (!session.isCloud) {
      await db.customUpdate(
        'UPDATE local_accounts SET bio_enabled = ? WHERE id = ?',
        variables: [Variable(enabled ? 1 : 0), Variable(session.accountId)],
      );
    }
    final updated = UserSession(
      accountId: session.accountId,
      name: session.name,
      handle: session.handle,
      bio: session.bio,
      email: session.email,
      isCloud: session.isCloud,
      isBioEnabled: enabled,
      avatarPath: session.avatarPath,
      coverPath: session.coverPath,
    );
    await saveSession(updated);
  }

  /// Export all user data as JSON
  Future<String> exportDataJson(String accountId) async {
    final tasks = await db.customSelect(
      'SELECT * FROM tasks WHERE account_id = ? AND is_deleted = 0',
      variables: [Variable(accountId)],
    ).get();

    final notes = await db.customSelect(
      'SELECT * FROM notes WHERE account_id = ? AND is_deleted = 0',
      variables: [Variable(accountId)],
    ).get();

    final wallets = await db.customSelect(
      'SELECT * FROM wallets WHERE account_id = ? AND is_deleted = 0',
      variables: [Variable(accountId)],
    ).get();

    final tx = await db.customSelect(
      'SELECT * FROM transactions WHERE account_id = ? AND is_deleted = 0',
      variables: [Variable(accountId)],
    ).get();

    final budgets = await db.customSelect(
      'SELECT * FROM budgets WHERE account_id = ? AND is_deleted = 0',
      variables: [Variable(accountId)],
    ).get();

    final posts = await db.customSelect(
      'SELECT * FROM feed_posts WHERE account_id = ? AND is_deleted = 0',
      variables: [Variable(accountId)],
    ).get();

    final exportMap = {
      'exportDate': DateTime.now().toIso8601String(),
      'accountId': accountId,
      'tasks': tasks.map((r) => r.data).toList(),
      'notes': notes.map((r) => r.data).toList(),
      'wallets': wallets.map((r) => r.data).toList(),
      'transactions': tx.map((r) => r.data).toList(),
      'budgets': budgets.map((r) => r.data).toList(),
      'feed': posts.map((r) => r.data).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportMap);
  }

  /// Wipes all productivity data for the account
  Future<void> wipeAccountData(String accountId) async {
    final tables = [
      'tasks',
      'notes',
      'wallets',
      'transactions',
      'budgets',
      'feed_posts',
      'stories',
      'stored_files',
    ];

    for (final table in tables) {
      await db.customUpdate(
        'DELETE FROM $table WHERE account_id = ?',
        variables: [Variable(accountId)],
      );
    }

    // Re-seed with fresh data
    await db.seedAccountData(accountId);
  }
}

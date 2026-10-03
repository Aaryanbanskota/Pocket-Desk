import 'package:isar/isar.dart';

part 'user_model.g.dart';

/// Local user account stored in Isar.
///
/// Passwords are NEVER stored in plaintext.
/// [passwordHash] stores the Argon2id-derived key as a hex string.
/// [passwordSalt] stores the random salt as a hex string.
@collection
class UserModel {
  UserModel();

  Id id = Isar.autoIncrement;

  /// Unique username chosen by the user.
  @Index(unique: true, replace: false)
  late String username;

  /// User's email address (Gmail)
  @Index()
  String? email;

  /// Argon2id hash of the password (hex-encoded).
  late String passwordHash;

  /// Random salt used during hashing (hex-encoded).
  late String passwordSalt;

  /// Cloud account master password hash (if converted from local).
  String? cloudPasswordHash;

  /// Cloud account master password salt (if converted from local).
  String? cloudPasswordSalt;

  /// Optional display name (may differ from username).
  String? displayName;

  /// Base64-encoded avatar image bytes, or null if no avatar.
  String? avatarBase64;

  /// Preferred theme: 'system' | 'light' | 'dark'.
  @Index()
  String themePreference = 'system';

  /// Whether notifications are enabled.
  bool notificationsEnabled = true;

  /// RFC 3339 timestamp of account creation.
  late DateTime createdAt;

  /// RFC 3339 timestamp of last login.
  DateTime? lastLoginAt;

  /// Unique device identifier for this installation.
  late String deviceId;

  /// Security question for password recovery.
  String? securityQuestion;

  /// Argon2id hash of the security answer (lowercased & trimmed).
  String? securityAnswerHash;

  /// Salt used for security answer hash.
  String? securityAnswerSalt;
}

/// Base class for all domain-level failures in PocketDesk.
///
/// Use sealed subclasses for exhaustive pattern matching.
sealed class AppFailure {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Database read / write failures.
final class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message);
}

/// Network / WebSocket failures.
final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

/// Authentication failures (wrong password, locked, etc.).
final class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

/// Synchronization failures.
final class SyncFailure extends AppFailure {
  const SyncFailure(super.message);
}

/// Serialization / deserialization failures.
final class SerializationFailure extends AppFailure {
  const SerializationFailure(super.message);
}

/// File I/O failures.
final class FileFailure extends AppFailure {
  const FileFailure(super.message);
}

/// Unexpected failures not covered by other types.
final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure(super.message, {this.error, this.stackTrace});
  final Object? error;
  final StackTrace? stackTrace;
}

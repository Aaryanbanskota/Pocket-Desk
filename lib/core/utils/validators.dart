/// Input validation functions for PocketDesk forms.
abstract final class Validators {
  static const int _minPasswordLength = 8;
  static const int _maxUsernameLength = 32;
  static const int _minUsernameLength = 2;

  // --------------------------------------------------------------------------
  // Username
  // --------------------------------------------------------------------------

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    final v = value.trim();
    if (v.length < _minUsernameLength) {
      return 'Username must be at least $_minUsernameLength characters';
    }
    if (v.length > _maxUsernameLength) {
      return 'Username must be at most $_maxUsernameLength characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(v)) {
      return 'Username may only contain letters, numbers, _, ., -';
    }
    return null;
  }

  // --------------------------------------------------------------------------
  // Password
  // --------------------------------------------------------------------------

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < _minPasswordLength) {
      return 'Password must be at least $_minPasswordLength characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one digit';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != original) {
      return 'Passwords do not match';
    }
    return null;
  }

  // --------------------------------------------------------------------------
  // General
  // --------------------------------------------------------------------------

  /// Returns error message if [value] is null or blank.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? maxLength(String? value, int max,
      {String fieldName = 'Field'}) {
    if (value != null && value.length > max) {
      return '$fieldName must be at most $max characters';
    }
    return null;
  }

  // --------------------------------------------------------------------------
  // Compose validators (run list, return first error)
  // --------------------------------------------------------------------------

  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final v in validators) {
        final result = v(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}

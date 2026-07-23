/// String extension methods for PocketDesk.
extension StringX on String {
  /// Capitalizes only the first letter.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Converts "hello_world" → "Hello World".
  String get titleCase => split('_')
      .map((w) => w.capitalized)
      .join(' ');

  /// Truncates to [maxLength] chars and appends [ellipsis].
  String truncate(int maxLength, {String ellipsis = '…'}) =>
      length <= maxLength ? this : '${substring(0, maxLength)}$ellipsis';

  /// Removes all whitespace.
  String get stripped => replaceAll(RegExp(r'\s+'), '');

  /// Returns true when this is a plausible e-mail address.
  bool get isEmail =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(this);

  /// Returns true if the string has no visible characters.
  bool get isBlank => trim().isEmpty;

  /// Returns the string if non-blank, otherwise null.
  String? get nullIfBlank => isBlank ? null : this;

  /// Returns initials from a name: "John Doe" → "JD".
  String get initials => split(' ')
      .where((s) => s.isNotEmpty)
      .take(2)
      .map((s) => s[0].toUpperCase())
      .join();
}

/// Nullable string helpers.
extension NullableStringX on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
  String get orEmpty => this ?? '';
}

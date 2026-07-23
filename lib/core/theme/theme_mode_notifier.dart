import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _themeModeKey = 'pocketdesk_theme_mode';

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  late final FlutterSecureStorage _storage;

  @override
  Future<ThemeMode> build() async {
    _storage = const FlutterSecureStorage();
    final stored = await _storage.read(key: _themeModeKey);
    return _fromString(stored);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(mode);
    await _storage.write(key: _themeModeKey, value: mode.name);
  }

  Future<void> toggleTheme() async {
    final current = state.valueOrNull ?? ThemeMode.system;
    final next = switch (current) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setThemeMode(next);
  }

  ThemeMode _fromString(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

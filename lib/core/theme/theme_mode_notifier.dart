import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:io' show Platform;

const String _themeModeKey = 'pocketdesk_theme_mode';
final bool _isTest = Platform.environment.containsKey('FLUTTER_TEST');

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  late final FlutterSecureStorage _storage;

  @override
  Future<ThemeMode> build() async {
    _storage = const FlutterSecureStorage();
    try {
      final Future<String?> readFuture = _storage.read(key: _themeModeKey);
      final stored = await (_isTest ? readFuture : readFuture.timeout(const Duration(seconds: 1)));
      return _fromString(stored);
    } catch (e) {
      // Fallback to system theme if Secure Storage initialization or read fails
      return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(mode);
    try {
      final Future<void> writeFuture = _storage.write(key: _themeModeKey, value: mode.name);
      await (_isTest ? writeFuture : writeFuture.timeout(const Duration(seconds: 1)));
    } catch (e) {
      // Ignore write failures due to storage hangs
    }
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

const String _textScaleKey = 'pocketdesk_text_scale';

class TextScaleNotifier extends AsyncNotifier<double> {
  late final FlutterSecureStorage _storage;

  @override
  Future<double> build() async {
    _storage = const FlutterSecureStorage();
    try {
      final Future<String?> readFuture = _storage.read(key: _textScaleKey);
      final stored = await (_isTest ? readFuture : readFuture.timeout(const Duration(seconds: 1)));
      if (stored != null) {
        return double.tryParse(stored) ?? 1.0;
      }
      return 1.0;
    } catch (e) {
      return 1.0;
    }
  }

  Future<void> setTextScale(double scale) async {
    state = AsyncData(scale);
    try {
      final Future<void> writeFuture = _storage.write(key: _textScaleKey, value: scale.toString());
      await (_isTest ? writeFuture : writeFuture.timeout(const Duration(seconds: 1)));
    } catch (e) {
      // Ignore write failures
    }
  }
}

final textScaleProvider =
    AsyncNotifierProvider<TextScaleNotifier, double>(TextScaleNotifier.new);

const String _enableRearrangeKey = 'pocketdesk_enable_rearrange';

class EnableRearrangeNotifier extends AsyncNotifier<bool> {
  late final FlutterSecureStorage _storage;

  @override
  Future<bool> build() async {
    _storage = const FlutterSecureStorage();
    try {
      final Future<String?> readFuture = _storage.read(key: _enableRearrangeKey);
      final stored = await (_isTest ? readFuture : readFuture.timeout(const Duration(seconds: 1)));
      if (stored != null) {
        return stored == 'true';
      }
      return false; // Disabled by default
    } catch (e) {
      return false;
    }
  }

  Future<void> setEnableRearrange(bool enabled) async {
    state = AsyncData(enabled);
    try {
      final Future<void> writeFuture =
          _storage.write(key: _enableRearrangeKey, value: enabled.toString());
      await (_isTest ? writeFuture : writeFuture.timeout(const Duration(seconds: 1)));
    } catch (e) {
      // Ignore write failures
    }
  }
}

final enableRearrangeProvider =
    AsyncNotifierProvider<EnableRearrangeNotifier, bool>(EnableRearrangeNotifier.new);

const String _shareTabUnlockedKey = 'pocketdesk_share_tab_unlocked';

class ShareTabUnlockedNotifier extends AsyncNotifier<bool> {
  late final FlutterSecureStorage _storage;

  @override
  Future<bool> build() async {
    _storage = const FlutterSecureStorage();
    try {
      final Future<String?> readFuture = _storage.read(key: _shareTabUnlockedKey);
      final stored = await (_isTest ? readFuture : readFuture.timeout(const Duration(seconds: 1)));
      return stored == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> unlockShareTab() async {
    state = const AsyncData(true);
    try {
      final Future<void> writeFuture =
          _storage.write(key: _shareTabUnlockedKey, value: 'true');
      await (_isTest ? writeFuture : writeFuture.timeout(const Duration(seconds: 1)));
    } catch (_) {}
  }
}

final shareTabUnlockedProvider =
    AsyncNotifierProvider<ShareTabUnlockedNotifier, bool>(ShareTabUnlockedNotifier.new);

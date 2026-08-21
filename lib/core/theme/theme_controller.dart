import 'package:auth_katalog_app/core/di/providers.dart';
import 'package:auth_katalog_app/core/theme/theme_mode_codec.dart';
import 'package:auth_katalog_app/core/theme/theme_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Async state for a theme-mode read (holds [ThemeMode], or its error).
final themeModeProvider =
    AsyncNotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

/// Owns the app's [ThemeMode] (light/dark/system) and persists every change
/// through the injected [ThemePreferencesStore]. Lives in `core/`, so no
/// feature imports it — [App] watches it and MaterialApp.router consumes it.
class ThemeController extends AsyncNotifier<ThemeMode> {
  Future<ThemePreferencesStore> get _store =>
      ref.read(themePreferencesStoreProvider);

  /// Loads the persisted mode on first build; falls back to system.
  @override
  Future<ThemeMode> build() async {
    final store = await _store;
    final raw = await store.read();
    return themeModeFromString(raw);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = const AsyncLoading();
    final persisted = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    // Best-effort persistence: a storage failure should not block the UI
    // switch — the state is still set and the app re-reads next launch.
    (await _store).write(persisted);
    state = AsyncData(mode);
  }
}
import 'dart:async';

/// Theme-mode persistence for theme_preferences_provider.
///
/// Kept tiny and static because the DI graph needs a plain synchronous
/// constructor (immediate read + injectable [SharedPreferences]). The (slow)
/// async state read/write lives in [ThemeController] on top of this storage.
abstract interface class ThemePreferencesStore {
  Future<String?> read();

  Future<void> write(String mode);

  Future<void> clear();
}
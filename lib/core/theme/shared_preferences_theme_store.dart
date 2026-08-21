import 'package:auth_katalog_app/core/theme/theme_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [SharedPreferences] implementation of [ThemePreferencesStore]. Theme mode is
/// non-sensitive (unlike auth tokens, which stay in flutter_secure_storage).
class SharedPreferencesThemeStore implements ThemePreferencesStore {
  SharedPreferencesThemeStore(this._prefs);

  static const _key = 'themeMode';

  final SharedPreferences _prefs;

  @override
  Future<String?> read() async => _prefs.getString(_key);

  @override
  Future<void> write(String mode) => _prefs.setString(_key, mode);

  @override
  Future<void> clear() => _prefs.remove(_key);
}
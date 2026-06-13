import 'package:shared_preferences/shared_preferences.dart';

/// Persists user preferences (theme mode) across sessions.
class SettingsService {
  static const _keyThemeMode = 'theme_mode'; // 'dark' | 'light' | 'system'

  static SettingsService? _instance;
  late SharedPreferences _prefs;

  SettingsService._();

  static Future<SettingsService> getInstance() async {
    if (_instance == null) {
      _instance = SettingsService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'dark';

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }
}

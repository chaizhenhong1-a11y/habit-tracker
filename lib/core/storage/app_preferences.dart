import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences(this._preferences);

  static const _themeModeKey = 'theme_mode';
  static const _seedColorKey = 'seed_color';
  static const _isLoggedInKey = 'is_logged_in';
  static const _languageKey = 'language';

  static const defaultSeedColor = Color(0xFF8E97FD);
  static const defaultLocale = Locale('zh');

  final SharedPreferences _preferences;

  ThemeMode get themeMode {
    switch (_preferences.getString(_themeModeKey)) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  Color get seedColor =>
      Color(_preferences.getInt(_seedColorKey) ?? defaultSeedColor.toARGB32());

  bool get isLoggedIn => _preferences.getBool(_isLoggedInKey) ?? false;

  Locale get locale => Locale(
    _preferences.getString(_languageKey) ?? defaultLocale.languageCode,
  );

  Future<void> setThemeMode(ThemeMode mode) {
    return _preferences.setString(_themeModeKey, mode.name);
  }

  Future<void> setSeedColor(Color color) {
    return _preferences.setInt(_seedColorKey, color.toARGB32());
  }

  Future<void> setLoggedIn(bool value) {
    return _preferences.setBool(_isLoggedInKey, value);
  }

  Future<void> setLocale(Locale locale) {
    return _preferences.setString(_languageKey, locale.languageCode);
  }
}

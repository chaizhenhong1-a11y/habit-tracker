import 'package:flutter/material.dart';

import '../core/storage/app_preferences.dart';

class AppController extends ChangeNotifier {
  AppController(this._preferences);

  final AppPreferences _preferences;

  ThemeMode _themeMode = ThemeMode.light;
  Color _seedColor = AppPreferences.defaultSeedColor;
  Locale _locale = AppPreferences.defaultLocale;
  bool _isLoggedIn = false;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  Locale get locale => _locale;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> load() async {
    _themeMode = _preferences.themeMode;
    _seedColor = _preferences.seedColor;
    _locale = _preferences.locale;
    _isLoggedIn = _preferences.isLoggedIn;
  }

  Future<void> changeThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _preferences.setThemeMode(mode);
  }

  Future<void> changeSeedColor(Color color) async {
    if (_seedColor.toARGB32() == color.toARGB32()) return;
    _seedColor = color;
    notifyListeners();
    await _preferences.setSeedColor(color);
  }

  Future<void> changeLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    await _preferences.setLocale(locale);
  }

  Future<void> setLoggedIn(bool value) async {
    if (_isLoggedIn == value) return;
    _isLoggedIn = value;
    notifyListeners();
    await _preferences.setLoggedIn(value);
  }
}

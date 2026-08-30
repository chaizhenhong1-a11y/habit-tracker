import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habittracker/app/app_controller.dart';
import 'package:habittracker/core/storage/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppController loads persisted application settings', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'dark',
      'seed_color': const Color(0xFF6750A4).toARGB32(),
      'is_logged_in': true,
      'language': 'en',
    });

    final sharedPreferences = await SharedPreferences.getInstance();
    final controller = AppController(AppPreferences(sharedPreferences));

    await controller.load();

    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.seedColor.toARGB32(), const Color(0xFF6750A4).toARGB32());
    expect(controller.isLoggedIn, isTrue);
    expect(controller.locale, const Locale('en'));
  });
}

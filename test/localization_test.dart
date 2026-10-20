import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habittracker/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Both languages cover every UI translation key', () {
    final en =
        jsonDecode(File('assets/l10n/en.json').readAsStringSync()) as Map;
    final zh =
        jsonDecode(File('assets/l10n/zh.json').readAsStringSync()) as Map;
    final keyPattern = RegExp(r"(?:translate|text)\(\s*'([^']+)'");
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final match in keyPattern.allMatches(file.readAsStringSync())) {
        final key = match.group(1)!;
        expect(
          en.containsKey(key),
          isTrue,
          reason: 'English: $key in ${file.path}',
        );
        expect(
          zh.containsKey(key),
          isTrue,
          reason: 'Chinese: $key in ${file.path}',
        );
      }
    }
    for (final key in en.keys.toSet().intersection(zh.keys.toSet())) {
      final placeholders = RegExp(r'\{[^}]+\}');
      expect(
        placeholders
            .allMatches(en[key] as String)
            .map((m) => m.group(0))
            .toSet(),
        placeholders
            .allMatches(zh[key] as String)
            .map((m) => m.group(0))
            .toSet(),
        reason: 'Placeholders must match: $key',
      );
    }
  });

  test('Locales load translated UI and interpolate progress', () async {
    final zh = AppLocalizations(const Locale('zh'));
    final en = AppLocalizations(const Locale('en'));
    await zh.load();
    await en.load();
    expect(zh.text('navToday'), '今日');
    expect(en.text('navToday'), 'Today');
    expect(zh.text('todayCompleted', {'done': 2, 'total': 3}), '已完成 2 / 3');
    expect(
      en.text('todayCompleted', {'done': 2, 'total': 3}),
      '2 / 3 completed',
    );
  });
}

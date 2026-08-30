import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/diary_entry.dart';
import '../../domain/repositories/diary_repository.dart';

class SharedPreferencesDiaryRepository implements DiaryRepository {
  static const _storageKey = 'diary_entries';

  @override
  Future<List<DiaryEntry>> getAll() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedEntries = preferences.getStringList(_storageKey) ?? const [];

    final entries = encodedEntries.map((encoded) {
      final map = jsonDecode(encoded) as Map<String, dynamic>;
      return DiaryEntry.fromJson(map);
    }).toList();

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  @override
  Future<void> replaceAll(List<DiaryEntry> entries) async {
    final preferences = await SharedPreferences.getInstance();
    final encodedEntries = entries
        .map((entry) => jsonEncode(entry.toJson()))
        .toList(growable: false);
    await preferences.setStringList(_storageKey, encodedEntries);
  }
}

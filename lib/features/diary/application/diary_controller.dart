import 'package:flutter/foundation.dart';

import '../domain/entities/diary_entry.dart';
import '../domain/repositories/diary_repository.dart';

class DiaryController extends ChangeNotifier {
  DiaryController(this._repository);

  final DiaryRepository _repository;
  List<DiaryEntry> _entries = const [];

  List<DiaryEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    _entries = await _repository.getAll();
    notifyListeners();
  }

  Future<void> add(DiaryEntry entry) async {
    _entries = [entry, ..._entries];
    await _persist();
  }

  Future<void> update(DiaryEntry entry) async {
    _entries = [
      for (final current in _entries)
        if (current.id == entry.id) entry else current,
    ];
    await _persist();
  }

  Future<void> delete(String id) async {
    _entries = _entries.where((entry) => entry.id != id).toList();
    await _persist();
  }

  Future<void> _persist() async {
    await _repository.replaceAll(_entries);
    _entries = await _repository.getAll();
    notifyListeners();
  }
}

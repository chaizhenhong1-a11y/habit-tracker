import '../entities/diary_entry.dart';

abstract interface class DiaryRepository {
  Future<List<DiaryEntry>> getAll();
  Future<void> replaceAll(List<DiaryEntry> entries);
}

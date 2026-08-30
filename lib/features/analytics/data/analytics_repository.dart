import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../habits/domain/repositories/habit_repository.dart';
import '../domain/analytics_snapshot.dart';

class AnalyticsRepository {
  AnalyticsRepository({required this.habitRepository});

  static const moodMap = <String, String>{
    'happy': '😊',
    'calm': '😌',
    'sad': '😢',
    'angry': '😡',
    'excited': '🤩',
    'tired': '😴',
  };

  final HabitRepository habitRepository;

  Future<AnalyticsSnapshot> load() async {
    final preferences = await SharedPreferences.getInstance();
    final diaryJson = preferences.getStringList('diary_entries') ?? const [];
    final now = DateTime.now();

    final moodCount = <String, int>{for (final key in moodMap.keys) key: 0};
    final diaryItems = <AnalyticsDiaryItem>[];

    for (final encoded in diaryJson) {
      try {
        final map = jsonDecode(encoded) as Map<String, dynamic>;
        final date = DateTime.parse(map['date'] as String);
        final mood = map['mood'] as String? ?? 'happy';
        final title = map['title'] as String? ?? '';
        diaryItems.add(
          AnalyticsDiaryItem(date: date, mood: mood, title: title),
        );
        if (date.year == now.year) {
          moodCount[mood] = (moodCount[mood] ?? 0) + 1;
        }
      } catch (_) {
        // Ignore malformed legacy diary entries while keeping the dashboard usable.
      }
    }

    diaryItems.sort((a, b) => b.date.compareTo(a.date));
    final habits = habitRepository.getAll();

    final dailyCount = <String, int>{};
    for (final habit in habits) {
      for (final date in habit.completedDates) {
        dailyCount[date] = (dailyCount[date] ?? 0) + 1;
      }
    }

    final weekValues = <double>[
      for (var i = 6; i >= 0; i--)
        (dailyCount[DateFormat(
                  'yyyy-MM-dd',
                ).format(now.subtract(Duration(days: i)))] ??
                0)
            .toDouble(),
    ];

    final monthDays = <AnalyticsMonthDay>[];
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    for (var day = 1; day <= daysInMonth; day++) {
      final key = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(now.year, now.month, day));
      monthDays.add(AnalyticsMonthDay(day: day, count: dailyCount[key] ?? 0));
    }

    return AnalyticsSnapshot(
      habits: habits,
      moodCount: moodCount,
      recentDiary: diaryItems.take(5).toList(growable: false),
      weekValues: weekValues,
      monthDays: monthDays,
      diaryTotalCount: diaryJson.length,
    );
  }
}

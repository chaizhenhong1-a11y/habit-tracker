import '../../habits/domain/entities/habit.dart';

class AnalyticsDiaryItem {
  const AnalyticsDiaryItem({
    required this.date,
    required this.mood,
    required this.title,
  });

  final DateTime date;
  final String mood;
  final String title;
}

class AnalyticsMonthDay {
  const AnalyticsMonthDay({required this.day, required this.count});

  final int day;
  final int count;
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.habits,
    required this.moodCount,
    required this.recentDiary,
    required this.weekValues,
    required this.monthDays,
    required this.diaryTotalCount,
  });

  final List<Habit> habits;
  final Map<String, int> moodCount;
  final List<AnalyticsDiaryItem> recentDiary;
  final List<double> weekValues;
  final List<AnalyticsMonthDay> monthDays;
  final int diaryTotalCount;

  int get habitCount => habits.length;

  int get totalCompletedDays =>
      habits.fold<int>(0, (sum, habit) => sum + habit.completedDates.length);
}

import '../entities/habit.dart';
import 'habit_streak_calculator.dart';

class HabitProgressSummary {
  const HabitProgressSummary({
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
    required this.completedScheduledDays,
    required this.completedThisWeek,
    required this.scheduledThisWeek,
    required this.todayProgress,
    required this.todayTarget,
    required this.isScheduledToday,
    required this.isCompletedToday,
  });

  final int currentStreak;
  final int longestStreak;
  final double completionRate;
  final int completedScheduledDays;
  final int completedThisWeek;
  final int scheduledThisWeek;
  final double todayProgress;
  final double todayTarget;
  final bool isScheduledToday;
  final bool isCompletedToday;

  double get todayProgressRatio {
    if (todayTarget <= 0) return 0;
    return (todayProgress / todayTarget).clamp(0.0, 1.0);
  }
}

class HabitProgressSummarizer {
  const HabitProgressSummarizer({
    this.streakCalculator = const HabitStreakCalculator(),
  });

  final HabitStreakCalculator streakCalculator;

  HabitProgressSummary summarize(Habit habit, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final stats = streakCalculator.calculate(habit, now: today);
    final scheduled = habit.isScheduledOn(today);
    final dateKey = _dateKey(today);
    final progress = scheduled ? habit.progressOn(dateKey) : 0.0;
    final target = habit.effectiveTargetValue;

    return HabitProgressSummary(
      currentStreak: stats.currentStreak,
      longestStreak: stats.longestStreak,
      completionRate: stats.completionRate,
      completedScheduledDays: stats.completedScheduledDays,
      completedThisWeek: stats.completedThisWeek,
      scheduledThisWeek: stats.scheduledThisWeek,
      todayProgress: progress,
      todayTarget: target,
      isScheduledToday: scheduled,
      isCompletedToday: scheduled && progress >= target,
    );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dateKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

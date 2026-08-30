import 'package:flutter_test/flutter_test.dart';
import 'package:habittracker/features/habits/domain/entities/habit.dart';
import 'package:habittracker/features/habits/domain/services/habit_progress_summarizer.dart';

void main() {
  const summarizer = HabitProgressSummarizer();

  test('binary habit reports completed today', () {
    final habit = Habit(
      id: 'binary',
      name: 'Read',
      completedDates: const ['2026-08-29'],
    );

    final summary = summarizer.summarize(habit, now: DateTime(2026, 8, 29));

    expect(summary.isScheduledToday, isTrue);
    expect(summary.isCompletedToday, isTrue);
    expect(summary.todayProgress, 1);
    expect(summary.todayProgressRatio, 1);
  });

  test('quantity habit exposes partial daily goal progress', () {
    final habit = Habit(
      id: 'quantity',
      name: 'Water',
      completedDates: const [],
      trackingMode: HabitTrackingMode.quantity,
      targetValue: 8,
      unit: 'cups',
      progressByDate: const {'2026-08-29': 3},
    );

    final summary = summarizer.summarize(habit, now: DateTime(2026, 8, 29));

    expect(summary.todayProgress, 3);
    expect(summary.todayTarget, 8);
    expect(summary.todayProgressRatio, 3 / 8);
    expect(summary.isCompletedToday, isFalse);
  });

  test('unscheduled day has no actionable daily progress', () {
    final habit = Habit(
      id: 'scheduled',
      name: 'Exercise',
      completedDates: const [],
      scheduledWeekdays: const [DateTime.monday],
    );

    final summary = summarizer.summarize(habit, now: DateTime(2026, 8, 29));

    expect(summary.isScheduledToday, isFalse);
    expect(summary.todayProgress, 0);
    expect(summary.isCompletedToday, isFalse);
  });
}

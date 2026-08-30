import 'package:flutter_test/flutter_test.dart';
import 'package:habittracker/features/habits/domain/entities/habit.dart';
import 'package:habittracker/features/habits/domain/services/habit_streak_calculator.dart';

void main() {
  const calculator = HabitStreakCalculator();

  Habit habit({required List<String> completedDates, List<int>? weekdays}) {
    return Habit(
      id: 'habit',
      name: 'Run',
      completedDates: completedDates,
      scheduledWeekdays: weekdays,
    );
  }

  group('HabitStreakCalculator', () {
    test('daily habit calculates current and longest streak', () {
      final stats = calculator.calculate(
        habit(
          completedDates: [
            '2026-08-25',
            '2026-08-26',
            '2026-08-27',
            '2026-08-29',
          ],
        ),
        now: DateTime(2026, 8, 29),
      );

      expect(stats.currentStreak, 1);
      expect(stats.longestStreak, 3);
    });

    test('non-scheduled days do not break a streak', () {
      final stats = calculator.calculate(
        habit(
          weekdays: const [
            DateTime.monday,
            DateTime.wednesday,
            DateTime.friday,
          ],
          completedDates: ['2026-08-24', '2026-08-26', '2026-08-28'],
        ),
        now: DateTime(2026, 8, 29),
      );

      expect(stats.currentStreak, 3);
      expect(stats.longestStreak, 3);
    });

    test('unfinished scheduled today does not break previous streak yet', () {
      final stats = calculator.calculate(
        habit(
          weekdays: const [
            DateTime.monday,
            DateTime.wednesday,
            DateTime.friday,
          ],
          completedDates: ['2026-08-24', '2026-08-26'],
        ),
        now: DateTime(2026, 8, 28),
      );

      expect(stats.currentStreak, 2);
    });

    test('a missed previous scheduled occurrence breaks current streak', () {
      final stats = calculator.calculate(
        habit(
          weekdays: const [
            DateTime.monday,
            DateTime.wednesday,
            DateTime.friday,
          ],
          completedDates: ['2026-08-24', '2026-08-28'],
        ),
        now: DateTime(2026, 8, 29),
      );

      expect(stats.currentStreak, 1);
      expect(stats.longestStreak, 1);
    });

    test('future completion records are ignored', () {
      final stats = calculator.calculate(
        habit(completedDates: ['2026-08-28', '2026-08-30']),
        now: DateTime(2026, 8, 29),
      );

      expect(stats.currentStreak, 1);
      expect(stats.completedScheduledDays, 1);
    });

    test('completion rate only counts elapsed scheduled days', () {
      final stats = calculator.calculate(
        habit(
          weekdays: const [
            DateTime.monday,
            DateTime.wednesday,
            DateTime.friday,
          ],
          completedDates: ['2026-08-24', '2026-08-28'],
        ),
        now: DateTime(2026, 8, 28),
      );

      expect(stats.completedScheduledDays, 2);
      expect(stats.elapsedScheduledDays, 3);
      expect(stats.completionRate, closeTo(2 / 3, 0.0001));
    });
    test('weekly metrics only count elapsed scheduled days', () {
      final stats = calculator.calculate(
        habit(
          weekdays: const [
            DateTime.monday,
            DateTime.wednesday,
            DateTime.friday,
          ],
          completedDates: ['2026-08-24', '2026-08-26'],
        ),
        now: DateTime(2026, 8, 28),
      );

      expect(stats.completedThisWeek, 2);
      expect(stats.scheduledThisWeek, 3);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:habittracker/features/achievements/domain/services/achievement_engine.dart';
import 'package:habittracker/features/habits/domain/entities/habit.dart';

void main() {
  const engine = AchievementEngine();

  Habit habitWithDates(List<String> dates) {
    return Habit(id: 'habit-1', name: 'Read', completedDates: dates);
  }

  test('all achievements are locked without habit progress', () {
    final achievements = engine.evaluate(const [], now: DateTime(2026, 8, 29));

    expect(achievements, hasLength(4));
    expect(achievements.every((item) => !item.isUnlocked), isTrue);
    expect(achievements.first.currentValue, 0);
  });

  test('7-day longest streak unlocks the first achievement only', () {
    final habit = habitWithDates([
      '2026-08-23',
      '2026-08-24',
      '2026-08-25',
      '2026-08-26',
      '2026-08-27',
      '2026-08-28',
      '2026-08-29',
    ]);

    final achievements = engine.evaluate([habit], now: DateTime(2026, 8, 29));

    expect(achievements[0].isUnlocked, isTrue);
    expect(achievements[1].isUnlocked, isFalse);
    expect(achievements[0].currentValue, 7);
  });

  test('uses the best longest streak across all habits', () {
    final shortHabit = habitWithDates([
      '2026-08-27',
      '2026-08-28',
      '2026-08-29',
    ]);
    final longHabit = Habit(
      id: 'habit-2',
      name: 'Exercise',
      completedDates: [
        for (var day = 1; day <= 10; day++)
          '2026-08-${day.toString().padLeft(2, '0')}',
      ],
    );

    final achievements = engine.evaluate([
      shortHabit,
      longHabit,
    ], now: DateTime(2026, 8, 29));

    expect(achievements.first.currentValue, 10);
    expect(achievements.first.isUnlocked, isTrue);
  });
}

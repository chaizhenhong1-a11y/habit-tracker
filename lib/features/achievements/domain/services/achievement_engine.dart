import '../../../habits/domain/entities/habit.dart';
import '../../../habits/domain/services/habit_streak_calculator.dart';
import '../entities/achievement.dart';

class AchievementEngine {
  const AchievementEngine({
    this.streakCalculator = const HabitStreakCalculator(),
  });

  final HabitStreakCalculator streakCalculator;

  static const definitions = <AchievementDefinition>[
    AchievementDefinition(id: 'streak_7', titleKey: 'beginner', target: 7),
    AchievementDefinition(
      id: 'streak_30',
      titleKey: 'perseverance',
      target: 30,
    ),
    AchievementDefinition(
      id: 'streak_100',
      titleKey: 'habitNature',
      target: 100,
    ),
    AchievementDefinition(
      id: 'streak_365',
      titleKey: 'thousandTempering',
      target: 365,
    ),
  ];

  List<AchievementProgress> evaluate(List<Habit> habits, {DateTime? now}) {
    var bestLongestStreak = 0;

    for (final habit in habits) {
      final stats = streakCalculator.calculate(habit, now: now);
      if (stats.longestStreak > bestLongestStreak) {
        bestLongestStreak = stats.longestStreak;
      }
    }

    return [
      for (final definition in definitions)
        AchievementProgress(
          definition: definition,
          currentValue: bestLongestStreak,
        ),
    ];
  }
}

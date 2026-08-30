import 'package:flutter/foundation.dart';
import '../../achievements/domain/entities/achievement.dart';
import '../../achievements/domain/services/achievement_engine.dart';
import '../../habits/domain/entities/habit.dart';
import '../../habits/domain/services/habit_streak_calculator.dart';
import '../data/analytics_repository.dart';
import '../domain/analytics_snapshot.dart';

class AnalyticsController extends ChangeNotifier {
  AnalyticsController(this._repository);

  final AnalyticsRepository _repository;

  AnalyticsSnapshot? _snapshot;
  bool _loading = false;

  AnalyticsSnapshot? get snapshot => _snapshot;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _snapshot = await _repository.load();
    _loading = false;
    notifyListeners();
  }

  static const _streakCalculator = HabitStreakCalculator();
  static const _achievementEngine = AchievementEngine();

  List<AchievementProgress> achievements(List<Habit> habits) {
    return _achievementEngine.evaluate(habits);
  }

  int streak(Habit habit) {
    return _streakCalculator.calculate(habit).currentStreak;
  }

  double weeklyCompletionRate(Habit habit) {
    final stats = _streakCalculator.calculate(habit);
    if (stats.scheduledThisWeek == 0) return 0;
    return stats.completedThisWeek / stats.scheduledThisWeek;
  }

  double totalCompletionRate(Habit habit) {
    return _streakCalculator.calculate(habit).completionRate;
  }
}

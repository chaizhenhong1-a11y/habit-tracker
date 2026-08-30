import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../domain/entities/habit.dart';
import '../domain/repositories/habit_repository.dart';
import '../domain/services/habit_progress_summarizer.dart';
import '../domain/services/habit_streak_calculator.dart';

class HabitController extends ChangeNotifier {
  HabitController(this._repository);

  final HabitRepository _repository;
  static const _streakCalculator = HabitStreakCalculator();
  static const _progressSummarizer = HabitProgressSummarizer();

  List<Habit> _habits = const [];

  List<Habit> get habits => List<Habit>.unmodifiable(_habits);

  List<Habit> get goodHabits =>
      _habits.where((habit) => habit.isGood).toList(growable: false);

  List<Habit> get badHabits =>
      _habits.where((habit) => habit.isBad).toList(growable: false);

  void load() {
    _habits = _repository.getAll();
    notifyListeners();
  }

  bool isScheduledToday(Habit habit, {DateTime? now}) {
    return habit.isScheduledOn(now ?? DateTime.now());
  }

  bool isCompletedToday(Habit habit, {DateTime? now}) {
    return habit.isCompletedOn(_dateKey(now ?? DateTime.now()));
  }

  double progressToday(Habit habit, {DateTime? now}) {
    return habit.progressOn(_dateKey(now ?? DateTime.now()));
  }

  HabitStreakStats streakStats(Habit habit, {DateTime? now}) {
    return _streakCalculator.calculate(habit, now: now);
  }

  HabitProgressSummary progressSummary(Habit habit, {DateTime? now}) {
    return _progressSummarizer.summarize(habit, now: now);
  }

  void toggleToday(Habit habit, {DateTime? now}) {
    final date = now ?? DateTime.now();
    if (!habit.isScheduledOn(date)) return;

    final dateKey = _dateKey(date);
    habit.setCompletedOn(dateKey, completed: !habit.isCompletedOn(dateKey));
    _repository.save(habit);
    load();
  }

  void incrementToday(Habit habit, {double? amount, DateTime? now}) {
    final date = now ?? DateTime.now();
    if (!habit.isScheduledOn(date)) return;

    final dateKey = _dateKey(date);
    final step = amount ?? _defaultStep(habit);
    habit.setProgressOn(dateKey, habit.progressOn(dateKey) + step);
    _repository.save(habit);
    load();
  }

  void decrementToday(Habit habit, {double? amount, DateTime? now}) {
    final date = now ?? DateTime.now();
    if (!habit.isScheduledOn(date)) return;

    final dateKey = _dateKey(date);
    final step = amount ?? _defaultStep(habit);
    habit.setProgressOn(dateKey, habit.progressOn(dateKey) - step);
    _repository.save(habit);
    load();
  }

  void add(Habit habit) {
    _repository.save(habit);
    load();
  }

  void update(Habit habit) {
    _repository.save(habit);
    load();
  }

  void deleteById(String id) {
    _repository.deleteById(id);
    load();
  }

  void replaceAll(List<Habit> habits) {
    _repository.replaceAll(habits);
    load();
  }

  double _defaultStep(Habit habit) {
    final target = habit.effectiveTargetValue;
    if (target <= 10) return 1;
    if (target <= 60) return 5;
    if (target <= 500) return 10;
    return 100;
  }

  String _dateKey(DateTime value) => DateFormat('yyyy-MM-dd').format(value);
}

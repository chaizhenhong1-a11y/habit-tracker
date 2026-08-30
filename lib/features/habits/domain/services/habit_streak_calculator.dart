import 'package:intl/intl.dart';

import '../entities/habit.dart';

class HabitStreakStats {
  const HabitStreakStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.completedScheduledDays,
    required this.elapsedScheduledDays,
    required this.completedThisWeek,
    required this.scheduledThisWeek,
  });

  final int currentStreak;
  final int longestStreak;
  final int completedScheduledDays;
  final int elapsedScheduledDays;
  final int completedThisWeek;
  final int scheduledThisWeek;

  double get completionRate {
    if (elapsedScheduledDays == 0) return 0;
    return completedScheduledDays / elapsedScheduledDays;
  }
}

class HabitStreakCalculator {
  const HabitStreakCalculator();

  HabitStreakStats calculate(Habit habit, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final completedDates = habit.completedDates
        .map(_tryParseDate)
        .whereType<DateTime>()
        .map(_dateOnly)
        .where((date) => !date.isAfter(today))
        .toSet();

    if (completedDates.isEmpty) {
      return HabitStreakStats(
        currentStreak: 0,
        longestStreak: 0,
        completedScheduledDays: 0,
        elapsedScheduledDays: 0,
        completedThisWeek: _completedThisWeek(
          habit,
          completedDates: completedDates,
          today: today,
        ),
        scheduledThisWeek: _scheduledThisWeek(habit, today),
      );
    }

    final firstCompletion = completedDates.reduce(
      (a, b) => a.isBefore(b) ? a : b,
    );
    final firstScheduledDate = _firstScheduledDateOnOrAfter(
      habit,
      firstCompletion,
      today,
    );

    if (firstScheduledDate == null) {
      return HabitStreakStats(
        currentStreak: 0,
        longestStreak: 0,
        completedScheduledDays: 0,
        elapsedScheduledDays: 0,
        completedThisWeek: _completedThisWeek(
          habit,
          completedDates: completedDates,
          today: today,
        ),
        scheduledThisWeek: _scheduledThisWeek(habit, today),
      );
    }

    var longest = 0;
    var running = 0;
    var completedScheduledDays = 0;
    var elapsedScheduledDays = 0;

    for (
      var date = firstScheduledDate;
      !date.isAfter(today);
      date = date.add(const Duration(days: 1))
    ) {
      if (!habit.isScheduledOn(date)) continue;

      elapsedScheduledDays++;
      if (completedDates.contains(date)) {
        completedScheduledDays++;
        running++;
        if (running > longest) longest = running;
      } else {
        running = 0;
      }
    }

    final current = _currentStreak(
      habit,
      completedDates: completedDates,
      today: today,
    );

    return HabitStreakStats(
      currentStreak: current,
      longestStreak: longest,
      completedScheduledDays: completedScheduledDays,
      elapsedScheduledDays: elapsedScheduledDays,
      completedThisWeek: _completedThisWeek(
        habit,
        completedDates: completedDates,
        today: today,
      ),
      scheduledThisWeek: _scheduledThisWeek(habit, today),
    );
  }

  int _scheduledThisWeek(Habit habit, DateTime today) {
    final monday = today.subtract(Duration(days: today.weekday - 1));
    var count = 0;
    for (var i = 0; i < 7; i++) {
      final date = _dateOnly(monday.add(Duration(days: i)));
      if (date.isAfter(today)) break;
      if (habit.isScheduledOn(date)) count++;
    }
    return count;
  }

  int _completedThisWeek(
    Habit habit, {
    required Set<DateTime> completedDates,
    required DateTime today,
  }) {
    final monday = today.subtract(Duration(days: today.weekday - 1));
    var count = 0;
    for (var i = 0; i < 7; i++) {
      final date = _dateOnly(monday.add(Duration(days: i)));
      if (date.isAfter(today)) break;
      if (habit.isScheduledOn(date) && completedDates.contains(date)) {
        count++;
      }
    }
    return count;
  }

  int _currentStreak(
    Habit habit, {
    required Set<DateTime> completedDates,
    required DateTime today,
  }) {
    DateTime? cursor = today;

    // A scheduled today that is not completed yet must not break the streak
    // before the day has ended. Start from the previous scheduled occurrence.
    if (habit.isScheduledOn(cursor) && !completedDates.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    cursor = _previousScheduledDateOnOrBefore(habit, cursor);
    var streak = 0;

    while (cursor != null) {
      if (!completedDates.contains(cursor)) break;
      streak++;
      cursor = _previousScheduledDateOnOrBefore(
        habit,
        cursor.subtract(const Duration(days: 1)),
      );
    }

    return streak;
  }

  DateTime? _firstScheduledDateOnOrAfter(
    Habit habit,
    DateTime start,
    DateTime end,
  ) {
    for (
      var date = _dateOnly(start);
      !date.isAfter(end);
      date = date.add(const Duration(days: 1))
    ) {
      if (habit.isScheduledOn(date)) return date;
    }
    return null;
  }

  DateTime? _previousScheduledDateOnOrBefore(Habit habit, DateTime start) {
    var date = _dateOnly(start);
    for (var i = 0; i < 8; i++) {
      if (habit.isScheduledOn(date)) return date;
      date = date.subtract(const Duration(days: 1));
    }
    return null;
  }

  DateTime? _tryParseDate(String value) {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(value);
    } on FormatException {
      return null;
    }
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/habit.dart';

class HabitLocalDataSource {
  HabitLocalDataSource(this._box);

  factory HabitLocalDataSource.fromHabitsBox() {
    return HabitLocalDataSource(Hive.box<dynamic>('habits'));
  }

  final Box<dynamic> _box;

  List<Habit> readAll() {
    final habits = <Habit>[];

    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data == null) continue;

      habits.add(Habit.fromMap(Map<String, dynamic>.from(data as Map)));
    }

    habits.sort((a, b) => b.id.compareTo(a.id));
    return habits;
  }

  void put(Habit habit) {
    _box.put(habit.id, habit.toMap());
  }

  void delete(String id) {
    _box.delete(id);
  }

  void replaceAll(List<Habit> habits) {
    _box.clear();

    for (final habit in habits) {
      _box.put(habit.id, habit.toMap());
    }
  }
}

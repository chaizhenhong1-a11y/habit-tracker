import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';

class HabitService {
  final Box _box = Hive.box('habits');

  List<Habit> getAllHabits() {
    final habits = <Habit>[];
    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data != null) {
        habits.add(Habit.fromMap(Map<String, dynamic>.from(data)));
      }
    }
    habits.sort((a, b) => b.id.compareTo(a.id));
    return habits;
  }

  void addHabit(Habit habit) {
    _box.put(habit.id, habit.toMap());
  }

  void updateHabit(Habit habit) {
    _box.put(habit.id, habit.toMap());
  }

  void deleteHabit(String id) {
    _box.delete(id);
  }

  // 新增：保存整个习惯列表（用于拖拽排序后更新顺序）
  void updateOrder(List<Habit> habits) {
    // 清空盒子
    _box.clear();
    // 重新按顺序添加
    for (final habit in habits) {
      _box.put(habit.id, habit.toMap());
    }
  }
}
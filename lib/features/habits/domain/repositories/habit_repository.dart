import '../entities/habit.dart';

abstract interface class HabitRepository {
  List<Habit> getAll();

  void save(Habit habit);

  void deleteById(String id);

  void replaceAll(List<Habit> habits);
}

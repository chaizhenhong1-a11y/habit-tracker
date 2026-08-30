import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../datasources/habit_local_data_source.dart';

class HiveHabitRepository implements HabitRepository {
  HiveHabitRepository(this._localDataSource);

  factory HiveHabitRepository.fromHabitsBox() {
    return HiveHabitRepository(HabitLocalDataSource.fromHabitsBox());
  }

  final HabitLocalDataSource _localDataSource;

  @override
  List<Habit> getAll() => _localDataSource.readAll();

  @override
  void save(Habit habit) => _localDataSource.put(habit);

  @override
  void deleteById(String id) => _localDataSource.delete(id);

  @override
  void replaceAll(List<Habit> habits) => _localDataSource.replaceAll(habits);
}

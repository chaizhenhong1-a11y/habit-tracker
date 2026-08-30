import '../features/habits/data/repositories/hive_habit_repository.dart';
import '../features/habits/domain/entities/habit.dart';
import '../features/habits/domain/repositories/habit_repository.dart';

@Deprecated(
  'Use HabitRepository/HiveHabitRepository from features/habits instead.',
)
class HabitService {
  HabitService({HabitRepository? repository})
    : _repository = repository ?? HiveHabitRepository.fromHabitsBox();

  final HabitRepository _repository;

  List<Habit> getAllHabits() => _repository.getAll();

  void addHabit(Habit habit) => _repository.save(habit);

  void updateHabit(Habit habit) => _repository.save(habit);

  void deleteHabit(String id) => _repository.deleteById(id);

  void updateOrder(List<Habit> habits) => _repository.replaceAll(habits);
}

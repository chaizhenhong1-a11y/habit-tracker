import 'package:flutter_test/flutter_test.dart';
import 'package:habittracker/features/habits/domain/entities/habit.dart';

void main() {
  group('Habit', () {
    test('legacy map keeps binary daily behaviour', () {
      final habit = Habit.fromMap({
        'id': '1',
        'name': 'Read',
        'completedDates': ['2026-08-29'],
        'type': 'good',
      });

      expect(habit.trackingMode, HabitTrackingMode.binary);
      expect(habit.scheduledWeekdays, [1, 2, 3, 4, 5, 6, 7]);
      expect(habit.isCompletedOn('2026-08-29'), isTrue);
    });

    test('quantity progress synchronizes completion state', () {
      final habit = Habit(
        id: '2',
        name: 'Read 30 min',
        completedDates: const [],
        trackingMode: HabitTrackingMode.quantity,
        targetValue: 30,
        unit: 'min',
      );

      habit.setProgressOn('2026-08-29', 20);
      expect(habit.isCompletedOn('2026-08-29'), isFalse);

      habit.setProgressOn('2026-08-29', 30);
      expect(habit.isCompletedOn('2026-08-29'), isTrue);

      habit.setProgressOn('2026-08-29', 10);
      expect(habit.isCompletedOn('2026-08-29'), isFalse);
    });

    test('scheduled weekdays are persisted and normalized', () {
      final habit = Habit(
        id: '3',
        name: 'Run',
        completedDates: const [],
        scheduledWeekdays: const [5, 1, 3],
      );

      expect(habit.scheduledWeekdays, [1, 3, 5]);
      expect(Habit.fromMap(habit.toMap()).scheduledWeekdays, [1, 3, 5]);
    });
  });
}

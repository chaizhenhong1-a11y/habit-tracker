import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../features/habits/domain/entities/habit.dart';

/// Completion rewards are permanent and each habit/date can earn only once.
class PointsLedger {
  PointsLedger(this.box);

  factory PointsLedger.opened() => PointsLedger(Hive.box<dynamic>('points'));

  final Box<dynamic> box;

  Map<String, dynamic> get snapshot => Map<String, dynamic>.from(
    box.get('ledger', defaultValue: <String, dynamic>{}) as Map,
  );

  int get totalEarned {
    final data = snapshot;
    return (data['awarded'] as List? ?? const []).length +
        (data['migrationCredit'] as int? ?? 0);
  }

  Future<void> initialize(
    List<Habit> habits, {
    required int spentPoints,
  }) async {
    if (box.containsKey('ledger')) return;
    final awarded = _events(habits).toSet();
    // Preserve old redemptions even if their earning habits were already deleted.
    await box.put('ledger', {
      'awarded': awarded.toList(),
      'migrationCredit': (spentPoints - awarded.length).clamp(0, spentPoints),
    });
  }

  Future<void> record(Iterable<Habit> habits) async {
    final data = snapshot;
    final awarded = Set<String>.from(data['awarded'] as List? ?? const []);
    final before = awarded.length;
    awarded.addAll(_events(habits));
    if (awarded.length == before) return;
    await box.put('ledger', {
      'awarded': awarded.toList(),
      'migrationCredit': data['migrationCredit'] ?? 0,
    });
  }

  Iterable<String> _events(Iterable<Habit> habits) sync* {
    for (final habit in habits) {
      for (final date in habit.completedDates) {
        yield jsonEncode([habit.id, date]);
      }
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habittracker/core/storage/backup_store.dart';
import 'package:habittracker/core/storage/cloud_sync.dart';
import 'package:habittracker/core/storage/points_ledger.dart';
import 'package:habittracker/features/habits/application/habit_controller.dart';
import 'package:habittracker/features/habits/data/repositories/hive_habit_repository.dart';
import 'package:habittracker/features/habits/domain/entities/habit.dart';
import 'package:habittracker/features/wishes/application/wish_controller.dart';
import 'package:habittracker/features/wishes/data/repositories/shared_preferences_wish_repository.dart';
import 'package:habittracker/features/wishes/domain/entities/reward.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late SharedPreferences prefs;
  late BackupStore store;
  late HiveHabitRepository repository;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    directory = await Directory.systemTemp.createTemp('habittracker-test-');
    Hive.init(directory.path);
    await Hive.openBox<dynamic>('habits');
    await Hive.openBox<dynamic>('points');
    repository = HiveHabitRepository.fromHabitsBox();
    await PointsLedger.opened().initialize([], spentPoints: 0);
    store = BackupStore(prefs);
  });
  tearDown(() async {
    await CloudSync.instance.stop();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Habit habit() => Habit(id: 'h1', name: 'Read', completedDates: []);

  test(
    'Offline check-ins and points survive restart without Firebase',
    () async {
      await CloudSync.instance.enterGuest();
      final controller = HabitController(repository)..load();
      final item = habit();
      controller.add(item);
      controller.toggleToday(item, now: DateTime(2026, 10, 20));
      await Hive.box<dynamic>('habits').flush();
      await Hive.box<dynamic>('points').flush();
      await Hive.close();
      await Hive.openBox<dynamic>('habits');
      await Hive.openBox<dynamic>('points');
      expect(
        HiveHabitRepository.fromHabitsBox().getAll().single.completedDates,
        ['2026-10-20'],
      );
      expect(PointsLedger.opened().totalEarned, 1);
      expect(prefs.getString('local_data_owner'), 'guest');
      expect(CloudSync.instance.uid, isNull);
      controller.dispose();
    },
  );

  test(
    'Undoing, repeating and deleting completion never re-awards or removes points',
    () async {
      final controller = HabitController(repository)..load();
      final item = habit();
      controller.add(item);
      for (var i = 0; i < 5; i++) {
        controller.toggleToday(item, now: DateTime(2026, 10, 20));
      }
      expect(PointsLedger.opened().totalEarned, 1);
      final wishes = WishController(
        repository: SharedPreferencesWishRepository(),
        habitRepository: repository,
      );
      await wishes.load();
      expect(
        await wishes.redeem(const Reward(name: 'Tea', emoji: '☕', cost: 1)),
        isTrue,
      );
      controller.deleteById(item.id);
      expect(wishes.totalPoints, 1);
      expect(wishes.availablePoints, 0);
      expect(
        await wishes.redeem(const Reward(name: 'Tea', emoji: '☕', cost: 1)),
        isFalse,
      );
      controller.dispose();
      wishes.dispose();
    },
  );

  test('Quantity goals earn once when the target is first reached', () async {
    final item = habit().copyWith(
      trackingMode: HabitTrackingMode.quantity,
      targetValue: 2,
    );
    final controller = HabitController(repository)..add(item);
    controller.incrementToday(item, amount: 1, now: DateTime(2026, 10, 20));
    expect(PointsLedger.opened().totalEarned, 0);
    controller.incrementToday(item, amount: 1, now: DateTime(2026, 10, 20));
    expect(PointsLedger.opened().totalEarned, 1);
    controller.decrementToday(item, amount: 1, now: DateTime(2026, 10, 20));
    controller.incrementToday(item, amount: 1, now: DateTime(2026, 10, 20));
    expect(PointsLedger.opened().totalEarned, 1);
    controller.dispose();
  });

  test(
    'Old redemptions migrate without a negative balance or duplicate migration',
    () async {
      await Hive.box<dynamic>('points').clear();
      final ledger = PointsLedger.opened();
      await ledger.initialize([], spentPoints: 7);
      expect(ledger.totalEarned, 7);
      await ledger.initialize([], spentPoints: 100);
      expect(ledger.totalEarned, 7);
    },
  );

  Map<String, dynamic> sample() {
    final data = store.empty();
    data['habits'] = [habit().toMap()];
    data['diary_entries'] = [
      {
        'id': 'd1',
        'title': 'Day',
        'content': 'Good',
        'date': '2026-10-20T10:00:00',
        'mood': 'happy',
        'imagePath': null,
      },
    ];
    data['plans'] = [
      {
        'id': 'p1',
        'title': 'Walk',
        'notes': '',
        'createdAt': '2026-10-20T10:00:00',
        'dueDate': null,
        'isCompleted': false,
      },
    ];
    data['custom_rewards'] = [
      {'name': 'Tea', 'emoji': '☕', 'cost': 1},
    ];
    data['ledger'] = {
      'awarded': [
        jsonEncode(['h1', '2026-10-20']),
      ],
      'migrationCredit': 0,
    };
    data['spentPoints'] = 1;
    data['redeem_history'] = [
      {
        'rewardName': 'Tea',
        'emoji': '☕',
        'cost': 1,
        'time': '2026-10-20T10:00:00',
      },
    ];
    return data;
  }

  test(
    'Complete backup round-trip includes all records, rewards and points, excludes credentials',
    () async {
      await prefs.setString('registered_password', 'legacy-secret');
      await store.restore(sample());
      final exported = await store.exportPortable();
      expect(exported.contains('legacy-secret'), isFalse);
      final prepared = await store.preparePortable(exported);
      await store.restore(store.empty());
      await store.restore(prepared);
      expect(store.capture(), store.validate(sample()));
    },
  );

  test('Malformed backups do not modify any saved data', () async {
    await store.restore(sample());
    final previous = jsonEncode(store.capture());
    for (final corrupt in [
      {...sample(), 'version': 99},
      {
        ...sample(),
        'plans': [
          {'title': 'Missing ID'},
        ],
      },
      {...sample(), 'spentPoints': -1},
      {...sample(), 'spentPoints': 200},
      {
        ...sample(),
        'habits': [habit().toMap(), habit().toMap()],
      },
    ]) {
      await expectLater(store.restore(corrupt), throwsFormatException);
      expect(jsonEncode(store.capture()), previous);
    }
  });

  test('An interrupted restore rolls back on next launch', () async {
    await store.restore(sample());
    final original = store.capture();
    await prefs.setString('restore_journal_v1', jsonEncode(original));
    await Hive.box<dynamic>('habits').clear();
    await prefs.remove('plans');
    await store.recoverInterruptedRestore();
    expect(store.capture(), original);
    expect(prefs.containsKey('restore_journal_v1'), isFalse);
  });

  test('Guest merge is idempotent and does not grant spent points twice', () {
    final result = store.mergeGuest(store.empty(), sample());
    final twice = store.mergeGuest(result, sample());
    expect(twice, result);
    expect(twice['spentPoints'], 1);
    expect((twice['ledger'] as Map)['awarded'], hasLength(1));
  });

  test(
    'Unmerged guest records stay local without exposing pending account data',
    () async {
      final guest = sample();
      await prefs.setString('guest_cache_v1', jsonEncode(guest));
      await prefs.setString(
        'account_cache_account-123',
        'pending-account-records',
      );
      await store.restore(store.empty());
      await prefs.setString('local_data_owner', 'account-123');
      await CloudSync.instance.enterGuest();
      expect(store.capture(), store.validate(guest));
      expect(
        prefs.getString('account_cache_account-123'),
        'pending-account-records',
      );
      expect(prefs.getString('local_data_owner'), 'guest');
    },
  );
}

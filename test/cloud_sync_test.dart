import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habittracker/core/storage/cloud_sync.dart';
import 'package:habittracker/core/storage/points_ledger.dart';
import 'package:habittracker/core/storage/cloud_media.dart';
import 'package:habittracker/core/storage/backup_store.dart';
import 'package:habittracker/features/habits/application/habit_controller.dart';
import 'package:habittracker/features/habits/data/repositories/hive_habit_repository.dart';
import 'package:habittracker/features/habits/domain/entities/habit.dart';

class NetworkFirestore extends FakeFirebaseFirestore {
  bool online = true;
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    if (!online) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    return super.runTransaction(
      handler,
      timeout: timeout,
      maxAttempts: maxAttempts,
    );
  }
}

class TestUser extends Fake implements User {
  TestUser(this.id);
  final String id;
  @override
  String get uid => id;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late NetworkFirestore database;
  final sessions = <CloudSync>[];
  CloudSync session() {
    final result = CloudSync(firestore: database);
    sessions.add(result);
    return result;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp(
      'habittracker-cloud-test-',
    );
    Hive.init(directory.path);
    await Hive.openBox<dynamic>('habits');
    await Hive.openBox<dynamic>('points');
    await PointsLedger.opened().initialize([], spentPoints: 0);
    database = NetworkFirestore();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
  });
  tearDown(() async {
    for (final sync in sessions) {
      await sync.stop();
      sync.dispose();
    }
    sessions.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'Guest auto-import, offline restart, reconnect upload, then clean sign-out',
    () async {
      final sync = session();
      await sync.enterGuest();
      final controller = HabitController(HiveHabitRepository.fromHabitsBox());
      final habit = Habit(id: 'read', name: 'Read', completedDates: []);
      controller.add(habit);
      controller.toggleToday(habit, now: DateTime(2026, 10, 20));
      await sync.start(TestUser('account-a'), importGuest: true);
      await sync.flush();
      expect(sync.status, SyncStatus.synced);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('guest_cache_v1'), isFalse);

      database.online = false;
      controller.toggleToday(habit, now: DateTime(2026, 10, 21));
      sync.changed();
      await sync.flush();
      expect(sync.status, SyncStatus.offline);
      expect(PointsLedger.opened().totalEarned, 2);
      await sync.stop();
      await Hive.box<dynamic>('habits').flush();
      await Hive.box<dynamic>('points').flush();
      await Hive.close();
      await Hive.openBox<dynamic>('habits');
      await Hive.openBox<dynamic>('points');

      final reopened = session();
      await reopened.start(TestUser('account-a'));
      await reopened.flush();
      expect(
        HiveHabitRepository.fromHabitsBox().getAll().single.completedDates,
        hasLength(2),
      );
      database.online = true;
      await reopened.flush();
      expect(reopened.status, SyncStatus.synced);
      final cloud = (await database.doc('users/account-a/state/main').get())
          .data()!;
      final payload = jsonDecode(cloud['payload'] as String) as Map;
      expect(
        (payload['habits'] as List).single['completedDates'],
        hasLength(2),
      );
      expect((payload['ledger'] as Map)['awarded'], hasLength(2));
      await reopened.stop(signingOut: true);
      await reopened.enterGuest();
      expect(HiveHabitRepository.fromHabitsBox().getAll(), isEmpty);
      expect(PointsLedger.opened().totalEarned, 0);
      expect(prefs.containsKey('account_cache_account-a'), isFalse);
      controller.dispose();
    },
  );

  test(
    'Photos round-trip through private chunks and portable backups',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final store = BackupStore(prefs);
      final photo = File('${directory.path}/photo.png');
      await photo.writeAsBytes(List<int>.generate(700000, (i) => i % 256));
      final data = store.empty();
      (data['profile'] as Map)['avatar_local_path'] = photo.path;
      final cloud = CloudMedia('account-a', firestore: database);
      final uploaded = await cloud.upload(data);
      expect(
        (uploaded['profile'] as Map)['avatar_local_path'],
        startsWith('cloud-media:'),
      );
      final downloaded = await cloud.download(uploaded);
      final restored = File(
        (downloaded['profile'] as Map)['avatar_local_path'] as String,
      );
      expect(await restored.readAsBytes(), await photo.readAsBytes());
      await store.restore(data);
      final exported = await store.exportPortable();
      final original = await photo.readAsBytes();
      await photo.delete();
      final prepared = await store.preparePortable(exported);
      expect(
        await File(
          (prepared['profile'] as Map)['avatar_local_path'] as String,
        ).readAsBytes(),
        original,
      );
    },
  );

  test('New guest data goes only to the next signed-in account', () async {
    final sync = session();
    await sync.enterGuest();
    final repository = HiveHabitRepository.fromHabitsBox();
    repository.save(Habit(id: 'a', name: 'A record', completedDates: []));
    await sync.start(TestUser('account-a'), importGuest: true);
    await sync.flush();
    await sync.stop(signingOut: true);
    await sync.enterGuest();
    repository.save(
      Habit(id: 'b', name: 'New guest record', completedDates: []),
    );
    await sync.start(TestUser('account-b'), importGuest: true);
    await sync.flush();
    final a =
        jsonDecode(
              (await database.doc('users/account-a/state/main').get())
                      .data()!['payload']
                  as String,
            )
            as Map;
    final b =
        jsonDecode(
              (await database.doc('users/account-b/state/main').get())
                      .data()!['payload']
                  as String,
            )
            as Map;
    expect((a['habits'] as List).single['id'], 'a');
    expect((b['habits'] as List).single['id'], 'b');
  });

  test('Only cross-account logins with guest data need confirmation', () async {
    final sync = session();
    await sync.enterGuest();
    HiveHabitRepository.fromHabitsBox().save(
      Habit(id: 'guest', name: 'Guest record', completedDates: []),
    );
    expect(await sync.needsGuestConfirmation('account-a'), isFalse);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_signed_in_uid', 'account-a');
    expect(await sync.needsGuestConfirmation('account-a'), isFalse);
    expect(await sync.needsGuestConfirmation('account-b'), isTrue);
    await sync.start(TestUser('account-b'), importGuest: false);
    await sync.flush();
    expect(HiveHabitRepository.fromHabitsBox().getAll(), isEmpty);
    await sync.stop(signingOut: true);
    await sync.enterGuest();
    expect(HiveHabitRepository.fromHabitsBox().getAll().single.id, 'guest');
  });

  test(
    'Offline sign-out keeps pending records only in their original account',
    () async {
      final sync = session();
      await sync.enterGuest();
      await sync.start(TestUser('account-a'));
      await sync.flush();
      database.online = false;
      HiveHabitRepository.fromHabitsBox().save(
        Habit(id: 'pending', name: 'Offline record', completedDates: []),
      );
      sync.changed();
      await sync.stop(signingOut: true);
      await sync.enterGuest();
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('account_cache_account-a'),
        contains('Offline record'),
      );
      expect(HiveHabitRepository.fromHabitsBox().getAll(), isEmpty);
      database.online = true;
      await sync.start(TestUser('account-a'));
      await sync.flush();
      expect(HiveHabitRepository.fromHabitsBox().getAll().single.id, 'pending');
    },
  );
}

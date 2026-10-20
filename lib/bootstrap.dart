import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app/app.dart';
import 'app/app_controller.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/app_preferences.dart';
import 'core/storage/points_ledger.dart';
import 'features/habits/data/repositories/hive_habit_repository.dart';
import 'core/storage/backup_store.dart';
import 'core/storage/cloud_sync.dart';
import 'firebase_options.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await Hive.initFlutter();
  await Hive.openBox<dynamic>('habits');
  await Hive.openBox<dynamic>('points');
  await NotificationService.instance.initialize();
  await initializeDateFormatting('zh_CN', null);

  final sharedPreferences = await SharedPreferences.getInstance();
  await sharedPreferences.remove('registered_password');
  await sharedPreferences.remove('registered_username');
  await PointsLedger.opened().initialize(
    HiveHabitRepository.fromHabitsBox().getAll(),
    spentPoints: sharedPreferences.getInt('spent_points') ?? 0,
  );
  final appPreferences = AppPreferences(sharedPreferences);
  await BackupStore(sharedPreferences).recoverInterruptedRestore();
  await appPreferences.setLoggedIn(false);
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      await CloudSync.instance.start(user);
      await appPreferences.setLoggedIn(true);
    } catch (_) {
      await CloudSync.instance.enterGuest();
    }
  } else {
    await CloudSync.instance.enterGuest();
  }
  final appController = AppController(appPreferences);
  await appController.load();

  runApp(HabitTrackerApp(controller: appController));
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/app_controller.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/app_preferences.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  await NotificationService.instance.initialize();
  await initializeDateFormatting('zh_CN', null);

  final sharedPreferences = await SharedPreferences.getInstance();
  final appPreferences = AppPreferences(sharedPreferences);
  final appController = AppController(appPreferences);
  await appController.load();

  runApp(HabitTrackerApp(controller: appController));
}

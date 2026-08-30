import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../l10n/app_localizations.dart';
import 'app_controller.dart';
import 'navigation/main_navigation.dart';
import 'theme/app_theme.dart';

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: '习惯打卡',
          debugShowCheckedModeBanner: false,
          locale: controller.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(controller.seedColor),
          darkTheme: AppTheme.dark(controller.seedColor),
          themeMode: controller.themeMode,
          home: controller.isLoggedIn
              ? MainNavigation(
                  themeMode: controller.themeMode,
                  seedColor: controller.seedColor,
                  locale: controller.locale,
                  onThemeModeChanged: controller.changeThemeMode,
                  onSeedColorChanged: controller.changeSeedColor,
                  onLocaleChanged: controller.changeLocale,
                  onLogout: () {
                    controller.setLoggedIn(false);
                  },
                )
              : LoginPage(
                  onLoginSuccess: () {
                    controller.setLoggedIn(true);
                  },
                ),
        );
      },
    );
  }
}

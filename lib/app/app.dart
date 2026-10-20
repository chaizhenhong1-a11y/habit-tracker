import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/storage/cloud_sync.dart';

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
      listenable: Listenable.merge([controller, CloudSync.instance]),
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) =>
              AppLocalizations.of(context).text('appTitle'),
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
          home: MainNavigation(
            key: ValueKey(
              '${CloudSync.instance.uid}:${CloudSync.instance.viewRevision}',
            ),
            themeMode: controller.themeMode,
            seedColor: controller.seedColor,
            locale: controller.locale,
            isGuest: CloudSync.instance.uid == null,
            onSignIn: () => controller.setLoggedIn(true),
            onThemeModeChanged: controller.changeThemeMode,
            onSeedColorChanged: controller.changeSeedColor,
            onLocaleChanged: controller.changeLocale,
            onLogout: () async {
              await CloudSync.instance.stop(signingOut: true);
              await FirebaseAuth.instance.signOut();
              await CloudSync.instance.enterGuest();
              await controller.setLoggedIn(false);
            },
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_localizations/flutter_localizations.dart'; // 新增
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'l10n/app_localizations.dart';
import 'screens/habit_list_screen.dart';
import 'screens/wish_screen.dart';
import 'screens/data_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await Hive.initFlutter();
  await Hive.openBox('habits');
  await NotificationService().init();
  await initializeDateFormatting('zh_CN', null);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  Color _seedColor = const Color(0xFF8E97FD);
  bool _isLoggedIn = false;
  Locale _locale = const Locale('zh');

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode') ?? 'light';
    final colorValue = prefs.getInt('seed_color') ?? 0xFF8E97FD;
    final loggedIn = prefs.getBool('is_logged_in') ?? false;
    final languageCode = prefs.getString('language') ?? 'zh';
    setState(() {
      _themeMode = _stringToThemeMode(mode);
      _seedColor = Color(colorValue);
      _isLoggedIn = loggedIn;
      _locale = Locale(languageCode);
    });
  }

  Future<void> _changeThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeModeToString(mode));
    setState(() => _themeMode = mode);
  }

  Future<void> _changeSeedColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seed_color', color.value);
    setState(() => _seedColor = color);
  }

  void _changeLocale(Locale locale) async {
    setState(() => _locale = locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
  }

  void _handleLoginSuccess() => setState(() => _isLoggedIn = true);
  void _handleLogout() => setState(() => _isLoggedIn = false);

  ThemeMode _stringToThemeMode(String mode) {
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.light;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      default: return 'light';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '习惯打卡',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
          surface: const Color(0xFFF8F9FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        typography: Typography.material2021(),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: Colors.white,
        ),
        dialogTheme: DialogThemeData(
          elevation: 10,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
          surface: const Color(0xFF12121A),
        ),
        scaffoldBackgroundColor: const Color(0xFF12121A),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: const Color(0xFF1E1E2A),
        ),
        dialogTheme: DialogThemeData(
          elevation: 20,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: const Color(0xFF1E1E2A),
        ),
      ),
      themeMode: _themeMode,
      home: _isLoggedIn
          ? MainNavigation(
              themeMode: _themeMode,
              seedColor: _seedColor,
              locale: _locale,
              onThemeModeChanged: _changeThemeMode,
              onSeedColorChanged: _changeSeedColor,
              onLocaleChanged: _changeLocale,
              onLogout: _handleLogout,
            )
          : LoginScreen(onLoginSuccess: _handleLoginSuccess),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final ThemeMode themeMode;
  final Color seedColor;
  final Locale locale;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Color> onSeedColorChanged;
  final ValueChanged<Locale> onLocaleChanged;
  final VoidCallback onLogout;

  const MainNavigation({
    super.key,
    required this.themeMode,
    required this.seedColor,
    required this.locale,
    required this.onThemeModeChanged,
    required this.onSeedColorChanged,
    required this.onLocaleChanged,
    required this.onLogout,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  final _wishKey = GlobalKey<WishScreenState>();
  final _dataKey = GlobalKey<DataScreenState>();

  @override
  void initState() {
    super.initState();
    _pages = [
      const HabitListScreen(),
      WishScreen(key: _wishKey),
      DataScreen(key: _dataKey),
      ProfileScreen(
        themeMode: widget.themeMode,
        seedColor: widget.seedColor,
        locale: widget.locale,
        onThemeModeChanged: widget.onThemeModeChanged,
        onSeedColorChanged: widget.onSeedColorChanged,
        onLocaleChanged: widget.onLocaleChanged,
        onLogout: widget.onLogout,
      ),
    ];
  }

  @override
  void didUpdateWidget(covariant MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pages[3] = ProfileScreen(
      themeMode: widget.themeMode,
      seedColor: widget.seedColor,
      locale: widget.locale,
      onThemeModeChanged: widget.onThemeModeChanged,
      onSeedColorChanged: widget.onSeedColorChanged,
      onLocaleChanged: widget.onLocaleChanged,
      onLogout: widget.onLogout,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.3) : colorScheme.primary.withOpacity(0.06),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  indicatorColor: colorScheme.primary.withOpacity(0.12),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final isSelected = states.contains(WidgetState.selected);
                    return TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      letterSpacing: 0.5,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    final isSelected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      size: 24,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
                    );
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                    if (index == 1) _wishKey.currentState?.refreshPoints();
                    if (index == 2) _dataKey.currentState?.refreshData();
                  },
                  backgroundColor: isDark
                      ? const Color(0xFF1E1E2A).withOpacity(0.7)
                      : Colors.white.withOpacity(0.75),
                  height: 76,
                  elevation: 0,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      selectedIcon: const Icon(Icons.check_circle_rounded),
                      label: loc.translate('habitTab') ?? '习惯',
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.star_outline_rounded),
                      selectedIcon: const Icon(Icons.star_rounded),
                      label: loc.translate('wishTab') ?? '愿望',
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.analytics_outlined),
                      selectedIcon: const Icon(Icons.analytics_rounded),
                      label: loc.translate('dataTab') ?? '数据',
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.face_outlined),
                      selectedIcon: const Icon(Icons.face_rounded),
                      label: loc.translate('profileTab') ?? '我的',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../screens/data_screen.dart';
import '../../screens/habit_list_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/wish_screen.dart';

class MainNavigation extends StatefulWidget {
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

  final ThemeMode themeMode;
  final Color seedColor;
  final Locale locale;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Color> onSeedColorChanged;
  final ValueChanged<Locale> onLocaleChanged;
  final VoidCallback onLogout;

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
    _pages = _buildPages();
  }

  List<Widget> _buildPages() {
    return [
      const HabitListScreen(),
      WishScreen(key: _wishKey),
      DataScreen(key: _dataKey),
      _buildProfileScreen(),
    ];
  }

  ProfileScreen _buildProfileScreen() {
    return ProfileScreen(
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
  void didUpdateWidget(covariant MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pages[3] = _buildProfileScreen();
  }

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);

    if (index == 1) {
      _wishKey.currentState?.refreshPoints();
    } else if (index == 2) {
      _dataKey.currentState?.refreshData();
    }
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
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : colorScheme.primary.withOpacity(0.06),
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
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                      letterSpacing: 0.5,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.4),
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    final isSelected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      size: 24,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.4),
                    );
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDestination,
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

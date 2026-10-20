import 'dart:ui';

import 'package:flutter/material.dart';

import '../../features/analytics/presentation/pages/data_page.dart';
import '../../features/habits/presentation/pages/habit_list_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/wishes/presentation/pages/wish_page.dart';

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
  final _wishKey = GlobalKey<WishPageState>();
  final _dataKey = GlobalKey<DataPageState>();

  @override
  void initState() {
    super.initState();
    _pages = _buildPages();
  }

  List<Widget> _buildPages() => [
        const HabitListPage(),
        WishPage(key: _wishKey),
        DataPage(key: _dataKey),
        _buildProfileScreen(),
      ];

  ProfilePage _buildProfileScreen() => ProfilePage(
        themeMode: widget.themeMode,
        seedColor: widget.seedColor,
        locale: widget.locale,
        onThemeModeChanged: widget.onThemeModeChanged,
        onSeedColorChanged: widget.onSeedColorChanged,
        onLocaleChanged: widget.onLocaleChanged,
        onLogout: widget.onLogout,
      );

  @override
  void didUpdateWidget(covariant MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pages[3] = _buildProfileScreen();
  }

  void _selectDestination(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    if (index == 1) {
      _wishKey.currentState?.refreshPoints();
    } else if (index == 2) {
      _dataKey.currentState?.refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _LifeNavigationBar(
        selectedIndex: _selectedIndex,
        onSelected: _selectDestination,
      ),
    );
  }
}

class _LifeNavigationBar extends StatelessWidget {
  const _LifeNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = <({IconData icon, IconData selectedIcon, String label})>[
    (icon: Icons.today_outlined, selectedIcon: Icons.today_rounded, label: 'Today'),
    (icon: Icons.route_outlined, selectedIcon: Icons.route_rounded, label: 'Journey'),
    (icon: Icons.insights_outlined, selectedIcon: Icons.insights_rounded, label: 'Insights'),
    (icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: (dark ? const Color(0xFF1A1D19) : Colors.white)
                  .withValues(alpha: .86),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: dark ? .2 : .38),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? .24 : .07),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var index = 0; index < _items.length; index++)
                  Expanded(
                    child: _NavItem(
                      item: _items[index],
                      selected: selectedIndex == index,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ({IconData icon, IconData selectedIcon, String label}) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant.withValues(alpha: .62);

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: .11)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.06 : 1,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 22,
                  color: selected ? scheme.primary : muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: .1,
                  color: selected ? scheme.primary : muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

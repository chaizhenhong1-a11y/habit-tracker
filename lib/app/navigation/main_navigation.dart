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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [Color(0xFF101510), Color(0xFF151A15)]
                : const [Color(0xFFFFFAF1), Color(0xFFF2F1E7)],
          ),
        ),
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
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
    (icon: Icons.eco_outlined, selectedIcon: Icons.eco_rounded, label: 'Today'),
    (icon: Icons.route_outlined, selectedIcon: Icons.route_rounded, label: 'Journey'),
    (icon: Icons.auto_graph_outlined, selectedIcon: Icons.auto_graph_rounded, label: 'Insights'),
    (icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF172019) : const Color(0xFFFFFCF6);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF173E2D).withValues(alpha: dark ? .20 : .10),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: 72,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: surface.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: .07)
                      : const Color(0xFF173F30).withValues(alpha: .08),
                ),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: _NavItem(
                        item: _items[i],
                        selected: selectedIndex == i,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final active = dark ? const Color(0xFFA9C4A7) : const Color(0xFF194B36);
    final muted = dark ? const Color(0xFF87948A) : const Color(0xFF7A827C);

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? active.withValues(alpha: dark ? .16 : .09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 22,
                color: selected ? active : muted,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? active : muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

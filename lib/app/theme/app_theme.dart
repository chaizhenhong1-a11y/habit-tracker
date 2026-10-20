import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _forest = Color(0xFF194B36);
  static const _ivory = Color(0xFFF7F1E7);
  static const _paper = Color(0xFFFFFCF6);
  static const _night = Color(0xFF0F1712);
  static const _nightSurface = Color(0xFF171F19);

  static ThemeData light(Color _) => _build(
        ColorScheme.fromSeed(
          seedColor: _forest,
          brightness: Brightness.light,
          surface: _paper,
          primary: _forest,
          secondary: const Color(0xFFD2A960),
          tertiary: const Color(0xFF7D9275),
        ),
        _ivory,
      );

  static ThemeData dark(Color _) => _build(
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF8EAD91),
          brightness: Brightness.dark,
          surface: _nightSurface,
          primary: const Color(0xFFA8C6A8),
          secondary: const Color(0xFFD9B873),
          tertiary: const Color(0xFF91A78A),
        ),
        _night,
      );

  static ThemeData _build(ColorScheme scheme, Color background) {
    final dark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      typography: Typography.material2021(),
      textTheme: TextTheme(
        displaySmall: TextStyle(fontFamily: 'Georgia', fontFamilyFallback: const ['Times New Roman'], fontSize: 34, height: 1.05, fontWeight: FontWeight.w400, letterSpacing: -.8, color: scheme.onSurface),
        headlineSmall: TextStyle(fontFamily: 'Georgia', fontFamilyFallback: const ['Times New Roman'], fontSize: 26, height: 1.08, fontWeight: FontWeight.w400, letterSpacing: -.5, color: scheme.onSurface),
        titleLarge: TextStyle(fontSize: 18, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -.2, color: scheme.onSurface),
        titleMedium: TextStyle(fontSize: 15, height: 1.25, fontWeight: FontWeight.w700, color: scheme.onSurface),
        bodyLarge: TextStyle(fontSize: 15, height: 1.5, color: scheme.onSurface),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: scheme.onSurfaceVariant),
        bodySmall: TextStyle(fontSize: 12, height: 1.4, color: scheme.onSurfaceVariant),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: .1, color: scheme.onSurface),
      ),
      appBarTheme: AppBarTheme(elevation: 0, scrolledUnderElevation: 0, centerTitle: false, backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, foregroundColor: scheme.onSurface, titleTextStyle: TextStyle(fontFamily: 'Georgia', fontFamilyFallback: const ['Times New Roman'], fontSize: 24, fontWeight: FontWeight.w400, color: scheme.onSurface)),
      cardTheme: CardThemeData(elevation: 0, margin: EdgeInsets.zero, color: scheme.surface, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: scheme.outlineVariant.withValues(alpha: dark ? .16 : .28)))),
      dialogTheme: DialogThemeData(elevation: 0, backgroundColor: scheme.surface, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: scheme.surface, surfaceTintColor: Colors.transparent, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30)))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: dark ? Colors.white.withValues(alpha: .055) : Colors.white.withValues(alpha: .7), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: .22))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: .22))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.primary.withValues(alpha: .65))), contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17)),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(0, 54), backgroundColor: dark ? const Color(0xFF315B43) : _forest, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), textStyle: const TextStyle(fontWeight: FontWeight.w800))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: scheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(elevation: 0, focusElevation: 0, highlightElevation: 0, backgroundColor: dark ? const Color(0xFF315B43) : _forest, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19))),
      listTileTheme: ListTileThemeData(iconColor: scheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3)),
      switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : null), trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? scheme.primary : null)),
      chipTheme: ChipThemeData(backgroundColor: scheme.surface, selectedColor: scheme.primary.withValues(alpha: .12), side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: .3), thickness: 1),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: dark ? const Color(0xFF26342A) : const Color(0xFF173F2D), contentTextStyle: const TextStyle(color: Colors.white), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    );
  }
}

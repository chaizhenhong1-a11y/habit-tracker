import '../features/profile/presentation/pages/profile_page.dart';

@Deprecated(
  'Import features/profile/presentation/pages/profile_page.dart instead.',
)
class ProfileScreen extends ProfilePage {
  const ProfileScreen({
    super.key,
    required super.themeMode,
    required super.seedColor,
    required super.onThemeModeChanged,
    required super.onSeedColorChanged,
    required super.onLogout,
    required super.locale,
    required super.onLocaleChanged,
  });
}

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/profile_settings.dart';
import '../../domain/repositories/profile_repository.dart';

class SharedPreferencesProfileRepository implements ProfileRepository {
  static const _reminderEnabledKey = 'reminder_enabled';
  static const _reminderHourKey = 'reminder_hour';
  static const _reminderMinuteKey = 'reminder_minute';
  static const _usernameKey = 'username';
  static const _avatarUrlKey = 'avatar_url';
  static const _avatarLocalPathKey = 'avatar_local_path';

  @override
  Future<ProfileSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return ProfileSettings(
      reminderEnabled: preferences.getBool(_reminderEnabledKey) ?? false,
      reminderHour: preferences.getInt(_reminderHourKey) ?? 20,
      reminderMinute: preferences.getInt(_reminderMinuteKey) ?? 0,
      username: preferences.getString(_usernameKey) ?? '用户',
      avatarUrl: preferences.getString(_avatarUrlKey) ?? '',
      avatarLocalPath: preferences.getString(_avatarLocalPathKey) ?? '',
    );
  }

  @override
  Future<void> save(ProfileSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setBool(_reminderEnabledKey, settings.reminderEnabled),
      preferences.setInt(_reminderHourKey, settings.reminderHour),
      preferences.setInt(_reminderMinuteKey, settings.reminderMinute),
      preferences.setString(_usernameKey, settings.username),
      preferences.setString(_avatarUrlKey, settings.avatarUrl),
      preferences.setString(_avatarLocalPathKey, settings.avatarLocalPath),
    ]);
  }
}

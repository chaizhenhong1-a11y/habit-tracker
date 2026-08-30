import '../entities/profile_settings.dart';

abstract interface class ProfileRepository {
  Future<ProfileSettings> load();
  Future<void> save(ProfileSettings settings);
}

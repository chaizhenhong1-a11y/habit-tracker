class ProfileSettings {
  const ProfileSettings({
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.username = '用户',
    this.avatarUrl = '',
    this.avatarLocalPath = '',
  });

  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final String username;
  final String avatarUrl;
  final String avatarLocalPath;

  ProfileSettings copyWith({
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    String? username,
    String? avatarUrl,
    String? avatarLocalPath,
  }) {
    return ProfileSettings(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarLocalPath: avatarLocalPath ?? this.avatarLocalPath,
    );
  }
}

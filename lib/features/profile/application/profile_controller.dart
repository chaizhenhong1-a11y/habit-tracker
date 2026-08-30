import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/notifications/notification_service.dart';
import '../../habits/domain/repositories/habit_repository.dart';
import '../domain/entities/profile_settings.dart';
import '../domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({
    required this.repository,
    required this.habitRepository,
    NotificationService? notificationService,
  }) : _notificationService =
           notificationService ?? NotificationService.instance;

  final ProfileRepository repository;
  final HabitRepository habitRepository;
  final NotificationService _notificationService;

  ProfileSettings _settings = const ProfileSettings();
  bool _loaded = false;

  ProfileSettings get settings => _settings;
  bool get loaded => _loaded;

  Future<void> load() async {
    _settings = await repository.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return;
    _settings = _settings.copyWith(username: trimmed);
    await _persist();
  }

  Future<void> setAvatarAssetOrUrl(String value) async {
    _settings = _settings.copyWith(avatarUrl: value, avatarLocalPath: '');
    await _persist();
  }

  Future<void> setAvatarLocalPath(String path) async {
    _settings = _settings.copyWith(avatarUrl: '', avatarLocalPath: path);
    await _persist();
  }

  Future<void> resetAvatar() async {
    _settings = _settings.copyWith(avatarUrl: '', avatarLocalPath: '');
    await _persist();
  }

  Future<void> setReminderEnabled(bool enabled) async {
    _settings = _settings.copyWith(reminderEnabled: enabled);
    await _persist();

    if (enabled) {
      await _scheduleReminder();
    } else {
      await _notificationService.cancelAll();
    }
  }

  Future<void> setReminderTime({required int hour, required int minute}) async {
    _settings = _settings.copyWith(reminderHour: hour, reminderMinute: minute);
    await _persist();

    if (_settings.reminderEnabled) {
      await _scheduleReminder();
    }
  }

  String exportHabitsJson() {
    final habits = habitRepository.getAll();
    final payload = habits.map((habit) => habit.toMap()).toList();
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> _scheduleReminder() {
    return _notificationService.scheduleDailyReminder(
      hour: _settings.reminderHour,
      minute: _settings.reminderMinute,
      enabled: true,
    );
  }

  Future<void> _persist() async {
    await repository.save(_settings);
    notifyListeners();
  }
}

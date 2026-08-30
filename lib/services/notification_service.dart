import '../core/notifications/notification_service.dart' as core;

@Deprecated(
  'Import core/notifications/notification_service.dart and use '
  'NotificationService.instance instead.',
)
class NotificationService {
  factory NotificationService() => _instance;

  NotificationService._();

  static final NotificationService _instance = NotificationService._();

  core.NotificationService get _delegate => core.NotificationService.instance;

  Future<void> init() => _delegate.initialize();

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required bool enabled,
  }) {
    return _delegate.scheduleDailyReminder(
      hour: hour,
      minute: minute,
      enabled: enabled,
    );
  }

  Future<void> cancelAll() => _delegate.cancelAll();
}

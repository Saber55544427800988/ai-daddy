/// No-op notification service for web platform.
/// All methods are safe no-ops — flutter_local_notifications is never imported.
class NotificationService {
  static final NotificationService instance = NotificationService._init();

  NotificationService._init();

  Future<void> init() async {}

  Future<bool> requestPermission() async => false;

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String repeatPolicy = 'none',
  }) async {}

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String priority = 'high',
  }) async {}

  Future<void> scheduleDailyReminders(
      String nickname, List<String> reminderTexts) async {}

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {}

  Future<void> cancelAll() async {}

  Future<void> cancel(int id) async {}

  Future<bool> canScheduleExactAlarms() async => false;

  Future<void> openExactAlarmSettings() async {}

  Future<bool> isBatteryOptimized() async => true;

  Future<int> getPendingReminderCount() async => 0;

  Future<bool> scheduleTestReminder() async => false;

  bool get bubblesSupported => false;
}

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'myfinance_main_channel';
  static const _channelName = 'MyFinance Notifications';

  static const _dailyReminderId = 1;
  static const _budgetAlertId = 2;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: 'Budget alerts and daily reminders',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const NotificationDetails _details =
      NotificationDetails(android: _androidDetails);

  // ─── Init (called from main.dart) ────────────────────────────
  static Future<void> init() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _plugin.initialize(settings);

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Budget alerts and daily reminders',
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('NotificationService.init error: $e');
    }
  }

  // ─── Daily Reminder ───────────────────────────────────────────
static Future<void> scheduleDailyReminder(
    int hour, int minute) async {
  try {
    await _plugin.cancel(_dailyReminderId);
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'MyFinance Tracker 💰',
      "Don't forget to log your transactions today!",
      scheduledDate,
      _details,

      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,

      matchDateTimeComponents: DateTimeComponents.time,

      // ✅ REQUIRED PARAM (THIS FIXES YOUR ERROR)
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  } catch (e) {
    debugPrint('scheduleDailyReminder error: $e');
  }
}



  static Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

  // ─── Budget Alert ─────────────────────────────────────────────
  static Future<void> showBudgetAlert(
      String categoryName, double budget, double spent) async {
    try {
      await _plugin.show(
        _budgetAlertId,
        '⚠️ Budget Alert',
        "You've exceeded your $categoryName budget "
            "(spent ${spent.toStringAsFixed(0)} of ${budget.toStringAsFixed(0)})",
        _details,
      );
    } catch (e) {
      debugPrint('showBudgetAlert error: $e');
    }
  }

  // ─── Helper ───────────────────────────────────────────────────
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
  // closing brace moved to end

  // ─── Scheduled Export Reminder ────────────────────────────────
  static const _exportReminderId = 3;

  static Future<void> scheduleExportReminder(
      int hour, int minute, String frequency) async {
    try {
      await _plugin.cancel(_exportReminderId);
      final scheduledDate = _nextInstanceOfTime(hour, minute);

      DateTimeComponents repeat;
      switch (frequency) {
        case 'Daily':
          repeat = DateTimeComponents.time;
          break;
        case 'Weekly':
          repeat = DateTimeComponents.dayOfWeekAndTime;
          break;
        default: // Monthly
          repeat = DateTimeComponents.dayOfMonthAndTime;
      }

      await _plugin.zonedSchedule(
        _exportReminderId,
        'MyFinance Export Ready 📊',
        'Tap to generate and share your scheduled report.',
        scheduledDate,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: repeat,
      );
    } catch (e) {
      debugPrint('scheduleExportReminder error: $e');
    }
  }

  static Future<void> cancelExportReminder() async {
    await _plugin.cancel(_exportReminderId);
  }

}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service for managing local notifications (workout reminders)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Notification IDs
  static const int dailyReminderId = 0;
  static const int restDayReminderId = 1;
  static const int weeklyGoalReminderId = 2;

  // SharedPreferences keys
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyReminderTime = 'reminder_time';
  static const String _keyRestDayReminders = 'rest_day_reminders';
  static const String _keyWeeklyGoalReminders = 'weekly_goal_reminders';

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone database
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      final iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );

      // Combined initialization settings
      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      debugPrint('NotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('NotificationService: Initialization failed: $e');
    }
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.requestNotificationsPermission() ??
          false;
    }
    return true;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? false;
  }

  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);

    if (enabled) {
      await scheduleDefaultReminders();
    } else {
      await cancelAllNotifications();
    }
  }

  /// Get reminder time (hour of day, 0-23)
  Future<int> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReminderTime) ?? 18; // Default: 6 PM
  }

  /// Set reminder time
  Future<void> setReminderTime(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderTime, hour);

    // Reschedule notifications with new time
    final enabled = await areNotificationsEnabled();
    if (enabled) {
      await scheduleDefaultReminders();
    }
  }

  /// Check if rest day reminders are enabled
  Future<bool> areRestDayRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRestDayReminders) ?? true;
  }

  /// Enable/disable rest day reminders
  Future<void> setRestDayReminders(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRestDayReminders, enabled);

    if (!enabled) {
      await _notifications.cancel(restDayReminderId);
    }
  }

  /// Check if weekly goal reminders are enabled
  Future<bool> areWeeklyGoalRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWeeklyGoalReminders) ?? true;
  }

  /// Enable/disable weekly goal reminders
  Future<void> setWeeklyGoalReminders(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeeklyGoalReminders, enabled);

    if (!enabled) {
      await _notifications.cancel(weeklyGoalReminderId);
    }
  }

  /// Schedule default workout reminders
  Future<void> scheduleDefaultReminders() async {
    final hour = await getReminderTime();

    await scheduleDailyReminder(
      hour: hour,
      minute: 0,
      title: 'Time to work out! 💪',
      body: 'Stay consistent with your fitness goals',
    );

    debugPrint('NotificationService: Scheduled daily reminder at $hour:00');
  }

  /// Schedule a daily reminder
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      dailyReminderId,
      title,
      body,
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Send immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      _notificationDetails(),
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('NotificationService: All notifications cancelled');
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Notification details for both platforms
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'workout_reminders',
        'Workout Reminders',
        channelDescription: 'Daily reminders to stay on track with workouts',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Handle notification tap (foreground)
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Can navigate to specific screen based on payload
  }

  /// Handle iOS foreground notification
  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    debugPrint('iOS notification received: $title');
  }
}

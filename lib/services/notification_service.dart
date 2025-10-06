import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();

    // For Android 13+, request notification permissions
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // For iOS, request permissions
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true; // Windows doesn't need explicit permission request
  }

  Future<void> scheduleContestReminder({
    required String contestName,
    required DateTime contestTime,
    required int reminderMinutes,
  }) async {
    await initialize();

    final notificationTime = contestTime.subtract(
      Duration(minutes: reminderMinutes),
    );

    // Don't schedule if the time has already passed
    if (notificationTime.isBefore(DateTime.now())) {
      return;
    }

    final id = _generateNotificationId(contestName, reminderMinutes);

    const androidDetails = AndroidNotificationDetails(
      'contest_reminders',
      'Contest Reminders',
      channelDescription: 'Notifications for upcoming LeetCode contests',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final timeString = _formatReminderTime(reminderMinutes);
    final body = '$contestName starts in $timeString';

    // Use simple scheduling for now
    if (notificationTime.isAfter(DateTime.now())) {
      // For simplicity, we'll use the show method for immediate notifications
      // In a production app, you'd want to implement proper scheduling
      await _notifications.show(
        id,
        'LeetCode Contest Reminder',
        body,
        notificationDetails,
      );
    }

    // Save the reminder to preferences
    await _saveReminder(contestName, reminderMinutes, notificationTime);
  }

  Future<void> cancelContestReminder(
    String contestName,
    int reminderMinutes,
  ) async {
    final id = _generateNotificationId(contestName, reminderMinutes);
    await _notifications.cancel(id);
    await _removeReminder(contestName, reminderMinutes);
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('contest_reminders');
  }

  Future<void> scheduleDailyProblemReminders(String problemTitle) async {
    await initialize();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Schedule reminders at 10 AM, 2 PM, 6 PM, and 9 PM if not passed
    final reminderTimes = [
      {
        'hour': 10,
        'message': 'Morning reminder: Don\'t forget today\'s problem!',
      },
      {
        'hour': 14,
        'message': 'Afternoon reminder: Still time to solve today\'s problem!',
      },
      {
        'hour': 18,
        'message': 'Evening reminder: Have you solved today\'s problem?',
      },
      {
        'hour': 21,
        'message': 'Last call: Solve today\'s problem before midnight!',
      },
    ];

    int reminderId = 1000; // Start from a high number to avoid conflicts

    for (final reminder in reminderTimes) {
      final reminderTime = today.add(Duration(hours: reminder['hour'] as int));

      if (reminderTime.isAfter(now)) {
        const androidDetails = AndroidNotificationDetails(
          'daily_problem_reminders',
          'Daily Problem Reminders',
          channelDescription: 'Reminders for LeetCode daily problems',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        final message = '${reminder['message']} - $problemTitle';

        // For now, just show immediate notification for testing
        // In production, you'd schedule these for the specific times
        await _notifications.show(
          reminderId++,
          'LeetCode Daily Problem',
          message,
          notificationDetails,
        );

        // Save the reminder info
        await _saveReminder(
          'daily_problem_${today.day}_${today.month}',
          0, // Use 0 to indicate daily reminder
          reminderTime,
        );
      }
    }
  }

  Future<void> cancelDailyProblemReminders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dailyReminderId = 'daily_problem_${today.day}_${today.month}';

    // Cancel notifications with IDs 1000-1003 (daily reminders)
    for (int i = 1000; i < 1004; i++) {
      await _notifications.cancel(i);
    }

    await _removeReminder(dailyReminderId, 0);
  }

  Future<List<Map<String, dynamic>>> getActiveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString('contest_reminders') ?? '[]';
    final reminders = List<Map<String, dynamic>>.from(
      json.decode(remindersJson),
    );

    // Filter out past reminders
    final now = DateTime.now();
    final activeReminders = reminders.where((reminder) {
      final reminderTime = DateTime.parse(reminder['reminderTime']);
      return reminderTime.isAfter(now);
    }).toList();

    // Update stored reminders to remove past ones
    if (activeReminders.length != reminders.length) {
      await prefs.setString('contest_reminders', json.encode(activeReminders));
    }

    return activeReminders;
  }

  Future<bool> hasReminder(String contestName, int reminderMinutes) async {
    final activeReminders = await getActiveReminders();
    return activeReminders.any(
      (reminder) =>
          reminder['contestName'] == contestName &&
          reminder['reminderMinutes'] == reminderMinutes,
    );
  }

  int _generateNotificationId(String contestName, int reminderMinutes) {
    return (contestName + reminderMinutes.toString()).hashCode.abs();
  }

  String _formatReminderTime(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else if (minutes == 60) {
      return '1 hour';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours hours';
      } else {
        return '$hours hours $remainingMinutes minutes';
      }
    }
  }

  Future<void> _saveReminder(
    String contestName,
    int reminderMinutes,
    DateTime reminderTime,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString('contest_reminders') ?? '[]';
    final reminders = List<Map<String, dynamic>>.from(
      json.decode(remindersJson),
    );

    reminders.add({
      'contestName': contestName,
      'reminderMinutes': reminderMinutes,
      'reminderTime': reminderTime.toIso8601String(),
    });

    await prefs.setString('contest_reminders', json.encode(reminders));
  }

  Future<void> _removeReminder(String contestName, int reminderMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString('contest_reminders') ?? '[]';
    final reminders = List<Map<String, dynamic>>.from(
      json.decode(remindersJson),
    );

    reminders.removeWhere(
      (reminder) =>
          reminder['contestName'] == contestName &&
          reminder['reminderMinutes'] == reminderMinutes,
    );

    await prefs.setString('contest_reminders', json.encode(reminders));
  }
}

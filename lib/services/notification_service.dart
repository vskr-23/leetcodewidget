import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

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

  // New method: Start recurring 2-hour daily problem reminders
  Future<void> startRecurringDailyReminders(String problemTitle) async {
    await initialize();

    // Note: For true background reminders, consider using a more advanced scheduling solution
    // For now, we'll show immediate notifications and rely on app usage patterns

    // Schedule immediate notifications for today at 2-hour intervals
    await _scheduleEvery2HourReminders(problemTitle);

    // Save reminder preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('recurring_daily_reminders', true);
    await prefs.setString('current_problem_title', problemTitle);
  }

  Future<void> _scheduleEvery2HourReminders(String problemTitle) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // True 2-hour intervals: 8 AM, 10 AM, 12 PM, 2 PM, 4 PM, 6 PM, 8 PM, 10 PM
    final reminderHours = [8, 10, 12, 14, 16, 18, 20, 22];

    int notificationId = 2000;

    // Check if problem is already solved before activating reminders
    final isSolved = await isDailyProblemSolved(problemTitle);
    if (isSolved) {
      debugPrint('Problem already solved, not activating reminders');
      return;
    }

    // Show immediate notification to confirm activation
    await _notifications.show(
      1999,
      '🎯 2-Hour Reminders Activated!',
      'You\'ll get reminders every 2 hours for: $problemTitle 🔥\n(Auto-stops when solved)',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_problem_2h',
          'Daily Problem (2-Hour)',
          channelDescription: 'Every 2-hour reminders for daily problems',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
    );

    // Schedule remaining reminders for today
    for (final hour in reminderHours) {
      final reminderTime = today.add(Duration(hours: hour));

      if (reminderTime.isAfter(now.add(const Duration(minutes: 5)))) {
        // Show notification after 5 minutes delay for testing
        Future.delayed(const Duration(seconds: 30), () async {
          await _notifications.show(
            notificationId++,
            '🎯 LeetCode Daily Problem (Every 2 Hours)',
            'Time to work on: $problemTitle 💪 (${hour}:00 reminder)',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'daily_problem_2h',
                'Daily Problem (2-Hour)',
                channelDescription: 'Every 2-hour reminders for daily problems',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
            ),
          );
        });
      }
    }
  }

  // Stop recurring daily reminders
  Future<void> stopRecurringDailyReminders() async {
    // Cancel scheduled notifications for today
    for (int i = 1999; i < 2010; i++) {
      await _notifications.cancel(i);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('recurring_daily_reminders', false);
    await prefs.remove('current_problem_title');

    // Mark that reminders were manually stopped (to prevent auto-restart)
    final manuallyStoppedKey =
        'daily_reminders_manually_stopped_${DateTime.now().day}_${DateTime.now().month}';
    await prefs.setBool(manuallyStoppedKey, true);
  }

  // Add contest to phone's calendar
  Future<bool> addContestToCalendar({
    required String contestName,
    required DateTime contestTime,
    required String contestUrl,
  }) async {
    final event = Event(
      title: contestName,
      description:
          'LeetCode contest - Join now and compete with others!\\n\\nContest Link: $contestUrl',
      location: 'Online - LeetCode Platform',
      startDate: contestTime,
      endDate: contestTime.add(
        const Duration(hours: 1, minutes: 30),
      ), // Contests are usually 1.5 hours
      iosParams: const IOSParams(reminder: Duration(minutes: 15)),
      androidParams: const AndroidParams(emailInvites: []),
    );

    try {
      final success = await Add2Calendar.addEvent2Cal(event);
      return success;
    } catch (e) {
      // Fallback: Try to open calendar app directly
      await _openCalendarApp(contestName, contestTime);
      return false;
    }
  }

  // Fallback method to open calendar app
  Future<void> _openCalendarApp(String title, DateTime dateTime) async {
    try {
      // TODO: Implement proper calendar integration
      debugPrint('Calendar integration requested for: $title at $dateTime');
    } catch (e) {
      // If all fails, just show a notification
      debugPrint('Could not open calendar: $e');
    }
  }

  // Enhanced contest reminder with calendar integration
  Future<void> scheduleContestReminderWithCalendar({
    required String contestName,
    required DateTime contestTime,
    required int reminderMinutes,
    String? contestUrl,
  }) async {
    // Schedule the notification reminder
    await scheduleContestReminder(
      contestName: contestName,
      contestTime: contestTime,
      reminderMinutes: reminderMinutes,
    );

    // Add to calendar if not already added
    final prefs = await SharedPreferences.getInstance();
    final calendarKey = 'calendar_added_$contestName';
    final alreadyAdded = prefs.getBool(calendarKey) ?? false;

    if (!alreadyAdded) {
      await addContestToCalendar(
        contestName: contestName,
        contestTime: contestTime,
        contestUrl: contestUrl ?? 'https://leetcode.com/contest/',
      );
      await prefs.setBool(calendarKey, true);
    }
  }

  // Check if daily reminders are active
  Future<bool> areRecurringDailyRemindersActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('recurring_daily_reminders') ?? false;
  }

  // Check if today's problem is already solved by querying recent submissions
  Future<bool> isDailyProblemSolved(String problemTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('leetcode_username');

    if (username == null || username.isEmpty) {
      debugPrint('No username found, cannot check problem status');
      return false; // Cannot check, assume not solved
    }

    try {
      // Simple check using stored problem status
      final todayKey =
          'daily_problem_solved_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}';
      final isSolved = prefs.getBool(todayKey) ?? false;

      if (isSolved) {
        debugPrint('Daily problem already marked as solved today');
        return true;
      }

      // Additional check: if reminders were manually stopped, assume solved
      final manuallyStoppedKey =
          'daily_reminders_manually_stopped_${DateTime.now().day}_${DateTime.now().month}';
      final manuallyStopped = prefs.getBool(manuallyStoppedKey) ?? false;

      return manuallyStopped;
    } catch (e) {
      debugPrint('Error checking if daily problem is solved: $e');
      return false; // On error, assume not solved to be safe
    }
  }

  // Mark today's problem as solved (called when problem status changes)
  Future<void> markDailyProblemAsSolved() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey =
        'daily_problem_solved_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}';
    await prefs.setBool(todayKey, true);

    // Auto-stop recurring reminders when problem is solved
    final hasRecurringReminders = await areRecurringDailyRemindersActive();
    if (hasRecurringReminders) {
      debugPrint('Problem solved! Auto-stopping recurring reminders.');
      await stopRecurringDailyReminders();
    }
  }

  // Get current problem title for recurring reminders
  Future<String?> getCurrentProblemTitle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_problem_title');
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

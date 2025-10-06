import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class UpcomingContests extends StatefulWidget {
  const UpcomingContests({super.key});

  @override
  State<UpcomingContests> createState() => _UpcomingContestsState();
}

class _UpcomingContestsState extends State<UpcomingContests> {
  final NotificationService _notificationService = NotificationService();
  Map<String, Set<int>> _activeReminders = {};

  @override
  void initState() {
    super.initState();
    _loadActiveReminders();
  }

  Future<void> _loadActiveReminders() async {
    final activeReminders = await _notificationService.getActiveReminders();
    setState(() {
      _activeReminders = {};
      for (final reminder in activeReminders) {
        final contestName = reminder['contestName'] as String;
        final minutes = reminder['reminderMinutes'] as int;
        _activeReminders.putIfAbsent(contestName, () => <int>{}).add(minutes);
      }
    });
  }

  Future<void> _toggleReminder(
    String contestName,
    DateTime contestTime,
    int minutes,
  ) async {
    final hasReminder =
        _activeReminders[contestName]?.contains(minutes) ?? false;

    if (hasReminder) {
      await _notificationService.cancelContestReminder(contestName, minutes);
      setState(() {
        _activeReminders[contestName]?.remove(minutes);
        if (_activeReminders[contestName]?.isEmpty ?? false) {
          _activeReminders.remove(contestName);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder cancelled for $contestName')),
        );
      }
    } else {
      final hasPermission = await _notificationService.requestPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification permission required')),
          );
        }
        return;
      }

      await _notificationService.scheduleContestReminder(
        contestName: contestName,
        contestTime: contestTime,
        reminderMinutes: minutes,
      );
      setState(() {
        _activeReminders.putIfAbsent(contestName, () => <int>{}).add(minutes);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder set for $contestName')),
        );
      }
    }
  }

  void _showReminderOptions(String contestName, DateTime contestTime) {
    final reminderOptions = [15, 30, 60]; // minutes

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Reminder for $contestName',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...reminderOptions.map((minutes) {
              final isActive =
                  _activeReminders[contestName]?.contains(minutes) ?? false;
              final timeText = minutes == 60 ? '1 hour' : '$minutes minutes';

              return ListTile(
                leading: Icon(
                  isActive
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: isActive ? Colors.orange : Colors.grey,
                ),
                title: Text(
                  '$timeText before',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[400],
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isActive
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  _toggleReminder(contestName, contestTime, minutes);
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 8),
            if (_activeReminders[contestName]?.isNotEmpty ?? false)
              ListTile(
                leading: const Icon(Icons.clear_all, color: Colors.red),
                title: const Text(
                  'Clear all reminders',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  final reminderMinutes = List<int>.from(
                    _activeReminders[contestName] ?? {},
                  );
                  for (final minutes in reminderMinutes) {
                    await _notificationService.cancelContestReminder(
                      contestName,
                      minutes,
                    );
                  }
                  setState(() {
                    _activeReminders.remove(contestName);
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('All reminders cleared for $contestName'),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  // Generate upcoming contests based on LeetCode's schedule
  List<Map<String, dynamic>> _generateUpcomingContests() {
    final now = DateTime.now();
    final contests = <Map<String, dynamic>>[];

    // LeetCode contests are in Eastern Time (UTC-5 in standard time, UTC-4 in daylight time)
    // Weekly contests: Every Sunday at 10:30 AM ET
    // Biweekly contests: Every other Saturday at 8:00 AM ET

    int weeklyCount = 420; // Starting from a recent contest number
    int biweeklyCount = 142; // Starting from a recent biweekly contest number

    // Generate next 4-6 contests
    for (int i = 0; i < 30; i++) {
      final checkDate = now.add(Duration(days: i));

      // Weekly contest - Every Sunday at 8:00 AM IST
      if (checkDate.weekday == DateTime.sunday) {
        // Create contest time directly in IST
        final contestTimeIST = DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day,
          8, // 8:00 AM IST
          0,
        );

        final contestTimeLocal = contestTimeIST;

        if (contestTimeLocal.isAfter(now)) {
          contests.add({
            'name': 'W-$weeklyCount',
            'fullName': 'Weekly Contest $weeklyCount',
            'date': contestTimeLocal,
            'type': 'weekly',
          });
          weeklyCount++;
        }
      }

      // Biweekly contest - Every other Saturday at 8:00 AM ET
      if (checkDate.weekday == DateTime.saturday) {
        // Simple biweekly calculation (every 14 days from a base date)
        final baseDate = DateTime(2024, 1, 6); // A known biweekly Saturday
        final daysDiff = checkDate.difference(baseDate).inDays;

        if (daysDiff >= 0 && daysDiff % 14 < 7) {
          // Biweekly contest - Every other Saturday at 8:00 PM IST
          final contestTimeIST = DateTime(
            checkDate.year,
            checkDate.month,
            checkDate.day,
            20, // 8:00 PM IST
            0,
          );

          final contestTimeLocal = contestTimeIST;

          if (contestTimeLocal.isAfter(now)) {
            contests.add({
              'name': 'BW-$biweeklyCount',
              'fullName': 'Biweekly Contest $biweeklyCount',
              'date': contestTimeLocal,
              'type': 'biweekly',
            });
            biweeklyCount++;
          }
        }
      }

      if (contests.length >= 3) break; // Limit to next 3 contests
    }

    // Sort by date
    contests.sort((a, b) => a['date'].compareTo(b['date']));
    return contests;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today ${DateFormat('h:mm a').format(date)} IST';
    } else if (difference == 1) {
      return 'Tomorrow ${DateFormat('h:mm a').format(date)} IST';
    } else {
      return '${DateFormat('MMM d, h:mm a').format(date)} IST';
    }
  }

  Color _getContestColor(String type) {
    switch (type) {
      case 'weekly':
        return Colors.blue;
      case 'biweekly':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final contests = _generateUpcomingContests();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      color: const Color(0xFF1C1C1E), // Dark background to match other widgets
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Upcoming Contests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Contest List
            if (contests.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'No upcoming contests scheduled',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...contests
                  .map(
                    (contest) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: _getContestColor(contest['type']),
                            width: 4,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Contest Icon
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _getContestColor(
                                contest['type'],
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              contest['type'] == 'weekly'
                                  ? Icons.calendar_view_week
                                  : Icons.calendar_month,
                              color: _getContestColor(contest['type']),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Contest Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contest['name'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(contest['date']),
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Reminder Button
                          IconButton(
                            icon: Icon(
                              (_activeReminders[contest['name']]?.isNotEmpty ??
                                      false)
                                  ? Icons.notifications_active
                                  : Icons.notifications_none,
                              color:
                                  (_activeReminders[contest['name']]
                                          ?.isNotEmpty ??
                                      false)
                                  ? Colors.orange
                                  : Colors.grey,
                              size: 20,
                            ),
                            onPressed: () => _showReminderOptions(
                              contest['name'],
                              contest['date'],
                            ),
                            tooltip: 'Set reminder',
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(width: 8),

                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getContestColor(
                                contest['type'],
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              contest['type'].toUpperCase(),
                              style: TextStyle(
                                color: _getContestColor(contest['type']),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),

            // Footer note
            if (contests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Contest times shown in Indian Standard Time (IST)',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

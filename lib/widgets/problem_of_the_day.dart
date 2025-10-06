import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_service.dart';

class ProblemOfTheDay extends StatefulWidget {
  final String problemTitle;
  final bool solved;
  final String difficulty;
  final String? problemLink;

  const ProblemOfTheDay({
    required this.problemTitle,
    required this.solved,
    required this.difficulty,
    this.problemLink,
    super.key,
  });

  @override
  State<ProblemOfTheDay> createState() => _ProblemOfTheDayState();
}

class _ProblemOfTheDayState extends State<ProblemOfTheDay> {
  bool _isSolved = false;
  final NotificationService _notificationService = NotificationService();
  bool _hasReminder = false;
  final String _reminderId = 'daily_problem_reminder';

  @override
  void initState() {
    super.initState();
    _isSolved = widget.solved;
    _loadReminderStatus();
  }

  Future<void> _loadReminderStatus() async {
    final activeReminders = await _notificationService.getActiveReminders();
    setState(() {
      _hasReminder = activeReminders.any(
        (reminder) => reminder['contestName'] == _reminderId,
      );
    });
  }

  @override
  void didUpdateWidget(ProblemOfTheDay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.solved != widget.solved) {
      setState(() {
        _isSolved = widget.solved;
      });

      // If problem is now solved, cancel any active reminders
      if (_isSolved && _hasReminder) {
        _cancelDailyReminders();
      }
    }
  }

  Future<void> _toggleDailyReminder() async {
    if (_isSolved) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Problem already solved!')));
      return;
    }

    if (_hasReminder) {
      await _cancelDailyReminders();
    } else {
      await _setDailyReminder();
    }
  }

  Future<void> _setDailyReminder() async {
    final hasPermission = await _notificationService.requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission required')),
        );
      }
      return;
    }

    await _notificationService.scheduleDailyProblemReminders(
      widget.problemTitle,
    );

    setState(() {
      _hasReminder = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daily reminders set for "${widget.problemTitle}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: _cancelDailyReminders,
          ),
        ),
      );
    }
  }

  Future<void> _cancelDailyReminders() async {
    await _notificationService.cancelDailyProblemReminders();

    setState(() {
      _hasReminder = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily reminders cancelled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main content
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.yellow),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.problemTitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        widget.difficulty,
                        style: TextStyle(
                          color: widget.difficulty == 'Easy'
                              ? Colors.green
                              : widget.difficulty == 'Medium'
                              ? Colors.orange
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Reminder button (only show if not solved)
                if (!_isSolved) ...[
                  IconButton(
                    icon: Icon(
                      _hasReminder
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: _hasReminder ? Colors.orange : Colors.grey,
                      size: 20,
                    ),
                    onPressed: _toggleDailyReminder,
                    tooltip: _hasReminder
                        ? 'Cancel daily reminders'
                        : 'Set daily reminders',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                ],

                Icon(
                  Icons.check_circle,
                  color: _isSolved ? Colors.green : Colors.grey,
                ),
              ],
            ),

            // Open problem button
            if (widget.problemLink != null && widget.problemLink!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.open_in_browser, size: 16),
                  label: Text('Open Problem', style: TextStyle(fontSize: 12)),
                  onPressed: () async {
                    final urlString =
                        'https://leetcode.com${widget.problemLink}';
                    final url = Uri.parse(urlString);

                    try {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not open the problem in a browser. Please visit LeetCode website directly.',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    minimumSize: Size(120, 36),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

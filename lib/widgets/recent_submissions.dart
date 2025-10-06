import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentSubmissions extends StatelessWidget {
  final List<dynamic> submissions;

  const RecentSubmissions({super.key, required this.submissions});

  @override
  Widget build(BuildContext context) {
    if (submissions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(child: Text('No recent submissions found')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Submissions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Today: ${_getSubmissionsToday()} solved',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (
              int index = 0;
              index < (submissions.length > 5 ? 5 : submissions.length);
              index++
            )
              _buildSubmissionItem(submissions[index]),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionItem(dynamic submission) {
    final timestamp = int.parse(submission['timestamp'].toString());
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final formattedDate = DateFormat('MMM d, yyyy, h:mm a').format(dateTime);

    Color statusColor;
    if (submission['statusDisplay'] == 'Accepted' ||
        submission['statusDisplay'] == 'Success') {
      statusColor = Colors.green;
    } else if (submission['statusDisplay'] == 'Wrong Answer') {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission['title'] ?? 'Unknown Problem',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              submission['statusDisplay'] ?? 'Unknown',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              submission['lang'] ?? 'Unknown',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to count submissions done today
  int _getSubmissionsToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int count = 0;
    final Set<String> uniqueTitleSlugs = {};

    for (var submission in submissions) {
      final timestamp = int.parse(submission['timestamp'].toString());
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final submissionDate = DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
      );

      // Check if submission was made today
      if (submissionDate.isAtSameMomentAs(today)) {
        final titleSlug = submission['titleSlug'] as String;
        final statusDisplay = submission['statusDisplay'] as String;

        // Only count accepted submissions and only count each problem once
        if ((statusDisplay == 'Accepted' || statusDisplay == 'Success') &&
            !uniqueTitleSlugs.contains(titleSlug)) {
          uniqueTitleSlugs.add(titleSlug);
          count++;
        }
      }
    }

    return count;
  }
}

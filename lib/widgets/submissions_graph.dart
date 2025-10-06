import 'package:flutter/material.dart';
import 'custom_heatmap.dart';

class SubmissionsGraph extends StatelessWidget {
  final Map<String, dynamic>? submissionCalendar;
  final int totalActiveDays;
  final int maxStreak;

  const SubmissionsGraph({
    super.key,
    this.submissionCalendar,
    this.totalActiveDays = 0,
    this.maxStreak = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Parse the submission calendar data
    Map<DateTime, int> heatMapData = _parseSubmissionCalendar();

    return CustomHeatMap(
      submissionsData: heatMapData,
      totalActiveDays: totalActiveDays,
      maxStreak: maxStreak,
    );
  }

  Map<DateTime, int> _parseSubmissionCalendar() {
    // If no submission calendar data is available, return an empty map
    if (submissionCalendar == null) {
      return {};
    }

    final Map<DateTime, int> result = {};

    submissionCalendar!.forEach((key, value) {
      // LeetCode provides timestamps in seconds, convert to milliseconds for DateTime
      try {
        final timestamp = int.parse(key) * 1000;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        // Round the date to remove time portion
        final roundedDate = DateTime(date.year, date.month, date.day);

        // LeetCode provides submission count as an integer
        final count = value is int
            ? value
            : int.tryParse(value.toString()) ?? 0;
        result[roundedDate] = count;
      } catch (e) {
        // Skip invalid entries
        debugPrint(
          'Error parsing submission calendar entry: $key -> $value: $e',
        );
      }
    });

    return result;
  }
}

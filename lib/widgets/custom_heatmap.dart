import 'package:flutter/material.dart';
import 'dart:math';
import 'heatmap_calendar.dart';

class CustomHeatMap extends StatefulWidget {
  final Map<DateTime, int> submissionsData;
  final int totalActiveDays;
  final int maxStreak;

  const CustomHeatMap({
    Key? key,
    required this.submissionsData,
    this.totalActiveDays = 0,
    this.maxStreak = 0,
  }) : super(key: key);

  @override
  State<CustomHeatMap> createState() => _CustomHeatMapState();
}

class _CustomHeatMapState extends State<CustomHeatMap> {
  late final PageController _monthPageController;
  final int totalMonthsToShow = 12; // Show 12 months (1 year)
  late int _displayedPageIndex;

  @override
  void initState() {
    super.initState();
    // Start with the current month (rightmost)
    _displayedPageIndex = totalMonthsToShow - 1;
    _monthPageController = PageController(initialPage: _displayedPageIndex);
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current date
    final now = DateTime.now();

    // Calculate the real streak value from user data
    int totalSubmissions = 0;
    List<DateTime> allDates = [];

    widget.submissionsData.forEach((date, count) {
      totalSubmissions += count;
      allDates.add(date);
    });

    int calculatedMaxStreak = _calculateMaxStreak(allDates);

    // Use either API streak or calculated streak, whichever is available
    final int displayStreak = widget.maxStreak > 0
        ? widget.maxStreak
        : calculatedMaxStreak;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      color: const Color(
        0xFF1C1C1E,
      ), // Dark background to match reference image
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar title
                const Text(
                  'Submissions Calendar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Month navigation on separate row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 18,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white70,
                      ),
                      onPressed: _displayedPageIndex > 0
                          ? () {
                              _monthPageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getMonthYearText(_displayedPageIndex),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 18,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _displayedPageIndex < totalMonthsToShow - 1
                          ? () {
                              _monthPageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Horizontally scrollable months
                SizedBox(
                  height: 120, // Height without tooltip space
                  child: PageView.builder(
                    controller: _monthPageController,
                    itemCount: totalMonthsToShow,
                    onPageChanged: (pageIndex) {
                      setState(() {
                        _displayedPageIndex = pageIndex;
                      });
                    },
                    itemBuilder: (context, pageIndex) {
                      // Calculate month and year for this page
                      final monthsAgo = totalMonthsToShow - 1 - pageIndex;
                      final targetDate = DateTime(
                        now.year,
                        now.month - monthsAgo,
                        1,
                      );

                      return HeatmapCalendar(
                        submissionsData: widget.submissionsData,
                        selectedMonth: targetDate.month,
                        selectedYear: targetDate.year,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),

                // Stats row
                _buildStatsRow(
                  totalSubmissions,
                  widget.totalActiveDays,
                  displayStreak,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Calculate maximum streak from a list of dates
  int _calculateMaxStreak(List<DateTime> activeDates) {
    if (activeDates.isEmpty) return 0;

    // Normalize dates to remove time component and create a set of unique days
    Set<int> activeDaysSet = {};

    for (var date in activeDates) {
      // Convert date to epoch days (days since epoch) for easy consecutive day checking
      int epochDays =
          DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/
          (1000 * 60 * 60 * 24);
      activeDaysSet.add(epochDays);
    }

    if (activeDaysSet.isEmpty) return 0;

    // Convert to list and sort
    List<int> sortedDays = activeDaysSet.toList()..sort();

    int currentStreak = 1;
    int maxStreak = 1;

    // Check for consecutive days
    for (int i = 1; i < sortedDays.length; i++) {
      if (sortedDays[i] == sortedDays[i - 1] + 1) {
        // Consecutive day
        currentStreak++;
        maxStreak = max(maxStreak, currentStreak);
      } else {
        // Break in streak
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  // Method to build the stats display with total data
  Widget _buildStatsRow(int totalSubmissions, int activeDays, int maxStreak) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Active Days', '$activeDays'),
          Container(height: 24, width: 1, color: Colors.grey.withOpacity(0.3)),
          _buildStatItem('Submissions', '$totalSubmissions'),
          Container(height: 24, width: 1, color: Colors.grey.withOpacity(0.3)),
          _buildStatItem('Max Streak', '$maxStreak'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  // Helper method to get month and year text for display
  String _getMonthYearText(int pageIndex) {
    final now = DateTime.now();
    final monthsAgo = totalMonthsToShow - 1 - pageIndex;
    final targetDate = DateTime(now.year, now.month - monthsAgo, 1);

    return '${_getMonthName(targetDate.month)} ${targetDate.year}';
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return monthNames[(month - 1) % 12]; // Use modulo to handle month overflow
  }
}

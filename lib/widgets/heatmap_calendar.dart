import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HeatmapCalendar extends StatefulWidget {
  final Map<DateTime, int> submissionsData;
  final int selectedMonth;
  final int selectedYear;

  const HeatmapCalendar({
    Key? key,
    required this.submissionsData,
    this.selectedMonth = 4, // Default to April
    this.selectedYear = 2025, // Default to 2025
  }) : super(key: key);

  @override
  State<HeatmapCalendar> createState() => _HeatmapCalendarState();
}

class _HeatmapCalendarState extends State<HeatmapCalendar> {
  // For tooltip tracking (simplified)
  DateTime? _tooltipDate;

  @override
  void dispose() {
    super.dispose();
  }

  void _showTooltipPopup(DateTime date, int count, Offset position) {
    // Get screen size to ensure tooltip stays within bounds
    final Size screenSize = MediaQuery.of(context).size;

    // Calculate tooltip position relative to the calendar widget
    double tooltipX = position.dx - 60; // Offset to center tooltip
    double tooltipY = position.dy - 50; // Position above the cell

    // Ensure tooltip doesn't go off screen
    if (tooltipX < 10) tooltipX = 10;
    if (tooltipX > screenSize.width - 150) tooltipX = screenSize.width - 150;
    if (tooltipY < 50)
      tooltipY = position.dy + 25; // Show below if no space above

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              top: tooltipY,
              left: tooltipX,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '$count ${count == 1 ? 'submission' : 'submissions'} on ${DateFormat('MMM d').format(date)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use the selected month and year
    final DateTime calendarDate = DateTime(
      widget.selectedYear,
      widget.selectedMonth,
      1,
    );

    return SizedBox(
      height: 120, // Fixed height without tooltip space
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heatmap grid for the selected month
          Expanded(child: _buildHeatmapGrid(calendarDate)),
          // Legend row
          SizedBox(height: 20, child: _buildLegendRow()),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
  }

  Widget _buildHeatmapGrid(DateTime calendarDate) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day of week labels column
          _buildDayLabelsColumn(),
          // Fixed grid of cells
          Expanded(child: _buildFixedGrid(calendarDate)),
        ],
      ),
    );
  }

  Widget _buildDayLabelsColumn() {
    const List<String> dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      width: 20,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: dayLabels.map((label) {
          return Flexible(
            child: Container(
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFixedGrid(DateTime calendarDate) {
    // Determine which day of the week the 1st of the month falls on
    final DateTime firstDayOfMonth = DateTime(
      calendarDate.year,
      calendarDate.month,
      1,
    );
    int firstDayOfWeek = firstDayOfMonth.weekday % 7;
    // Handle Sunday (convert from 0 to 6)
    if (firstDayOfMonth.weekday == 7) {
      firstDayOfWeek = 0;
    }

    // Get the number of days in the month
    final int daysInMonth = DateTime(
      calendarDate.year,
      calendarDate.month + 1,
      0,
    ).day;

    // Generate the calendar grid for the selected month
    List<List<int?>> monthCalendar = _generateMonthCalendar(
      firstDayOfWeek,
      daysInMonth,
    );

    // Calculate the maximum number of weeks needed for this month
    int maxWeeks = 0;
    for (var dayRow in monthCalendar) {
      for (int i = 0; i < dayRow.length; i++) {
        if (dayRow[i] != null && i > maxWeeks) {
          maxWeeks = i;
        }
      }
    }
    maxWeeks++; // Add 1 because weeks are 0-indexed
    maxWeeks = maxWeeks > 6 ? 6 : maxWeeks; // Allow up to 6 weeks

    return GestureDetector(
      onTap: () {
        // Clear any selected cell when tapping on empty area
        setState(() {
          _tooltipDate = null;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(7, (rowIndex) {
          return Flexible(
            child: Row(
              children: List.generate(maxWeeks, (colIndex) {
                final day =
                    rowIndex < monthCalendar.length &&
                        colIndex < monthCalendar[rowIndex].length
                    ? monthCalendar[rowIndex][colIndex]
                    : null;
                return _buildCell(day, calendarDate);
              }),
            ),
          );
        }),
      ),
    );
  }

  // Generate a calendar grid for a month
  List<List<int?>> _generateMonthCalendar(int firstDayOfWeek, int daysInMonth) {
    // Create a grid for the days - each row is a day of week (Sunday to Saturday)
    // Each column is a week (up to 6 weeks)
    List<List<int?>> calendar = List.generate(7, (_) => List.filled(6, null));

    int day = 1;
    int weekIndex = 0;

    // Fill in days before the 1st of the month with null
    for (int dayOfWeek = 0; dayOfWeek < firstDayOfWeek; dayOfWeek++) {
      calendar[dayOfWeek][weekIndex] = null;
    }

    // Start filling from the first day of the month
    int dayOfWeek = firstDayOfWeek;

    // Fill in all days of the month
    while (day <= daysInMonth) {
      calendar[dayOfWeek][weekIndex] = day;
      day++;

      // Move to the next day of the week
      dayOfWeek = (dayOfWeek + 1) % 7;

      // If we've reached Sunday (0), move to the next week
      if (dayOfWeek == 0 && day <= daysInMonth) {
        weekIndex++;
      }
    }

    return calendar;
  }

  Widget _buildCell(int? day, DateTime calendarDate) {
    // If day is null, this cell is not part of the month
    if (day == null) {
      return SizedBox(width: 14, height: 14);
    }

    // Create a date for this cell
    final DateTime cellDate = DateTime(
      calendarDate.year,
      calendarDate.month,
      day,
    );

    // Check if this is today's date
    final DateTime today = DateTime.now();
    final bool isToday =
        cellDate.year == today.year &&
        cellDate.month == today.month &&
        cellDate.day == today.day;

    // Check if this is the selected date
    final bool isSelected =
        _tooltipDate != null &&
        _tooltipDate!.year == cellDate.year &&
        _tooltipDate!.month == cellDate.month &&
        _tooltipDate!.day == cellDate.day;

    // Check if there's activity data for this date
    final bool hasActivity = widget.submissionsData.containsKey(cellDate);
    int count = 0;
    int activityLevel = 0;

    if (hasActivity) {
      // Get the submission count for this date
      count = widget.submissionsData[cellDate] ?? 0;

      // Convert the count to an activity level (1-4)
      if (count > 0) {
        if (count <= 2) {
          activityLevel = 1; // Low activity
        } else if (count <= 5) {
          activityLevel = 2; // Medium activity
        } else if (count <= 10) {
          activityLevel = 3; // High activity
        } else {
          activityLevel = 4; // Very high activity
        }
      }
    }

    Color cellColor = _getLegendColor(activityLevel);

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        if (hasActivity && count > 0) {
          // Get the position of the tap relative to the screen
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final Offset globalPosition = renderBox.localToGlobal(
            details.localPosition,
          );

          _showTooltipPopup(cellDate, count, globalPosition);
          setState(() {
            _tooltipDate = cellDate;
          });
        }
      },
      child: Container(
        width: 12, // Reasonable cell size
        height: 12, // Same size for width and height
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(2),
          border: isToday ? Border.all(color: Colors.white, width: 1) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _buildLegendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Less', style: TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(width: 4),
        ...List.generate(5, (index) {
          return Container(
            width: 12, // Match cell size
            height: 12, // Match cell size
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _getLegendColor(index),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 4),
        const Text('More', style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Color _getLegendColor(int index) {
    switch (index) {
      case 0:
        return const Color(
          0xFF2D2D2D,
        ); // Empty cell - darker gray to match reference
      case 1:
        return const Color(0xFF4CAF50).withOpacity(0.3); // Low activity
      case 2:
        return const Color(0xFF4CAF50).withOpacity(0.5); // Medium activity
      case 3:
        return const Color(0xFF4CAF50).withOpacity(0.7); // High activity
      case 4:
        return const Color(0xFF4CAF50); // Very high activity
      default:
        return const Color(0xFF2D2D2D);
    }
  }
}

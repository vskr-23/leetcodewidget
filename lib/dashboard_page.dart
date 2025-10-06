import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'dart:convert'; // Add this import for jsonDecode
import 'widgets/profile_card.dart';
import 'widgets/stat_cards.dart';
import 'widgets/contest_stats.dart';
import 'widgets/badges_section.dart';
import 'widgets/submissions_graph.dart';
import 'widgets/problem_of_the_day.dart';
import 'widgets/upcoming_contest.dart';
import 'widgets/recent_submissions.dart';
import 'main.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final void Function() onSignOut;
  const DashboardPage({
    required this.username,
    required this.onSignOut,
    super.key,
  });
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final String query = '''
    query getUserProfile(
      \$username: String!
    ) {
      matchedUser(username: \$username) {
        username
        profile {
          realName
          userAvatar
          countryName
          ranking
        }
        submitStats {
          acSubmissionNum { difficulty count }
        }
        badges { name icon }
        userCalendar { 
          submissionCalendar
          activeYears
          streak
          totalActiveDays
        }
      }
      recentSubmissions: recentAcSubmissionList(username: \$username, limit: 15) {
        id
        title
        titleSlug
        timestamp
        statusDisplay
        lang
      }
      streakCounter {
        streakCount
        daysSkipped
        currentDayCompleted
      }
      allQuestionsCount {
        difficulty
        count
      }
      userContestRanking(username: \$username) {
        attendedContestsCount
        rating
        topPercentage
      }
      activeDailyCodingChallengeQuestion {
        date
        userStatus
        link
        question {
          titleSlug
          title
          difficulty
        }
      }
    }
  ''';

  Future<void> _changeUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('leetcode_username');
    widget.onSignOut();
  }

  Map<String, dynamic> _parseSubmissionCalendar(Map<String, dynamic>? data) {
    if (data == null) return {};

    final calendar =
        data['matchedUser']?['userCalendar']?['submissionCalendar'];
    if (calendar == null || calendar is! String || calendar.isEmpty) {
      return {};
    }

    try {
      if (calendar.startsWith('{') && calendar.endsWith('}')) {
        return Map<String, dynamic>.from(jsonDecode(calendar));
      }
    } catch (e) {
      debugPrint('Error parsing submission calendar: $e');
    }

    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LeetCode Dashboard'),
        actions: [
          // Refresh button will be added within the Query builder
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _changeUsername,
            tooltip: 'Change Username',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Query(
          options: QueryOptions(
            document: gql(query),
            variables: {'username': widget.username},
          ),
          builder: (result, {fetchMore, refetch}) {
            if (result.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (result.hasException) {
              return Center(
                child: Text(
                  'Error: \n${result.exception.toString()}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            // Extract problem of the day
            final daily = result.data?['activeDailyCodingChallengeQuestion'];
            final problemTitle =
                daily?['question']?['title'] ?? 'Problem of the Day';
            final difficulty = daily?['question']?['difficulty'] ?? '';
            final userStatus = daily?['userStatus'] ?? '';
            final questionStatus = daily?['question']?['status'] ?? '';

            final profile = LeetCodeProfile.fromGraphQL(result.data ?? {});

            // Check for all possible status values
            bool solved = false;

            // First check standard status values
            solved =
                userStatus == 'Finish' ||
                userStatus == 'ac' ||
                userStatus == 'AC' ||
                userStatus == 'Solved' ||
                userStatus == 'Finished' ||
                userStatus == 'DONE' ||
                questionStatus == 'ac' ||
                questionStatus == 'AC';

            // If still not solved, check recent submissions to see if daily challenge is completed
            if (!solved && daily != null) {
              final dailyTitleSlug = daily['question']?['titleSlug'];
              final recentSubmissions = result.data?['recentSubmissions'];

              if (dailyTitleSlug != null && recentSubmissions != null) {
                // Check if any recent submission matches the daily challenge
                for (var submission in recentSubmissions) {
                  if (submission['titleSlug'] == dailyTitleSlug &&
                      (submission['statusDisplay'] == 'Accepted' ||
                          submission['statusDisplay'] == 'Success')) {
                    solved = true;
                    break;
                  }
                }
              }

              // Get today's date in Unix timestamp (seconds)
              final now = DateTime.now();
              final todayUnix =
                  DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).millisecondsSinceEpoch ~/
                  1000;
              final todayStr = todayUnix.toString();

              // Check if there are submissions today
              final calendar = result
                  .data?['matchedUser']?['userCalendar']?['submissionCalendar'];

              if (calendar != null &&
                  calendar is String &&
                  calendar.isNotEmpty) {
                try {
                  final Map<String, dynamic>
                  calendarData = Map<String, dynamic>.from(
                    (calendar.startsWith('{') && calendar.endsWith('}'))
                        ? Map<String, dynamic>.from(
                            Map.castFrom<String, dynamic, String, dynamic>(
                              Map<String, dynamic>.from(
                                Map.castFrom<String, dynamic, String, dynamic>(
                                  jsonDecode(calendar),
                                ),
                              ),
                            ),
                          )
                        : {},
                  );

                  if (calendarData.containsKey(todayStr) &&
                      calendarData[todayStr] > 0) {
                    solved = true;
                  }
                } catch (e) {
                  // Error parsing submission calendar
                }
              }

              // Also check if the user's totalSubmissionNum for the day is > 0
              final streakCounter = result.data?['streakCounter'];
              if (streakCounter != null &&
                  streakCounter['currentDayCompleted'] == true) {
                solved = true;
              }
            }

            // Main dashboard content
            return ListView(
              children: [
                ProfileCard(profile: profile),
                const SizedBox(height: 16),
                StatCards(profile: profile),
                const SizedBox(height: 16),
                BadgesSection(profile: profile),
                const SizedBox(height: 16),
                SubmissionsGraph(
                  submissionCalendar: _parseSubmissionCalendar(result.data),
                  // Use the API values for streak and active days if available
                  totalActiveDays:
                      result
                          .data?['matchedUser']?['userCalendar']?['totalActiveDays'] ??
                      _parseSubmissionCalendar(result.data).length,
                  maxStreak:
                      result.data?['matchedUser']?['userCalendar']?['streak'] ??
                      result.data?['streakCounter']?['streakCount'] ??
                      0,
                ),
                const SizedBox(height: 16),
                ProblemOfTheDay(
                  problemTitle: problemTitle,
                  solved: solved,
                  difficulty: difficulty,
                  problemLink: daily?['link'],
                ),
                const SizedBox(height: 16),
                // Only show recent submissions if available
                if (result.data?['recentSubmissions'] != null &&
                    (result.data?['recentSubmissions'] as List).isNotEmpty)
                  RecentSubmissions(
                    submissions: result.data?['recentSubmissions'],
                  ),
                if (result.data?['recentSubmissions'] != null)
                  const SizedBox(height: 16),
                ContestStats(profile: profile),
                const SizedBox(height: 16),
                const UpcomingContests(),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:device_preview/device_preview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'landing_page.dart';
import 'dashboard_page.dart';
import 'services/notification_service.dart';

// Minimal profile model for only the requested fields
class LeetCodeProfile {
  final String username;
  final String realName;
  final String avatarUrl;
  final String countryName;
  final int problemsSolved;
  final int easySolved;
  final int mediumSolved;
  final int hardSolved;
  final int easyTotal;
  final int mediumTotal;
  final int hardTotal;
  final List<dynamic> badges;
  final Map<String, dynamic>? activeBadge;
  final String submissionCalendar;
  final double contestRating;
  final int globalRanking;
  final int attendedContestsCount;
  final double topPercentage;

  LeetCodeProfile({
    required this.username,
    required this.realName,
    required this.avatarUrl,
    required this.countryName,
    required this.problemsSolved,
    required this.easySolved,
    required this.mediumSolved,
    required this.hardSolved,
    required this.easyTotal,
    required this.mediumTotal,
    required this.hardTotal,
    required this.badges,
    this.activeBadge,
    required this.submissionCalendar,
    required this.contestRating,
    required this.globalRanking,
    required this.attendedContestsCount,
    required this.topPercentage,
  });

  factory LeetCodeProfile.fromGraphQL(Map<String, dynamic> data) {
    final matchedUser = data['matchedUser'] ?? {};
    final profile = matchedUser['profile'] ?? {};
    final submitStats = matchedUser['submitStats'] ?? {};
    final acSubmissionNum = submitStats['acSubmissionNum'] ?? [];
    final allQuestionsCount = data['allQuestionsCount'] ?? [];
    final badges = matchedUser['badges'] ?? [];
    final activeBadge = matchedUser['activeBadge'];
    final userCalendar = matchedUser['userCalendar'] ?? {};
    final submissionCalendar = userCalendar['submissionCalendar'] ?? '';
    final contestData = data['userContestRanking'] ?? {};
    int problemsSolved = 0, easySolved = 0, mediumSolved = 0, hardSolved = 0;
    int easyTotal = 0, mediumTotal = 0, hardTotal = 0;
    for (var item in acSubmissionNum) {
      final diff = (item['difficulty'] ?? '').toString().toLowerCase();
      if (diff == 'all') problemsSolved = item['count'] ?? 0;
      if (diff == 'easy') easySolved = item['count'] ?? 0;
      if (diff == 'medium') mediumSolved = item['count'] ?? 0;
      if (diff == 'hard') hardSolved = item['count'] ?? 0;
    }
    for (var item in allQuestionsCount) {
      final diff = (item['difficulty'] ?? '').toString().toLowerCase();
      if (diff == 'easy') easyTotal = item['count'] ?? 0;
      if (diff == 'medium') mediumTotal = item['count'] ?? 0;
      if (diff == 'hard') hardTotal = item['count'] ?? 0;
    }
    return LeetCodeProfile(
      username: matchedUser['username'] ?? '',
      realName: profile['realName'] ?? '',
      avatarUrl: profile['userAvatar'] ?? '',
      countryName: profile['countryName'] ?? '',
      problemsSolved: problemsSolved,
      easySolved: easySolved,
      mediumSolved: mediumSolved,
      hardSolved: hardSolved,
      easyTotal: easyTotal,
      mediumTotal: mediumTotal,
      hardTotal: hardTotal,
      badges: badges,
      activeBadge: activeBadge,
      submissionCalendar: submissionCalendar,
      contestRating: (contestData['rating'] ?? 0).toDouble(),
      globalRanking: profile['ranking'] ?? 0, // changed
      attendedContestsCount: contestData['attendedContestsCount'] ?? 0,
      topPercentage: (contestData['topPercentage'] ?? 0).toDouble(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter();

  // Initialize notification service
  await NotificationService().initialize();

  runApp(DevicePreview(enabled: true, builder: (context) => MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final HttpLink httpLink = HttpLink('https://leetcode.com/graphql');
    ValueNotifier<GraphQLClient> client = ValueNotifier(
      GraphQLClient(
        link: httpLink,
        cache: GraphQLCache(store: HiveStore()),
      ),
    );
    return GraphQLProvider(
      client: client,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: DevicePreview.appBuilder,
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        title: 'LeetCode Dashboard',
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          cardColor: const Color(0xFF22232B),
          scaffoldBackgroundColor: const Color(0xFF181920),
        ),
        home: _RootNavigator(),
      ),
    );
  }
}

class _RootNavigator extends StatefulWidget {
  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('leetcode_username');
    });
  }

  void _onUsernameEntered(String username) {
    setState(() {
      _username = username;
    });
  }

  void _onSignOut() {
    setState(() {
      _username = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_username == null || _username!.isEmpty) {
      return LandingPage(onUsernameEntered: _onUsernameEntered);
    } else {
      return DashboardPage(username: _username!, onSignOut: _onSignOut);
    }
  }
}

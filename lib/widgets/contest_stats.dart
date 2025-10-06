import 'package:flutter/material.dart';
import '../main.dart';

class ContestStats extends StatelessWidget {
  final LeetCodeProfile profile;
  const ContestStats({required this.profile, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text('Rating', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                Text(
                  profile.contestRating.toStringAsFixed(2),
                  style: const TextStyle(color: Colors.amber),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.leaderboard, color: Colors.cyan),
                const SizedBox(width: 8),
                Text(
                  'Global Rank',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  profile.globalRanking.toString(),
                  style: const TextStyle(color: Colors.cyan),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.percent, color: Colors.purpleAccent),
                const SizedBox(width: 8),
                Text('Top', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                Text(
                  '${profile.topPercentage.toStringAsFixed(2)}%',
                  style: const TextStyle(color: Colors.purpleAccent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event_available, color: Colors.greenAccent),
                const SizedBox(width: 8),
                Text('Attended', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                Text(
                  profile.attendedContestsCount.toString(),
                  style: const TextStyle(color: Colors.greenAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

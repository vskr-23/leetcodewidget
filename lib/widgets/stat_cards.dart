import 'package:flutter/material.dart';
import '../main.dart';

class StatCards extends StatelessWidget {
  final LeetCodeProfile profile;
  const StatCards({required this.profile, super.key});

  Widget _statCard(String label, int value, Color color, int total) {
    return SizedBox(
      width: 90,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: Colors.white70)),
              if (label != 'Total')
                LinearProgressIndicator(
                  value: total > 0 ? value / total : 0,
                  color: color,
                  backgroundColor: Colors.white12,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statCard(
            'Easy',
            profile.easySolved,
            Colors.green,
            profile.easyTotal,
          ),
          const SizedBox(width: 8),
          _statCard(
            'Medium',
            profile.mediumSolved,
            Colors.orange,
            profile.mediumTotal,
          ),
          const SizedBox(width: 8),
          _statCard('Hard', profile.hardSolved, Colors.red, profile.hardTotal),
          const SizedBox(width: 8),
          _statCard(
            'Total',
            profile.problemsSolved,
            Colors.purple,
            profile.easyTotal + profile.mediumTotal + profile.hardTotal,
          ),
        ],
      ),
    );
  }
}

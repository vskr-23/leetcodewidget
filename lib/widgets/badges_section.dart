import 'package:flutter/material.dart';
import 'dart:ui';
import '../main.dart';

class BadgesSection extends StatelessWidget {
  final LeetCodeProfile profile;
  const BadgesSection({required this.profile, super.key});

  @override
  Widget build(BuildContext context) {
    final badges = profile.badges;
    // Debug print to inspect badge data
    print('Badges data:');
    for (final badge in badges) {
      print(badge);
    }
    final Map<String, dynamic>? activeBadge = profile.activeBadge;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Badges',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final badge in badges)
                  GestureDetector(
                    onTap: () {
                      if (badge['icon'] != null) {
                        final isActive =
                            activeBadge != null &&
                            badge['icon'] == activeBadge['icon'];
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withOpacity(0.5),
                          builder: (context) => Stack(
                            children: [
                              BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  color: Colors.black.withOpacity(0),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.network(
                                      badge['icon'],
                                      width: 120,
                                      height: 120,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      isActive
                                          ? (activeBadge['displayName'] ?? '')
                                          : (badge['name'] ?? ''),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: badge['icon'] != null
                          ? Image.network(badge['icon'], width: 40, height: 40)
                          : const SizedBox(width: 40, height: 40),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

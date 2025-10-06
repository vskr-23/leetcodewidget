import 'package:flutter/material.dart';
import '../main.dart';

class ProfileCard extends StatelessWidget {
  final LeetCodeProfile profile;
  const ProfileCard({required this.profile, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: profile.avatarUrl.isNotEmpty
                  ? NetworkImage(profile.avatarUrl)
                  : null,
              child: profile.avatarUrl.isEmpty
                  ? const Icon(Icons.person, size: 32)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.realName.isNotEmpty
                        ? profile.realName
                        : profile.username,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${profile.username}',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile.countryName.isNotEmpty)
                    Text(
                      profile.countryName,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  // streakWidget removed
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

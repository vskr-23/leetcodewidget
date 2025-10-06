import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingPage extends StatefulWidget {
  final void Function(String username) onUsernameEntered;
  const LandingPage({required this.onUsernameEntered, super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('leetcode_username', username);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to LeetCode Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter your LeetCode username to continue:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'LeetCode Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final username = _controller.text.trim();
                if (username.isNotEmpty) {
                  await _saveUsername(username);
                  widget.onUsernameEntered(username);
                }
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

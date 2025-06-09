import 'package:flutter/material.dart';
import 'user_session.dart';

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> userProfile;

  const ProfilePage({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    final name = userProfile['name'] ?? 'N/A';
    final email = userProfile['email'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                UserSession.username = '';
                UserSession.role = '';
                Navigator.pushReplacementNamed(context, '/login');
              },
            )
          ],
        ),
      ),
    );
  }
}
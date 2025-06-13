import 'package:flutter/material.dart';
import 'medication_order_screen.dart';

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  const ProfilePage({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    final name = userProfile['name'] ?? 'N/A';
    final email = userProfile['email'] ?? 'N/A';
    final gender = userProfile['gender'] ?? 'N/A';
    final phone = userProfile['phone'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(name),
              subtitle: const Text('Name'),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(email),
              subtitle: const Text('Email'),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(phone),
              subtitle: const Text('Phone Number'),
            ),
            ListTile(
              leading: const Icon(Icons.transgender),
              title: Text(gender),
              subtitle: const Text('Gender'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.list_alt),
              label: const Text('View Medication Orders'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicationOrderScreen(
                      patientEmail: email,
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

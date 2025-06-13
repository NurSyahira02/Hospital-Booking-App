import 'package:flutter/material.dart';
import 'book_appointment_page.dart';
import 'appointment_history.dart';
import 'feedback_screen.dart';
import 'order_medication_page.dart';
import 'profile_page.dart';
import 'database_helper.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const HomePage({super.key, required this.userProfile});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _appointments = [];

  Future<void> _loadAppointments() async {
    final email = widget.userProfile['email'] ?? '';
    print('📩 Loading appointments for: $email');

    final db = DatabaseHelper();
    final results = await db.getAppointmentsForPatient(email);
    setState(() => _appointments = results);
  }

  @override
  void initState() {
    super.initState();
    print('🏠 HomePage loaded with userProfile: ${widget.userProfile}');
    _loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userProfile['name'] ?? 'Guest';
    final email = widget.userProfile['email'] ?? 'unknown@example.com';

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $name'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(userProfile: widget.userProfile),
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Upcoming Appointments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _appointments.isEmpty
                ? const Text('No appointments found.')
                : Column(
                    children: _appointments.map((appointment) {
                      final doctor = appointment['doctor'] ?? 'Unknown';
                      final dateTime = appointment['dateTime'] ?? 'Not set';
                      return Card(
                        child: ListTile(
                          title: Text('Dr. $doctor'),
                          subtitle: Text('Date: $dateTime'),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Book Appointment'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BookAppointmentPage(userProfile: widget.userProfile),
                      ),
                    ).then((_) => _loadAppointments());
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('Appointment History'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AppointmentHistoryPage(userProfile: widget.userProfile),
                      ),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.feedback),
                  label: const Text('Feedback'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FeedbackPage(userProfile: widget.userProfile),
                      ),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.medical_services),
                  label: const Text('Order Medication'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderMedicationPage(userProfile: widget.userProfile),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

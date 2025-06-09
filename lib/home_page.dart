import 'package:flutter/material.dart';
import 'book_appointment_page.dart';
import 'order_medication_page.dart';
import 'feedback_screen.dart';
import 'feedback_history.dart';
import 'profile_page.dart';
import 'order.dart';
import 'user_session.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const HomePage({super.key, required this.userProfile});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _pages = [
      _buildDashboard(),
      BookAppointmentPage(userProfile: widget.userProfile),
      OrderMedicationPage(userProfile: widget.userProfile),
      const FeedbackScreen(),
      ProfilePage(userProfile: widget.userProfile),
    ];
  }

  Widget _buildDashboard() {
    final appointment = widget.userProfile['appointmentDateTime'];
    final userName = widget.userProfile['name'] ?? 'User';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text(
            'WELCOME, $userName!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.teal[50],
            child: const ListTile(
              leading: Icon(Icons.health_and_safety, color: Colors.teal),
              title: Text('💡 Tip: Stay hydrated and follow your medication schedule.'),
            ),
          ),
          const SizedBox(height: 12),
          if (appointment != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.indigo),
                title: const Text("Upcoming Appointment"),
                subtitle: Text('$appointment'),
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            onPressed: () {
              UserSession.username = '';
              UserSession.role = '';
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
    );
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Appointment'),
          BottomNavigationBarItem(icon: Icon(Icons.local_pharmacy), label: 'Medication'),
          BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Feedback'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

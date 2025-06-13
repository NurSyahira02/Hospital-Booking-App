import 'package:flutter/material.dart';
import 'database_helper.dart';

class AppointmentHistoryPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const AppointmentHistoryPage({super.key, required this.userProfile});

  @override
  State<AppointmentHistoryPage> createState() => _AppointmentHistoryPageState();
}

class _AppointmentHistoryPageState extends State<AppointmentHistoryPage> {
  List<Map<String, dynamic>> _appointments = [];

  Future<void> _loadAppointments() async {
    final db = DatabaseHelper();
    final results = await db.getAppointmentsForPatient(widget.userProfile['email']);
    setState(() => _appointments = results);
  }

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment History')),
      body: _appointments.isEmpty
          ? const Center(child: Text('No past appointments found.'))
          : ListView.builder(
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appointment = _appointments[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_note),
                    title: Text('Dr. ${appointment['doctor']}'),
                    subtitle: Text('Date: ${appointment['dateTime']}'),
                  ),
                );
              },
            ),
    );
  }
}

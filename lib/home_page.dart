import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'book_appointment_page.dart';
import 'appointment_history.dart';
import 'order_medication_page.dart';
import 'view_medication_orders.dart';
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
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _loadProfileImage();
  }

  Future<void> _loadAppointments() async {
    final email = widget.userProfile['email'] ?? '';
    final db = DatabaseHelper();
    final results = await db.getAppointmentsForPatient(email);
    setState(() => _appointments = results);
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profileImagePath');
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImage = File(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final name = widget.userProfile['name'] ?? loc.guest;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('${loc.welcome}, $name')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: loc.settings,
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: loc.logout,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(loc.confirmLogout),
                  content: Text(loc.logoutConfirmation),
                  actions: [
                    TextButton(
                      child: Text(loc.cancel),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: Text(loc.logoutYes),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: loc.profile,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(userProfile: widget.userProfile),
                ),
              ).then((_) => _loadProfileImage());
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              loc.upcomingAppointments,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _appointments.isEmpty
                ? Text(loc.noAppointments)
                : Column(
                    children: _appointments.map((appointment) {
                      final doctor = appointment['doctor'] ?? loc.unknown;
                      final dateTime = appointment['dateTime'] ?? loc.notSet;
                      return Card(
                        child: ListTile(
                          title: Text('${loc.dr} $doctor'),
                          subtitle: Text('${loc.date}: $dateTime'),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 24),
            Text(
              loc.quickActions,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle),
                  label: Text(loc.bookAppointment),
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
                  label: Text(loc.appointmentHistory),
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
                  icon: const Icon(Icons.medication),
                  label: Text(loc.orderMedication),
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.receipt_long),
                  label: Text(loc.viewMedicationOrders),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewMedicationOrdersPage(userProfile: widget.userProfile),
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

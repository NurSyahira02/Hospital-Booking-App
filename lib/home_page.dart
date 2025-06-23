import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'book_appointment_page.dart';
import 'appointment_history.dart';
import 'order_medication_page.dart';
import 'view_medication_orders.dart';
import 'profile_page.dart';
import 'feedback_screen.dart';
import 'pharmacy_page.dart';
import 'medication_order.dart';
import 'database_helper.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const HomePage({super.key, required this.userProfile});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _appointments = [];
  File? _profileImage;
  Map<String, dynamic>? _latestFeedback;

  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _loadProfileImage();
    _loadLatestFeedback();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    final email = widget.userProfile['email'] ?? '';
    final db = DatabaseHelper();
    final results = await db.getAppointmentsForPatient(email);
    setState(() => _appointments = results);
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final email = widget.userProfile['email'];
    final path = prefs.getString('profileImagePath_$email');
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImage = File(path));
    }
  }

  Future<void> _loadLatestFeedback() async {
    final email = widget.userProfile['email'] ?? '';
    final db = DatabaseHelper();
    final result = await db.getLatestFeedbackForUser(email);
    setState(() {
      _latestFeedback = result;
    });
  }

  void _showImprovementFeedbackPrompt() {
    final loc = AppLocalizations.of(context)!;
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(loc.feedback),
            content: TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any suggestions before you go?',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (_) => false,
                  );
                },
                child: Text(loc.skip),
              ),
              TextButton(
                onPressed: () async {
                  final feedback = feedbackController.text.trim();
                  if (feedback.isNotEmpty) {
                    await DatabaseHelper().insertImprovement({
                      'email': widget.userProfile['email'],
                      'message': feedback,
                      'timestamp': DateTime.now().toIso8601String(),
                    });
                  }
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (_) => false,
                  );
                },
                child: Text(loc.submit),
              ),
            ],
          ),
    );
  }

  Future<void> _openPharmacyPage() async {
    final orders = await DatabaseHelper().getAllMedicationOrders();
    final converted = orders.map((e) => MedicationOrder.fromMap(e)).toList();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PharmacyPage(
              medicationOrders: converted,
              currentPatientEmail: widget.userProfile['email'],
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final name = widget.userProfile['name'] ?? loc.guest;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  _profileImage != null
                      ? FileImage(_profileImage!)
                      : const AssetImage('assets/default_avatar.png')
                          as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('${loc.welcome}, $name')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: loc.profile,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ProfilePage(userProfile: widget.userProfile),
                ),
              ).then((_) => _loadProfileImage());
            },
          ),
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
                builder:
                    (context) => AlertDialog(
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
                            _showImprovementFeedbackPrompt();
                          },
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/hospital_cartoon.png',
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '🏥 Welcome to Hospital Booking App',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Text(
              loc.upcomingAppointments,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _appointments.isEmpty
                ? Text(loc.noAppointments)
                : Column(
                  children:
                      _appointments.map((appointment) {
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
                        builder:
                            (context) => BookAppointmentPage(
                              userProfile: widget.userProfile,
                            ),
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
                        builder:
                            (context) => AppointmentHistoryPage(
                              userProfile: widget.userProfile,
                            ),
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
                        builder:
                            (context) => OrderMedicationPage(
                              userProfile: widget.userProfile,
                            ),
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
                        builder:
                            (context) => ViewMedicationOrdersPage(
                              userProfile: widget.userProfile,
                            ),
                      ),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.local_pharmacy),
                  label: const Text("Pharmacy"),
                  onPressed: _openPharmacyPage,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.feedback),
                  label: Text(loc.feedback),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                FeedbackPage(userProfile: widget.userProfile),
                      ),
                    );
                    if (result == true) {
                      _loadLatestFeedback(); // Reload feedback
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_latestFeedback != null) ...[
              Text(
                loc.yourLatestFeedback,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: isDark ? Colors.grey[900] : Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            '${loc.rating}: ${_latestFeedback!['rating']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color:
                                  isDark
                                      ? Colors.tealAccent[100]
                                      : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${loc.comment}: ${_latestFeedback!['comment'] ?? loc.noComment}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

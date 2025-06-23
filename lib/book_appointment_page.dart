import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'notification_service.dart';
import 'home_page.dart';

class BookAppointmentPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const BookAppointmentPage({super.key, required this.userProfile});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _profileImage;

  final Map<String, String> _appointmentTypes = {
    'Cardiology (heart diseases)': 'Dr. John',
    'Orthopedic (bone & joint issues)': 'Dr. Smith',
    'General (common illness)': 'Dr. Emma',
  };

  String? _selectedType;
  String? _selectedDoctor;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final email = widget.userProfile['email'];
    final path = prefs.getString('profileImagePath_$email');
    if (path != null && File(path).existsSync()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _profileImage = File(path));
      });
    }
  }

  Future<void> _bookAppointment() async {
    final loc = AppLocalizations.of(context)!;

    if (_selectedDate != null &&
        _selectedTime != null &&
        _selectedType != null) {
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final appointmentData = {
        'patient_email': widget.userProfile['email'],
        'doctor': _selectedDoctor,
        'dateTime': appointmentDateTime.toIso8601String(),
        'reason': _selectedType,
      };

      await DatabaseHelper().insertAppointment(appointmentData);

      await NotificationService.scheduleAppointmentReminders(
        doctorName: _selectedDoctor!,
        appointmentDateTime: appointmentDateTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.appointmentBooked)));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(userProfile: widget.userProfile),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.pleaseCompleteAllFields)));
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
              backgroundImage:
                  _profileImage != null
                      ? FileImage(_profileImage!)
                      : const AssetImage('assets/default_avatar.png')
                          as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('${loc.bookAppointment}, $name')),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              isDense: true,
              decoration: InputDecoration(labelText: loc.appointmentType),
              items:
                  _appointmentTypes.entries.map((entry) {
                    final typeLabel = entry.key.split(' (')[0];
                    final description =
                        entry.key.contains('(')
                            ? entry.key.split('(')[1].replaceAll(')', '')
                            : '';

                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$typeLabel\n',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (description.isNotEmpty)
                              TextSpan(
                                text: description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedType = val;
                  _selectedDoctor = _appointmentTypes[val!];
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedDoctor != null)
              Text(
                '${loc.assignedDoctor}: $_selectedDoctor',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                _selectedDate == null
                    ? loc.selectDate
                    : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            ListTile(
              title: Text(
                _selectedTime == null
                    ? loc.selectTime
                    : _selectedTime!.format(context),
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) setState(() => _selectedTime = picked);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _bookAppointment,
              child: Text(loc.bookAppointment),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'notification_service.dart'; // ✅ Make sure this file exists

class BookAppointmentPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const BookAppointmentPage({super.key, required this.userProfile});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final List<String> _doctors = ['Dr. John', 'Dr. Smith', 'Dr. Emma'];
  String? _selectedDoctor;
  final TextEditingController _reasonController = TextEditingController();

  Future<void> _bookAppointment() async {
    if (_selectedDate != null && _selectedTime != null && _selectedDoctor != null) {
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
        'reason': _reasonController.text.trim(),
      };

      await DatabaseHelper().insertAppointment(appointmentData);

      // ✅ Schedule Notification
      await NotificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Appointment Reminder',
        body: 'You have an appointment with $_selectedDoctor',
        dateTime: appointmentDateTime.subtract(const Duration(hours: 1)),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked')),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedDoctor,
              decoration: const InputDecoration(labelText: 'Select Doctor'),
              items: _doctors.map((doctor) {
                return DropdownMenuItem(
                  value: doctor,
                  child: Text(doctor),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedDoctor = value),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_selectedDate == null
                  ? 'Select Date'
                  : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            ListTile(
              title: Text(_selectedTime == null
                  ? 'Select Time'
                  : _selectedTime!.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() => _selectedTime = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Appointment',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _bookAppointment,
              child: const Text('Book Appointment'),
            ),
          ],
        ),
      ),
    );
  }
}

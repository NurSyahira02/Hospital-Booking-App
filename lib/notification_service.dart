import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class NotificationService {
  static Future<bool> _notificationsAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notificationsEnabled') ?? true;
  }

  static Future<void> scheduleAppointmentReminders({
    required String doctorName,
    required DateTime appointmentDateTime,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (!await _notificationsAllowed()) return;

    final idBase = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (appointmentDateTime.difference(DateTime.now()).inHours >= 25) {
      await _schedule(
        id: idBase,
        title: 'Appointment Reminder',
        body: 'Your appointment with $doctorName is tomorrow.',
        dateTime: appointmentDateTime.subtract(const Duration(days: 1)),
      );
    }

    await _schedule(
      id: idBase + 1,
      title: 'Appointment Reminder',
      body: 'You have an appointment with $doctorName in 1 hour.',
      dateTime: appointmentDateTime.subtract(const Duration(hours: 1)),
    );
  }

  static Future<void> schedulePickupReminder({
    required List<String> medications,
    required String location,
    required DateTime pickupDateTime,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (!await _notificationsAllowed()) return;

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _schedule(
      id: id,
      title: 'Medication Pickup Reminder',
      body: 'Pick up your medications: ${medications.join(', ')} at $location',
      dateTime: pickupDateTime.subtract(const Duration(hours: 1)),
    );
  }

  /// ✅ NEW: Manual reminder sent immediately or with short delay
  static Future<void> sendManualReminder({
    required List<String> medications,
    required String location,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (!await _notificationsAllowed()) return;

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _schedule(
      id: id,
      title: 'Medication Pickup Reminder',
      body: 'Pick up your medications: ${medications.join(', ')} at $location',
      dateTime: DateTime.now().add(const Duration(seconds: 5)),
    );
  }

  /// ✅ NEW: Courier delivery reminder
  static Future<void> scheduleCourierReminder({
    required List<String> medications,
    required String address,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (!await _notificationsAllowed()) return;

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _schedule(
      id: id,
      title: 'Courier Delivery Scheduled',
      body: 'Your medications (${medications.join(', ')}) will be delivered to: $address',
      dateTime: DateTime.now().add(const Duration(seconds: 5)),
    );
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hospital_app_channel',
          'Hospital Notifications',
          channelDescription: 'Reminders for appointments and pickups',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

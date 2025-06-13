import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'database_helper.dart';
import 'medication_order.dart';
import 'notification_service.dart'; // ✅ Notification logic

class OrderMedicationPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const OrderMedicationPage({super.key, required this.userProfile});

  @override
  State<OrderMedicationPage> createState() => _OrderMedicationPageState();
}

class _OrderMedicationPageState extends State<OrderMedicationPage> {
  final List<String> _medications = ['Paracetamol', 'Cough Syrup', 'Antibiotic'];
  final Map<String, Map<String, String>> _medicationDetails = {
    'Paracetamol': {
      'mg': '500mg',
      'adult': '1 tablet every 6 hours',
      'child': 'Half tablet every 6 hours',
    },
    'Cough Syrup': {
      'mg': '5ml',
      'adult': '10ml every 8 hours',
      'child': '5ml every 8 hours',
    },
    'Antibiotic': {
      'mg': '250mg',
      'adult': '1 capsule every 8 hours',
      'child': 'Ask doctor',
    },
  };

  final List<String> _pickupLocations = ['Pharmacy Counter A', 'Pharmacy Counter B', 'Drive-Thru A'];
  String? _selectedMedication;
  int _quantity = 1;
  bool _isChild = false;
  String _deliveryMethod = 'Pickup';
  final TextEditingController _addressController = TextEditingController();
  String _pickupLocation = 'Pharmacy Counter A';
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;

  Future<void> _submitOrder() async {
    if (_selectedMedication == null || _quantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select medication and quantity')),
      );
      return;
    }

    if (_deliveryMethod == 'Courier' && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a delivery address')),
      );
      return;
    }

    if (_pickupDate == null || _pickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup date and time')),
      );
      return;
    }

    final pickupDateTime = DateTime(
      _pickupDate!.year,
      _pickupDate!.month,
      _pickupDate!.day,
      _pickupTime!.hour,
      _pickupTime!.minute,
    );

    final order = MedicationOrder(
      id: const Uuid().v4(),
      patientName: widget.userProfile['name'],
      patientEmail: widget.userProfile['email'],
      medications: [_selectedMedication!],
      quantity: _quantity,
      isChild: _isChild,
      deliveryMethod: _deliveryMethod,
      address: _deliveryMethod == 'Courier' ? _addressController.text.trim() : '',
      pickupLocation: _pickupLocation,
      pickupDateTime: pickupDateTime,
      status: OrderStatus.pending,
    );

    await DatabaseHelper().insertMedicationOrder(order.toMap());

    // ✅ Schedule pickup reminder
    await NotificationService.scheduleNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Medication Pickup Reminder',
      body: 'Pick up your medication: $_selectedMedication at $_pickupLocation',
      dateTime: pickupDateTime.subtract(const Duration(hours: 1)),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDetails = _selectedMedication != null ? _medicationDetails[_selectedMedication!] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Medication')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('Is this for a child?'),
              value: _isChild,
              onChanged: (val) => setState(() => _isChild = val),
            ),
            DropdownButtonFormField<String>(
              value: _selectedMedication,
              items: _medications
                  .map((med) => DropdownMenuItem(value: med, child: Text(med)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Select Medication'),
              onChanged: (val) => setState(() => _selectedMedication = val),
            ),
            if (selectedDetails != null) ...[
              const SizedBox(height: 12),
              Text('Dosage: ${selectedDetails[_isChild ? 'child' : 'adult']}'),
              Text('Strength: ${selectedDetails['mg']}'),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Quantity:'),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: _quantity,
                  items: List.generate(10, (i) => i + 1)
                      .map((num) => DropdownMenuItem(value: num, child: Text('$num')))
                      .toList(),
                  onChanged: (val) => setState(() => _quantity = val!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _deliveryMethod,
              decoration: const InputDecoration(labelText: 'Delivery Method'),
              items: const [
                DropdownMenuItem(value: 'Pickup', child: Text('Pickup at Hospital')),
                DropdownMenuItem(value: 'Courier', child: Text('Courier Delivery')),
              ],
              onChanged: (val) => setState(() => _deliveryMethod = val!),
            ),
            if (_deliveryMethod == 'Courier') ...[
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Delivery Address'),
              ),
            ] else ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _pickupLocation,
                decoration: const InputDecoration(labelText: 'Pickup Location'),
                items: _pickupLocations.map((loc) {
                  return DropdownMenuItem(value: loc, child: Text(loc));
                }).toList(),
                onChanged: (val) => setState(() => _pickupLocation = val!),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  _pickupDate == null
                      ? 'Select Pickup Date'
                      : '${_pickupDate!.year}-${_pickupDate!.month.toString().padLeft(2, '0')}-${_pickupDate!.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _pickupDate = picked);
                  }
                },
              ),
              ListTile(
                title: Text(
                  _pickupTime == null
                      ? 'Select Pickup Time'
                      : _pickupTime!.format(context),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() => _pickupTime = picked);
                  }
                },
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitOrder,
              child: const Text('Submit Order'),
            )
          ],
        ),
      ),
    );
  }
}

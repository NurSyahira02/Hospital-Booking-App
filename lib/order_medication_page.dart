import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'database_helper.dart';
import 'medication_order.dart';
import 'notification_service.dart';

class OrderMedicationPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const OrderMedicationPage({super.key, required this.userProfile});

  @override
  State<OrderMedicationPage> createState() => _OrderMedicationPageState();
}

class _OrderMedicationPageState extends State<OrderMedicationPage> {
  final Map<String, List<Map<String, String>>> _diseaseMedications = {
    'Cardiology': [
      {
        'name': 'Atenolol',
        'mg': '50mg',
        'adult': 'Once daily',
        'child': 'Consult doctor',
      },
      {
        'name': 'Losartan',
        'mg': '25mg',
        'adult': 'Once daily',
        'child': 'Consult doctor',
      },
      {
        'name': 'Aspirin',
        'mg': '100mg',
        'adult': 'Once daily',
        'child': 'Avoid unless prescribed',
      },
    ],
    'Orthopedic': [
      {
        'name': 'Ibuprofen',
        'mg': '400mg',
        'adult': 'Every 8 hours',
        'child': 'Half tablet every 8 hours',
      },
      {
        'name': 'Calcium Carbonate',
        'mg': '500mg',
        'adult': 'Once daily',
        'child': 'Half tablet daily',
      },
      {
        'name': 'Paracetamol',
        'mg': '500mg',
        'adult': 'Every 6 hours',
        'child': 'Half tablet every 6 hours',
      },
    ],
    'General': [
      {
        'name': 'Cough Syrup',
        'mg': '5ml',
        'adult': '10ml every 8 hours',
        'child': '5ml every 8 hours',
      },
      {
        'name': 'Antibiotic',
        'mg': '250mg',
        'adult': '1 capsule every 8 hours',
        'child': 'Consult doctor',
      },
      {
        'name': 'Vitamin C',
        'mg': '500mg',
        'adult': 'Once daily',
        'child': 'Half tablet daily',
      },
    ],
  };

  String? _selectedDisease;
  final Map<String, int> _medicationQuantities = {};
  final List<String> _selectedMedications = [];
  final TextEditingController _otherMedicationController =
      TextEditingController();
  final Map<String, int> _customQuantities = {};
  bool _isChild = false;
  String _deliveryMethod = 'Pickup';
  final TextEditingController _addressController = TextEditingController();
  String _pickupLocation = 'Pharmacy Counter A';
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  File? _profileImage;

  final List<String> _pickupLocations = [
    'Pharmacy Counter A',
    'Pharmacy Counter B',
    'Drive-Thru A',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('loggedInEmail');
    final path = prefs.getString('profileImagePath_$email');
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImage = File(path));
    }
  }

  Future<void> _submitOrder() async {
    final loc = AppLocalizations.of(context)!;

    if (_selectedMedications.isEmpty ||
        (_deliveryMethod == 'Courier' &&
            _addressController.text.trim().isEmpty) ||
        (_deliveryMethod == 'Pickup' &&
            (_pickupDate == null || _pickupTime == null))) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.pleaseCompleteAllFields)));
      return;
    }

    final meds =
        _selectedMedications.map((name) {
          final qty =
              _medicationQuantities[name] ?? _customQuantities[name] ?? 1;
          return '$name (x$qty)';
        }).toList();

    final pickupDateTime =
        _deliveryMethod == 'Pickup'
            ? DateTime(
              _pickupDate!.year,
              _pickupDate!.month,
              _pickupDate!.day,
              _pickupTime!.hour,
              _pickupTime!.minute,
            )
            : DateTime.now().add(const Duration(minutes: 2));

    final order = MedicationOrder(
      id: const Uuid().v4(),
      patientName: widget.userProfile['name'],
      patientEmail: widget.userProfile['email'],
      medications: meds,
      quantity: meds.length,
      isChild: _isChild,
      deliveryMethod: _deliveryMethod,
      address:
          _deliveryMethod == 'Courier' ? _addressController.text.trim() : '',
      pickupLocation: _pickupLocation,
      pickupDateTime: pickupDateTime,
      status: OrderStatus.pending,
      disease: _selectedDisease ?? 'Unknown',
    );

    await DatabaseHelper().insertMedicationOrder(order.toMap());

    if (_deliveryMethod == 'Pickup') {
      await NotificationService.schedulePickupReminder(
        medications: meds,
        location: _pickupLocation,
        pickupDateTime: pickupDateTime,
      );
    } else {
      await NotificationService.scheduleCourierReminder(
        medications: meds,
        address: _addressController.text.trim(),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.orderSuccess)));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final name = widget.userProfile['name'] ?? loc.guest;
    final medications =
        _selectedDisease != null
            ? _diseaseMedications[_selectedDisease!] ?? []
            : [];

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
            Expanded(child: Text('${loc.orderMedication}, $name')),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: Text(loc.isChild),
              value: _isChild,
              onChanged: (val) => setState(() => _isChild = val),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: loc.selectDisease),
              value: _selectedDisease,
              items:
                  _diseaseMedications.keys
                      .map(
                        (disease) => DropdownMenuItem(
                          value: disease,
                          child: Text(disease),
                        ),
                      )
                      .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDisease = val;
                  _selectedMedications.clear();
                  _medicationQuantities.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            if (medications.isNotEmpty)
              Text(
                loc.selectMedications,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ...medications.map((med) {
              final name = med['name']!;
              final selected = _selectedMedications.contains(name);
              return CheckboxListTile(
                title: Text(name),
                subtitle: Text(
                  '${loc.dosage}: ${med[_isChild ? 'child' : 'adult']} | ${loc.strength}: ${med['mg']}',
                ),
                value: selected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedMedications.add(name);
                      _medicationQuantities[name] = 1;
                    } else {
                      _selectedMedications.remove(name);
                      _medicationQuantities.remove(name);
                    }
                  });
                },
              );
            }),
            if (_selectedMedications.isNotEmpty)
              Column(
                children:
                    _selectedMedications.map((med) {
                      return Row(
                        children: [
                          Expanded(child: Text('Qty for $med:')),
                          DropdownButton<int>(
                            value: _medicationQuantities[med] ?? 1,
                            items:
                                List.generate(10, (i) => i + 1)
                                    .map(
                                      (num) => DropdownMenuItem(
                                        value: num,
                                        child: Text('$num'),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (val) => setState(
                                  () => _medicationQuantities[med] = val!,
                                ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _otherMedicationController,
              decoration: InputDecoration(
                labelText: loc.otherMedicationOptional,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final name = _otherMedicationController.text.trim();
                    if (name.isNotEmpty &&
                        !_selectedMedications.contains(name)) {
                      setState(() {
                        _selectedMedications.add(name);
                        _customQuantities[name] = 1;
                        _otherMedicationController.clear();
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _deliveryMethod,
              decoration: InputDecoration(labelText: loc.deliveryMethod),
              items: [
                DropdownMenuItem(
                  value: 'Pickup',
                  child: Text(loc.pickupAtHospital),
                ),
                DropdownMenuItem(
                  value: 'Courier',
                  child: Text(loc.courierDelivery),
                ),
              ],
              onChanged: (val) => setState(() => _deliveryMethod = val!),
            ),
            if (_deliveryMethod == 'Courier')
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: loc.deliveryAddress),
              ),
            if (_deliveryMethod == 'Pickup') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _pickupLocation,
                decoration: InputDecoration(labelText: loc.pickupLocation),
                items:
                    _pickupLocations
                        .map(
                          (loc) =>
                              DropdownMenuItem(value: loc, child: Text(loc)),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _pickupLocation = val!),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  _pickupDate == null
                      ? loc.selectPickupDate
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
                  if (picked != null) setState(() => _pickupDate = picked);
                },
              ),
              ListTile(
                title: Text(
                  _pickupTime == null
                      ? loc.selectPickupTime
                      : _pickupTime!.format(context),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) setState(() => _pickupTime = picked);
                },
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitOrder,
              child: Text(loc.submitOrder),
            ),
          ],
        ),
      ),
    );
  }
}

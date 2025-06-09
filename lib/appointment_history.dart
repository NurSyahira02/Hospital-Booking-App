import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order.dart';

class OrderMedicationPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const OrderMedicationPage({super.key, required this.userProfile});

  @override
  State<OrderMedicationPage> createState() => _OrderMedicationPageState();
}

class _OrderMedicationPageState extends State<OrderMedicationPage> {
  final List<String> selectedMedications = [];
  DateTime? selectedDateTime;
  String? selectedLocation;
  String?
  medicationDecision; // 'order_before', 'order_after', 'no_order', 'prescription'

  final List<String> pickupLocations = [
    'Main Lobby',
    'Drive-Thru Pharmacy',
    'Ward Dispensary',
  ];

  final Map<String, String> medicineDetails = {
    'Panadol':
        '500mg • For fever, mild to moderate pain\nAdult: 1 tab/6h • Child: ½ tab/6h',
    'Ibuprofen':
        '200mg • For inflammation, muscle pain\nAdult: 1 tab/8h • Child: ½ tab/8h',
    'Antibiotics':
        '250mg • For bacterial infections\nAdult: 1 cap/12h • Child: consult doctor',
  };

  void _submitOrder() {
    if (medicationDecision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an option for medication ordering.'),
        ),
      );
      return;
    }

    if (medicationDecision == 'no_order' ||
        medicationDecision == 'prescription') {
      Navigator.pop(context, null); // user chose not to order
      return;
    }

    if (selectedMedications.isEmpty ||
        selectedLocation == null ||
        selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all medication fields')),
      );
      return;
    }

    final newOrder = MedicationOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientName: widget.userProfile['name'],
      medications: selectedMedications,
      pickupLocation: selectedLocation!,
      pickupDateTime: selectedDateTime!,
    );

    Navigator.pop(context, newOrder);
  }

  Future<void> _pickDateTime() async {
    DateTime? appointment = widget.userProfile['appointmentDateTime'];

    final suggestedDate =
        appointment != null
            ? (medicationDecision == 'order_before'
                ? appointment.subtract(Duration(days: 1))
                : appointment.add(Duration(days: 1)))
            : DateTime.now().add(Duration(days: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: suggestedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _showMedicationDialog(String medicine) {
    bool isAdultSelected = selectedMedications.contains('$medicine (Adult)');
    bool isChildSelected = selectedMedications.contains('$medicine (Child)');

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: Text("Select Dosage for $medicine"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CheckboxListTile(
                        title: Text("Adult"),
                        value: isAdultSelected,
                        onChanged: (val) {
                          setStateDialog(() => isAdultSelected = val!);
                        },
                      ),
                      CheckboxListTile(
                        title: Text("Child"),
                        value: isChildSelected,
                        onChanged: (val) {
                          setStateDialog(() => isChildSelected = val!);
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (isAdultSelected) {
                            if (!selectedMedications.contains(
                              '$medicine (Adult)',
                            )) {
                              selectedMedications.add('$medicine (Adult)');
                            }
                          } else {
                            selectedMedications.remove('$medicine (Adult)');
                          }

                          if (isChildSelected) {
                            if (!selectedMedications.contains(
                              '$medicine (Child)',
                            )) {
                              selectedMedications.add('$medicine (Child)');
                            }
                          } else {
                            selectedMedications.remove('$medicine (Child)');
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Text('OK'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildMedicationOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Medications'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              medicineDetails.entries.map((entry) {
                return ElevatedButton(
                  onPressed: () => _showMedicationDialog(entry.key),
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.all(12)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(entry.value, style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 10),
        if (selectedMedications.isNotEmpty) ...[
          Text('Selected:'),
          ...selectedMedications.map((m) => Text('- $m')),
        ],
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: selectedLocation,
          decoration: InputDecoration(labelText: 'Pickup Location'),
          items:
              pickupLocations.map((loc) {
                return DropdownMenuItem(value: loc, child: Text(loc));
              }).toList(),
          onChanged: (value) {
            setState(() {
              selectedLocation = value;
            });
          },
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedDateTime == null
                    ? 'Choose Pickup Time'
                    : 'Pickup: ${DateFormat('yyyy-MM-dd – HH:mm').format(selectedDateTime!)}',
              ),
              if (widget.userProfile['appointmentDateTime'] != null)
                Text(
                  '📌 Your appointment is on ${DateFormat('yyyy-MM-dd – HH:mm').format(widget.userProfile['appointmentDateTime'])}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
          onPressed: _pickDateTime,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime? appointment = widget.userProfile['appointmentDateTime'];

    return Scaffold(
      appBar: AppBar(title: Text('Order Medication')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (appointment != null)
              Text(
                'Your Appointment: ${DateFormat('yyyy-MM-dd – HH:mm').format(appointment)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),
            Text('Do you want to order medication?'),
            Column(
              children: [
                RadioListTile<String>(
                  title: Text('Yes, before my appointment'),
                  value: 'order_before',
                  groupValue: medicationDecision,
                  onChanged: (val) => setState(() => medicationDecision = val),
                ),
                RadioListTile<String>(
                  title: Text('Yes, after my appointment'),
                  value: 'order_after',
                  groupValue: medicationDecision,
                  onChanged: (val) => setState(() => medicationDecision = val),
                ),
                RadioListTile<String>(
                  title: Text("No, I’ll get it from the doctor’s prescription"),
                  value: 'prescription',
                  groupValue: medicationDecision,
                  onChanged: (val) => setState(() => medicationDecision = val),
                ),
                RadioListTile<String>(
                  title: Text("No, I don't want to order"),
                  value: 'no_order',
                  groupValue: medicationDecision,
                  onChanged: (val) => setState(() => medicationDecision = val),
                ),
              ],
            ),
            const Divider(height: 30),
            if (medicationDecision == 'order_before' ||
                medicationDecision == 'order_after')
              Expanded(
                child: SingleChildScrollView(child: _buildMedicationOptions()),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _submitOrder,
              icon: Icon(Icons.check),
              label: Text('Submit'),
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}

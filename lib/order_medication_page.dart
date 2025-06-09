import 'package:flutter/material.dart';
import 'user_session.dart';

class OrderMedicationPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const OrderMedicationPage({super.key, required this.userProfile});

  @override
  State<OrderMedicationPage> createState() => _OrderMedicationPageState();
}

class _OrderMedicationPageState extends State<OrderMedicationPage> {
  String? selectedMedicine;
  String? pickupTime;
  String? selectedDate;

  final List<String> availableMedicines = [
    "Paracetamol 500mg - Adult: 1 tab, Child: ½ tab",
    "Amoxicillin 250mg - Adult: 1 cap, Child: ½ cap",
    "Cetirizine 10mg - Adult: 1 tab, Child: ½ tab",
  ];

  final List<String> pickupSlots = [
    "9:00 AM", "11:00 AM", "2:00 PM", "4:00 PM"
  ];

  void _submitOrder() {
    if (selectedMedicine == null || pickupTime == null || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all details')),
      );
      return;
    }

    final orderSummary =
        "Order placed for: $selectedMedicine\nPickup Date: $selectedDate\nTime: $pickupTime";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(orderSummary)),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        selectedDate =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Medication")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Select Medicine",
                border: OutlineInputBorder(),
              ),
              items: availableMedicines.map((medicine) {
                return DropdownMenuItem(
                  value: medicine,
                  child: Text(medicine),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedMedicine = value),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(selectedDate == null
                  ? "Select Pickup Date"
                  : "Pickup Date: $selectedDate"),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Select Pickup Time",
                border: OutlineInputBorder(),
              ),
              items: pickupSlots.map((slot) {
                return DropdownMenuItem(
                  value: slot,
                  child: Text(slot),
                );
              }).toList(),
              onChanged: (value) => setState(() => pickupTime = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitOrder,
              child: const Text("Confirm Order"),
            )
          ],
        ),
      ),
    );
  }
}

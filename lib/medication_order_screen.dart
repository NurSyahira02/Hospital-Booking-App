import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'medication_order.dart';

class MedicationOrderScreen extends StatefulWidget {
  final String patientEmail;
  const MedicationOrderScreen({super.key, required this.patientEmail});

  @override
  State<MedicationOrderScreen> createState() => _MedicationOrderScreenState();
}

class _MedicationOrderScreenState extends State<MedicationOrderScreen> {
  List<MedicationOrder> _orders = [];

  Future<void> _loadOrders() async {
    final rawOrders = await DatabaseHelper().getAllMedicationOrders();
    final filtered = rawOrders
        .where((o) => o['patient_email'] == widget.patientEmail)
        .map((data) => MedicationOrder.fromMap(data))
        .toList();
    setState(() => _orders = filtered);
  }

  Future<void> _deleteOrder(String id) async {
    await DatabaseHelper().deleteMedicationOrder(int.parse(id)); // ID is String → int
    _loadOrders();
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication Orders')),
      body: _orders.isEmpty
          ? const Center(child: Text('No orders found'))
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(order.medications.join(', ')), // ✅ Fix here
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quantity: ${order.quantity}'),
                        Text('For: ${order.isChild ? 'Child' : 'Adult'}'),
                        Text('Delivery: ${order.deliveryMethod}'),
                        if (order.deliveryMethod == 'Courier')
                          Text('Address: ${order.address}'),
                        Text('Status: ${order.status.name}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteOrder(order.id), // ✅ Uses correct type
                    ),
                  ),
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'medication_order.dart';

class MedicationOrderHistoryPage extends StatefulWidget {
  final String email;
  const MedicationOrderHistoryPage({super.key, required this.email});

  @override
  State<MedicationOrderHistoryPage> createState() =>
      _MedicationOrderHistoryPageState();
}

class _MedicationOrderHistoryPageState
    extends State<MedicationOrderHistoryPage> {
  List<MedicationOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final allOrders = await DatabaseHelper().getAllMedicationOrders();

    final filtered =
        allOrders
            .map((map) => MedicationOrder.fromMap(map))
            .where((order) => order.patientEmail == widget.email)
            .toList();

    // Sort: upcoming first
    filtered.sort((a, b) => a.pickupDateTime.compareTo(b.pickupDateTime));

    setState(() => _orders = filtered);
  }

  Future<void> _deleteOrder(String id) async {
    final numericId = int.tryParse(id);
    if (numericId == null) return;

    await DatabaseHelper().deleteMedicationOrder(numericId);
    _loadOrders();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order deleted')));
    }
  }

  void _showDeleteConfirmation(MedicationOrder order) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Order'),
            content: const Text('Are you sure you want to delete this order?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteOrder(order.id);
                },
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication Order History')),
      body:
          _orders.isEmpty
              ? const Center(child: Text('No orders found.'))
              : ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final now = DateTime.now();
                  final isPast = order.pickupDateTime.isBefore(now);

                  return Card(
                    color: isPast ? Colors.grey[200] : Colors.white,
                    child: ListTile(
                      title: Text(
                        'Medication: ${order.medications.join(', ')}',
                      ),
                      subtitle: Text(
                        'Pickup: ${order.pickupLocation} on ${order.pickupDateTime}\nStatus: ${order.status.name}',
                      ),
                      trailing: Icon(isPast ? Icons.history : Icons.schedule),
                      onLongPress:
                          () => _showDeleteConfirmation(
                            order,
                          ), // long-press to delete
                    ),
                  );
                },
              ),
    );
  }
}

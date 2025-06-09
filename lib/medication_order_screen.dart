// medication_order_screen.dart
import 'package:flutter/material.dart';
import 'order.dart';

class MedicationOrderScreen extends StatelessWidget {
  final List<MedicationOrder> medicationOrders;
  final Function(String orderId, OrderStatus status) onUpdateStatus;

  MedicationOrderScreen({
    required this.medicationOrders,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (medicationOrders.isEmpty) {
      return Center(child: Text('No medication orders at the moment.'));
    }

    return ListView.builder(
      itemCount: medicationOrders.length,
      itemBuilder: (context, index) {
        final order = medicationOrders[index];

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text('Order ID: ${order.id}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient: ${order.patientName}'),
                Text('Medications: ${order.medications.join(', ')}'),
                Text('Pickup Location: ${order.pickupLocation}'),
                Text('Pickup Date & Time: ${order.pickupDateTime}'),
                Text('Status: ${order.status.name}'),
              ],
            ),
            trailing: PopupMenuButton<OrderStatus>(
              onSelected: (OrderStatus status) {
                onUpdateStatus(order.id, status);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order ${order.id} status updated to ${status.name}')),
                );
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<OrderStatus>>[
                const PopupMenuItem<OrderStatus>(
                  value: OrderStatus.pending,
                  child: Text('Pending'),
                ),
                const PopupMenuItem<OrderStatus>(
                  value: OrderStatus.processing,
                  child: Text('Processing'),
                ),
                const PopupMenuItem<OrderStatus>(
                  value: OrderStatus.completed,
                  child: Text('Completed'),
                ),
              ],
              icon: Icon(Icons.more_vert),
            ),
          ),
        );
      },
    );
  }
}

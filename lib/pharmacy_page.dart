import 'package:flutter/material.dart';
import 'order.dart';

class PharmacyPage extends StatefulWidget {
  final List<MedicationOrder> medicationOrders;
  final Function(String orderId, OrderStatus status) onUpdateStatus;

  const PharmacyPage({
    super.key,
    required this.medicationOrders,
    required this.onUpdateStatus,
  });

  @override
  State<PharmacyPage> createState() => _PharmacyPageState();
}

class _PharmacyPageState extends State<PharmacyPage> {
  OrderStatus? selectedFilter;

  List<MedicationOrder> get filteredOrders {
    if (selectedFilter == null) return widget.medicationOrders;
    return widget.medicationOrders
        .where((order) => order.status == selectedFilter)
        .toList();
  }

  void _showOrderDetails(MedicationOrder order) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Order Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient: ${order.patientName}'),
                Text('Medications:\n${order.medications.join('\n')}'),
                Text('Pickup Location: ${order.pickupLocation}'),
                Text('Pickup Time: ${order.pickupDateTime}'),
                Text('Status: ${order.status.name}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildStatusIcon(OrderStatus status) {
    IconData icon;
    Color color;
    switch (status) {
      case OrderStatus.pending:
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      case OrderStatus.processing:
        icon = Icons.sync;
        color = Colors.blue;
        break;
      case OrderStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
    }
    return Icon(icon, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy'),
        actions: [
          DropdownButton<OrderStatus?>(
            value: selectedFilter,
            hint: const Text("Filter", style: TextStyle(color: Colors.white)),
            dropdownColor: Colors.white,
            underline: Container(),
            onChanged: (status) {
              setState(() {
                selectedFilter = status;
              });
            },
            items: [
              const DropdownMenuItem<OrderStatus?>(
                value: null,
                child: Text('All'),
              ),
              ...OrderStatus.values.map((status) {
                return DropdownMenuItem<OrderStatus?>(
                  value: status,
                  child: Text(status.name),
                );
              }),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body:
          filteredOrders.isEmpty
              ? const Center(child: Text('No medication orders.'))
              : ListView.builder(
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: _buildStatusIcon(order.status),
                      title: Text('Patient: ${order.patientName}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pickup: ${order.pickupDateTime}'),
                          Text('Location: ${order.pickupLocation}'),
                        ],
                      ),
                      trailing: DropdownButton<OrderStatus>(
                        value: order.status,
                        underline: Container(),
                        onChanged: (newStatus) {
                          if (newStatus != null && newStatus != order.status) {
                            widget.onUpdateStatus(order.id, newStatus);
                            setState(() {
                              order.status = newStatus;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Status updated')),
                            );
                          }
                        },
                        items:
                            OrderStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status.name),
                              );
                            }).toList(),
                      ),
                      onTap: () => _showOrderDetails(order),
                    ),
                  );
                },
              ),
    );
  }
}

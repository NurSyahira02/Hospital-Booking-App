import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'medication_order.dart' as mo;
import 'notification_service.dart';

class PharmacyPage extends StatefulWidget {
  final List<mo.MedicationOrder> medicationOrders;
  final Function(String orderId, mo.OrderStatus status) onUpdateStatus;

  const PharmacyPage({
    super.key,
    required this.medicationOrders,
    required this.onUpdateStatus,
  });

  @override
  State<PharmacyPage> createState() => _PharmacyPageState();
}

class _PharmacyPageState extends State<PharmacyPage> {
  mo.OrderStatus? selectedStatusFilter;
  String _searchQuery = '';
  String _dateFilter = 'All'; // All, Today, Upcoming, Past
  final Map<String, File?> _profileImages = {};

  @override
  void initState() {
    super.initState();
    _loadProfileImages();
  }

  Future<void> _loadProfileImages() async {
    final prefs = await SharedPreferences.getInstance();
    final imageMap = <String, File?>{};
    for (var order in widget.medicationOrders) {
      final email = order.patientEmail;
      final path = prefs.getString('profileImagePath_$email');
      if (path != null && File(path).existsSync()) {
        imageMap[email] = File(path);
      }
    }
    setState(() => _profileImages.addAll(imageMap));
  }

  List<mo.MedicationOrder> get filteredOrders {
    final now = DateTime.now();

    return widget.medicationOrders.where((order) {
      final matchStatus = selectedStatusFilter == null || order.status == selectedStatusFilter;
      final matchSearch = _searchQuery.isEmpty ||
          order.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.medications.any((m) => m.toLowerCase().contains(_searchQuery.toLowerCase()));

      final pickup = order.pickupDateTime;
      final isToday = pickup.year == now.year &&
          pickup.month == now.month &&
          pickup.day == now.day;
      final isUpcoming = pickup.isAfter(now);
      final isPast = pickup.isBefore(now);

      final matchDate = switch (_dateFilter) {
        'Today' => isToday,
        'Upcoming' => isUpcoming,
        'Past' => isPast,
        _ => true
      };

      return matchStatus && matchSearch && matchDate;
    }).toList();
  }

  Future<void> _sendManualReminder(mo.MedicationOrder order) async {
    await NotificationService.sendManualReminder(
      medications: order.medications,
      location: order.pickupLocation,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder sent to patient')),
    );
  }

  void _showOrderDetails(mo.MedicationOrder order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Order Details'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy'),
        actions: [
          DropdownButton<String>(
            value: _dateFilter,
            underline: Container(),
            dropdownColor: Colors.white,
            onChanged: (value) => setState(() => _dateFilter = value!),
            items: ['All', 'Today', 'Upcoming', 'Past']
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
          ),
          DropdownButton<mo.OrderStatus?>(
            value: selectedStatusFilter,
            underline: Container(),
            dropdownColor: Colors.white,
            onChanged: (status) => setState(() => selectedStatusFilter = status),
            items: [
              const DropdownMenuItem<mo.OrderStatus?>(
                value: null,
                child: Text('All'),
              ),
              ...mo.OrderStatus.values.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.name),
                  )),
            ],
          ),
          const SizedBox(width: 10),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search name or medication...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
      ),
      body: filteredOrders.isEmpty
          ? const Center(child: Text('No medication orders.'))
          : ListView.builder(
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                final image = _profileImages[order.patientEmail];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: image != null
                          ? FileImage(image)
                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                    title: Text('Patient: ${order.patientName}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pickup: ${order.pickupDateTime}'),
                        Text('Location: ${order.pickupLocation}'),
                        Text('Status: ${order.status.name}'),
                      ],
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<mo.OrderStatus>(
                          value: order.status,
                          underline: Container(),
                          onChanged: (newStatus) {
                            if (newStatus != null && newStatus != order.status) {
                              widget.onUpdateStatus(order.id, newStatus);
                              setState(() => order.status = newStatus);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Status updated')),
                              );
                            }
                          },
                          items: mo.OrderStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status.name),
                            );
                          }).toList(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications),
                          tooltip: 'Send Reminder',
                          onPressed: () => _sendManualReminder(order),
                        ),
                      ],
                    ),
                    onTap: () => _showOrderDetails(order),
                  ),
                );
              },
            ),
    );
  }
}

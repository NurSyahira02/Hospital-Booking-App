import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'database_helper.dart';

class ViewMedicationOrdersPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const ViewMedicationOrdersPage({super.key, required this.userProfile});

  @override
  State<ViewMedicationOrdersPage> createState() => _ViewMedicationOrdersPageState();
}

class _ViewMedicationOrdersPageState extends State<ViewMedicationOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  File? _profileImage;
  bool _showUpcomingOnly = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadProfileImage();
  }

  Future<void> _loadOrders() async {
    final all = await DatabaseHelper().getAllMedicationOrders();
    final email = widget.userProfile['email'];

    final filtered = all.where((order) => order['patient_email'] == email).toList();
    filtered.sort((a, b) => b['id'].compareTo(a['id']));
    setState(() => _orders = filtered);
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profileImagePath');
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImage = File(path));
    }
  }

  Future<void> _deleteOrder(int id) async {
    await DatabaseHelper().deleteMedicationOrder(id);
    _loadOrders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.orderDeleted)),
      );
    }
  }

  String _translateStatus(String status, AppLocalizations loc) {
    switch (status.toLowerCase()) {
      case 'pending':
        return loc.statusPending;
      case 'ready':
        return loc.statusReady;
      case 'completed':
        return loc.statusCompleted;
      case 'cancelled':
        return loc.statusCancelled;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final filteredOrders = _orders.where((order) {
      final pickup = DateTime.tryParse(order['pickupDateTime'] ?? '') ?? DateTime.now();
      return _showUpcomingOnly ? pickup.isAfter(DateTime.now()) : pickup.isBefore(DateTime.now());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Text(loc.orderMedication),
          ],
        ),
        actions: [
          PopupMenuButton<bool>(
            initialValue: _showUpcomingOnly,
            onSelected: (value) => setState(() => _showUpcomingOnly = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: true, child: Text(loc.upcomingAppointments)),
              PopupMenuItem(value: false, child: Text(loc.pastAppointments)),
            ],
          )
        ],
      ),
      body: filteredOrders.isEmpty
          ? Center(
              child: Text(_showUpcomingOnly
                  ? loc.noUpcomingOrders
                  : loc.noPastOrders),
            )
          : ListView.builder(
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                final meds = (order['medication'] as String?)?.split(', ') ?? [];
                final status = _translateStatus(order['status'] ?? 'Pending', loc);
                final date = order['pickupDateTime'] ?? '';
                final method = order['delivery_method'] ?? '-';
                final location = order['pickup_location'] ?? '-';

                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(loc.cancelOrder),
                        content: Text(loc.cancelOrderConfirm),
                        actions: [
                          TextButton(
                            child: Text(loc.cancel),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: Text(loc.logoutYes),
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteOrder(order['id']);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${loc.medications}: ${meds.join(', ')}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text('${loc.pickupLocation}: $location'),
                          Text('${loc.date}: $date'),
                          Text('${loc.deliveryMethod}: $method'),
                          Text('${loc.status}: $status'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

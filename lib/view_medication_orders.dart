import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'database_helper.dart';

class ViewMedicationOrdersPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const ViewMedicationOrdersPage({Key? key, required this.userProfile})
    : super(key: key);

  @override
  _ViewMedicationOrdersPageState createState() =>
      _ViewMedicationOrdersPageState();
}

class _ViewMedicationOrdersPageState extends State<ViewMedicationOrdersPage> {
  Map<String, List<Map<String, dynamic>>> groupedOrders = {};
  bool showUpcoming = true;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadMedicationOrders();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('loggedInEmail');
    final path = prefs.getString('profileImagePath_$email');
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImage = File(path));
    }
  }

  Future<void> _loadMedicationOrders() async {
    final email = widget.userProfile['email'];
    final all = await DatabaseHelper().getAllMedicationOrders();
    final filtered =
        all.where((order) => order['patient_email'] == email).toList();

    final now = DateTime.now();
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var order in filtered) {
      final pickup = DateTime.tryParse(order['pickup_datetime'] ?? '');
      if (pickup == null) continue;

      final isUpcoming = pickup.isAfter(now);
      if ((showUpcoming && !isUpcoming) || (!showUpcoming && isUpcoming))
        continue;

      final disease = order['disease'] ?? 'Other';
      grouped.putIfAbsent(disease, () => []).add(order);
    }

    setState(() {
      groupedOrders = grouped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final name = widget.userProfile['name'] ?? loc.guest;

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
            Expanded(child: Text("${loc.viewMedicationOrders} - $name")),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(showUpcoming ? Icons.history : Icons.upcoming),
            tooltip: showUpcoming ? loc.showPastOrders : loc.showUpcomingOrders,
            onPressed: () {
              setState(() {
                showUpcoming = !showUpcoming;
              });
              _loadMedicationOrders();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: loc.refresh,
            onPressed: () async {
              await _loadMedicationOrders();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(loc.ordersRefreshed)));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMedicationOrders,
        child:
            groupedOrders.isEmpty
                ? ListView(
                  children: [
                    const SizedBox(height: 200),
                    Center(
                      child: Text(
                        showUpcoming ? loc.noUpcomingOrders : loc.noPastOrders,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                )
                : ListView(
                  children:
                      groupedOrders.entries.map((entry) {
                        final disease = entry.key;
                        final orders = entry.value;

                        return ExpansionTile(
                          title: Text(
                            disease,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children:
                              orders.map((order) {
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      "${loc.medications}: ${order['medications']}",
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${loc.deliveryMethod}: ${order['delivery_method']}",
                                        ),
                                        if (order['delivery_method'] ==
                                            'Pickup')
                                          Text(
                                            "${loc.pickupLocation}: ${order['pickup_location']}",
                                          ),
                                        if (order['delivery_method'] ==
                                            'Courier')
                                          Text(
                                            "${loc.deliveryAddress}: ${order['address']}",
                                          ),
                                        Text(
                                          "${loc.pickupTime}: ${order['pickup_datetime']}",
                                        ),
                                        Text(
                                          "${loc.status}: ${order['status']}",
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        );
                      }).toList(),
                ),
      ),
    );
  }
}

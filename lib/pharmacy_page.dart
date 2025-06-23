import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'medication_order.dart' as mo;
import 'notification_service.dart';

class PharmacyPage extends StatefulWidget {
  final List<mo.MedicationOrder> medicationOrders;
  final String currentPatientEmail;

  const PharmacyPage({
    super.key,
    required this.medicationOrders,
    required this.currentPatientEmail,
  });

  @override
  State<PharmacyPage> createState() => _PharmacyPageState();
}

class _PharmacyPageState extends State<PharmacyPage> {
  String _searchQuery = '';
  String _diseaseFilter = 'All';
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
    return widget.medicationOrders
        .where((order) => order.patientEmail == widget.currentPatientEmail)
        .where((order) {
          final disease =
              order.disease == 'Unknown' ? 'General' : order.disease;
          final matchDisease =
              _diseaseFilter == 'All' || disease == _diseaseFilter;
          final matchSearch =
              _searchQuery.isEmpty ||
              order.medications.any(
                (m) => m.toLowerCase().contains(_searchQuery.toLowerCase()),
              );
          return matchDisease && matchSearch;
        })
        .toList();
  }

  Map<String, List<mo.MedicationOrder>> get groupedByDisease {
    final Map<String, List<mo.MedicationOrder>> map = {};
    for (var order in filteredOrders) {
      final diseaseKey = order.disease == 'Unknown' ? 'General' : order.disease;
      map.putIfAbsent(diseaseKey, () => []).add(order);
    }
    return map;
  }

  Future<void> _sendManualReminder(mo.MedicationOrder order) async {
    await NotificationService.sendManualReminder(
      medications: order.medications,
      location: order.pickupLocation,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder sent to patient')));
  }

  void _cancelOrder(mo.MedicationOrder order) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(loc.confirmCancel),
            content: Text(loc.cancelConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.no),
              ),
              TextButton(
                onPressed: () {
                  setState(() => order.status = mo.OrderStatus.cancelled);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(loc.orderCancelled)));
                },
                child: Text(loc.yes),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final uniqueDiseases = {
      'All',
      ...widget.medicationOrders
          .where((o) => o.patientEmail == widget.currentPatientEmail)
          .map((o) => o.disease == 'Unknown' ? 'General' : o.disease),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.pharmacy),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: loc.searchMedicationOrPatient,
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: DropdownButton<String>(
                  value: _diseaseFilter,
                  onChanged: (val) => setState(() => _diseaseFilter = val!),
                  items:
                      uniqueDiseases
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body:
          groupedByDisease.isEmpty
              ? Center(child: Text(loc.noMedicationOrders))
              : ListView(
                children:
                    groupedByDisease.entries.map((entry) {
                      final disease = entry.key;
                      final orders = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              '🦠 $disease',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...orders.map((order) {
                            final image = _profileImages[order.patientEmail];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      image != null
                                          ? FileImage(image)
                                          : const AssetImage(
                                                'assets/default_avatar.png',
                                              )
                                              as ImageProvider,
                                ),
                                title: Text(
                                  '${loc.patient}: ${order.patientName}',
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${loc.pickupTime}: ${order.pickupDateTime}',
                                    ),
                                    Text(
                                      '${loc.pickupLocation}: ${order.pickupLocation}',
                                    ),
                                    Text('${loc.status}: ${order.status.name}'),
                                  ],
                                ),
                                trailing: Wrap(
                                  direction: Axis.vertical,
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.notifications),
                                      tooltip: loc.sendReminder,
                                      onPressed:
                                          () => _sendManualReminder(order),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      ),
                                      tooltip: loc.cancel,
                                      onPressed: () => _cancelOrder(order),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
              ),
    );
  }
}

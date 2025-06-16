import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'database_helper.dart';

class AppointmentHistoryPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const AppointmentHistoryPage({super.key, required this.userProfile});

  @override
  State<AppointmentHistoryPage> createState() => _AppointmentHistoryPageState();
}

class _AppointmentHistoryPageState extends State<AppointmentHistoryPage> {
  List<Map<String, dynamic>> _appointments = [];
  File? _profileImage;
  int? _touchedIndex;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _loadProfileImage();
  }

  Future<void> _loadAppointments() async {
    final db = DatabaseHelper();
    final results = await db.getAppointmentsForPatient(widget.userProfile['email']);
    setState(() => _appointments = results);
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profileImagePath');
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImage = File(path));
    }
  }

  Map<String, int> _countByType() {
    final Map<String, int> counts = {};
    for (var appt in _appointments) {
      final type = appt['reason'] ?? 'Unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  List<Map<String, dynamic>> _filteredAppointments() {
    if (_selectedFilter == 'All') return _appointments;
    return _appointments.where((a) => a['reason'] == _selectedFilter).toList();
  }

  Future<void> _exportToCSV() async {
    final loc = AppLocalizations.of(context)!;
    List<List<String>> rows = [
      [loc.date, loc.dr, loc.appointmentType]
    ];
    for (var appt in _filteredAppointments()) {
      rows.add([
        appt['dateTime'] ?? '',
        appt['doctor'] ?? '',
        appt['reason'] ?? '',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csvData);
    final blob = Uint8List.fromList(bytes);

    await Printing.sharePdf(
      bytes: blob,
      filename: 'appointments.csv',
    );
  }

  String _buildHtmlExport(List<Map<String, dynamic>> data) {
    final rows = data.map((e) {
      final date = e['dateTime'] ?? '';
      final dr = e['doctor'] ?? '';
      final reason = e['reason'] ?? '';
      return '<tr><td>$date</td><td>$dr</td><td>$reason</td></tr>';
    }).join();

    return '''
      <html>
      <head>
        <style>
          table { width: 100%; border-collapse: collapse; }
          th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
        </style>
      </head>
      <body>
        <h2>Appointment Summary</h2>
        <table>
          <tr><th>Date</th><th>Doctor</th><th>Type</th></tr>
          $rows
        </table>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final chartData = _countByType();
    final filteredAppointments = _filteredAppointments();

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
            Text(loc.appointmentHistory),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: _exportToCSV,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print',
            onPressed: () => Printing.layoutPdf(
              onLayout: (_) => Printing.convertHtml(
                format: PdfPageFormat.a4,
                html: _buildHtmlExport(filteredAppointments),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _appointments.isEmpty
            ? Center(child: Text(loc.noPastAppointments))
            : Column(
                children: [
                  DropdownButton<String>(
                    value: _selectedFilter,
                    items: ['All', ...chartData.keys].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedFilter = val!);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (chartData.isNotEmpty)
                    Column(
                      children: [
                        const Text(
                          'Appointment Summary',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  setState(() {
                                    _touchedIndex =
                                        response?.touchedSection?.touchedSectionIndex;
                                  });
                                },
                              ),
                              sections: chartData.entries.mapIndexed((index, entry) {
                                final isTouched = _touchedIndex == index;
                                final color = Colors.primaries[index % Colors.primaries.length];
                                final double fontSize = isTouched ? 14 : 12;
                                final double radius = isTouched ? 65 : 60;

                                return PieChartSectionData(
                                  color: color,
                                  value: entry.value.toDouble(),
                                  title: '${entry.value}',
                                  titleStyle: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  radius: radius,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: chartData.entries.mapIndexed((index, entry) {
                            final color = Colors.primaries[index % Colors.primaries.length];
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(backgroundColor: color, radius: 5),
                                const SizedBox(width: 4),
                                Text(entry.key, style: const TextStyle(fontSize: 12)),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredAppointments.length,
                      itemBuilder: (context, index) {
                        final appointment = filteredAppointments[index];
                        final doctor = appointment['doctor'] ?? loc.unknown;
                        final dateTime = appointment['dateTime'] ?? loc.notSet;
                        final reason = appointment['reason'] ?? '-';

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text('${loc.dr} $doctor'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${loc.date}: $dateTime'),
                                Text('${loc.appointmentType}: $reason'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  Iterable<E> mapIndexed<E>(E Function(int, T) f) sync* {
    int i = 0;
    for (final item in this) {
      yield f(i++, item);
    }
  }
}

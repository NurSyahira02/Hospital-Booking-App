// order.dart

enum OrderStatus { pending, processing, completed }

class MedicationOrder {
  final String id;
  final String patientName;
  final List<String> medications;
  final String pickupLocation;
  final DateTime pickupDateTime;
  OrderStatus status;

  MedicationOrder({
    required this.id,
    required this.patientName,
    required this.medications,
    required this.pickupLocation,
    required this.pickupDateTime,
    this.status = OrderStatus.pending,
  });

  // ✅ Convert object to Map<String, dynamic> for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientName': patientName,
      'medications': medications.join(','), // store list as comma-separated string
      'pickupLocation': pickupLocation,
      'pickupDateTime': pickupDateTime.toIso8601String(),
      'status': status.name, // save as string name (e.g., "pending")
    };
  }

  // Create object from Map<String, dynamic> from SQLite
  factory MedicationOrder.fromMap(Map<String, dynamic> map) {
    return MedicationOrder(
      id: map['id'],
      patientName: map['patientName'],
      medications: map['medications'].split(','), // convert string back to list
      pickupLocation: map['pickupLocation'],
      pickupDateTime: DateTime.parse(map['pickupDateTime']),
      status: OrderStatus.values.firstWhere((e) => e.name == map['status']),
    );
  }
}


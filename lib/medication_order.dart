enum OrderStatus {
  pending,
  processing,
  approved,
  completed,
}

class MedicationOrder {
  final String id;
  final String patientName;
  final String patientEmail;
  final List<String> medications;
  final int quantity;
  final bool isChild;
  final String deliveryMethod;
  final String address;
  final String pickupLocation;
  final DateTime pickupDateTime;
  OrderStatus status;

  MedicationOrder({
    required this.id,
    required this.patientName,
    required this.patientEmail,
    required this.medications,
    required this.quantity,
    required this.isChild,
    required this.deliveryMethod,
    required this.address,
    required this.pickupLocation,
    required this.pickupDateTime,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_name': patientName,             // ✅ snake_case
      'patient_email': patientEmail,           // ✅ snake_case
      'medications': medications.join(','),
      'quantity': quantity,
      'is_child': isChild ? 1 : 0,
      'delivery_method': deliveryMethod,       // ✅ snake_case
      'address': address,
      'pickup_location': pickupLocation,       // ✅ snake_case
      'pickup_datetime': pickupDateTime.toIso8601String(), // ✅ snake_case
      'status': status.name,
    };
  }

  factory MedicationOrder.fromMap(Map<String, dynamic> map) {
    return MedicationOrder(
      id: map['id'].toString(),
      patientName: map['patient_name'],             // ✅ match DB column
      patientEmail: map['patient_email'],
      medications: (map['medications'] as String).split(',').map((s) => s.trim()).toList(),
      quantity: map['quantity'],
      isChild: map['is_child'] == 1,
      deliveryMethod: map['delivery_method'],
      address: map['address'],
      pickupLocation: map['pickup_location'],
      pickupDateTime: DateTime.parse(map['pickup_datetime']),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
    );
  }
}

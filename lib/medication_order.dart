enum OrderStatus { pending, processing, ready, completed, cancelled }

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
  final String disease;
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
    required this.disease,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_name': patientName,
      'patient_email': patientEmail,
      'medications': medications.join(','),
      'quantity': quantity,
      'is_child': isChild ? 1 : 0,
      'delivery_method': deliveryMethod,
      'address': address,
      'pickup_location': pickupLocation,
      'pickup_datetime': pickupDateTime.toIso8601String(),
      'status': status.name,
      'disease': disease,
    };
  }

  factory MedicationOrder.fromMap(Map<String, dynamic> map) {
    return MedicationOrder(
      id: (map['id'] ?? '').toString(),
      patientName: map['patient_name'] ?? 'Unknown',
      patientEmail: map['patient_email'] ?? '',
      medications:
          (map['medications'] ?? '')
              .toString()
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
      quantity: map['quantity'] ?? 0,
      isChild: map['is_child'] == 1,
      deliveryMethod: map['delivery_method'] ?? 'Pickup',
      address: map['address'] ?? '',
      pickupLocation: map['pickup_location'] ?? '',
      pickupDateTime:
          DateTime.tryParse(map['pickup_datetime'] ?? '') ?? DateTime.now(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      disease: (map['disease'] ?? 'General'),
    );
  }
}

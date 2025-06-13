class Appointment {
  final String id;
  final String patientEmail;
  final String doctor;
  final String dateTime;
  final String reason;

  Appointment({
    required this.id,
    required this.patientEmail,
    required this.doctor,
    required this.dateTime,
    required this.reason,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'].toString(),
      patientEmail: map['patient_email'], // ✅ DB = patient_email
      doctor: map['doctor'],
      dateTime: map['dateTime'],
      reason: map['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_email': patientEmail, // ✅ Match DB naming
      'doctor': doctor,
      'dateTime': dateTime,
      'reason': reason,
    };
  }
}


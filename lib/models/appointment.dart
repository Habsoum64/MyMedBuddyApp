class Appointment {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String doctorName;
  final String location;
  final String type; // checkup, consultation, surgery, etc.
  final AppointmentStatus status;
  final String? notes;

  Appointment({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.doctorName,
    required this.location,
    required this.type,
    this.status = AppointmentStatus.scheduled,
    this.notes,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      doctorName: map['doctorName'] ?? '',
      location: map['location'] ?? '',
      type: map['type'] ?? '',
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString() == 'AppointmentStatus.${map['status']}',
        orElse: () => AppointmentStatus.scheduled,
      ),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'doctorName': doctorName,
      'location': location,
      'type': type,
      'status': status.toString().split('.').last,
      'notes': notes,
    };
  }

  Appointment copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    String? doctorName,
    String? location,
    String? type,
    AppointmentStatus? status,
    String? notes,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      doctorName: doctorName ?? this.doctorName,
      location: location ?? this.location,
      type: type ?? this.type,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

enum AppointmentStatus {
  scheduled,
  completed,
  cancelled,
  missed,
}

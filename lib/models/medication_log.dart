class MedicationLog {
  final String id;
  final String medicationId;
  final String medicationName;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final MedicationStatus status;
  final String? notes;

  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    this.takenTime,
    this.status = MedicationStatus.pending,
    this.notes,
  });

  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      id: map['id'] ?? '',
      medicationId: map['medicationId'] ?? '',
      medicationName: map['medicationName'] ?? '',
      scheduledTime: DateTime.parse(map['scheduledTime']),
      takenTime: map['takenTime'] != null ? DateTime.parse(map['takenTime']) : null,
      status: MedicationStatus.values.firstWhere(
        (e) => e.toString() == 'MedicationStatus.${map['status']}',
        orElse: () => MedicationStatus.pending,
      ),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'takenTime': takenTime?.toIso8601String(),
      'status': status.toString().split('.').last,
      'notes': notes,
    };
  }

  MedicationLog copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    DateTime? scheduledTime,
    DateTime? takenTime,
    MedicationStatus? status,
    String? notes,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

enum MedicationStatus {
  pending,
  late,
  taken,
  missed,
  skipped,
}

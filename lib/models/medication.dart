class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String instructions;
  final DateTime startDate;
  final DateTime? endDate;
  final String category;
  final bool isActive;
  final List<String> times; // Times of day to take (e.g., ["08:00", "20:00"])

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.instructions,
    required this.startDate,
    this.endDate,
    required this.category,
    this.isActive = true,
    required this.times,
  });

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      instructions: map['instructions'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      category: map['category'] ?? '',
      isActive: map['isActive'] ?? true,
      times: List<String>.from(map['times'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'instructions': instructions,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'category': category,
      'isActive': isActive,
      'times': times,
    };
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    String? instructions,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    bool? isActive,
    List<String>? times,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      instructions: instructions ?? this.instructions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      times: times ?? this.times,
    );
  }
}

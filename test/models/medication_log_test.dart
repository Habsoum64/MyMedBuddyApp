import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/medication_log.dart';

void main() {
  group('MedicationLog Tests', () {
    test('copyWith should update takenTime correctly', () {
      final originalLog = MedicationLog(
        id: 'test_id',
        medicationId: 'med_id',
        medicationName: 'Test Medication',
        scheduledTime: DateTime(2024, 1, 1, 8, 0),
        status: MedicationStatus.pending,
      );

      final takenTime = DateTime(2024, 1, 1, 8, 15);
      final updatedLog = originalLog.copyWith(
        takenTime: takenTime,
        status: MedicationStatus.taken,
      );

      expect(updatedLog.takenTime, equals(takenTime));
      expect(updatedLog.scheduledTime, equals(DateTime(2024, 1, 1, 8, 0)));
      expect(updatedLog.status, equals(MedicationStatus.taken));
    });

    test('toMap should include takenTime when not null', () {
      final log = MedicationLog(
        id: 'test_id',
        medicationId: 'med_id',
        medicationName: 'Test Medication',
        scheduledTime: DateTime(2024, 1, 1, 8, 0),
        takenTime: DateTime(2024, 1, 1, 8, 15),
        status: MedicationStatus.taken,
      );

      final map = log.toMap();
      expect(map['takenTime'], isNotNull);
      expect(map['takenTime'], equals(DateTime(2024, 1, 1, 8, 15).toIso8601String()));
    });

    test('fromMap should parse takenTime correctly', () {
      final map = {
        'id': 'test_id',
        'medicationId': 'med_id',
        'medicationName': 'Test Medication',
        'scheduledTime': DateTime(2024, 1, 1, 8, 0).toIso8601String(),
        'takenTime': DateTime(2024, 1, 1, 8, 15).toIso8601String(),
        'status': 'taken',
      };

      final log = MedicationLog.fromMap(map);
      expect(log.takenTime, equals(DateTime(2024, 1, 1, 8, 15)));
      expect(log.scheduledTime, equals(DateTime(2024, 1, 1, 8, 0)));
      expect(log.status, equals(MedicationStatus.taken));
    });
  });
}

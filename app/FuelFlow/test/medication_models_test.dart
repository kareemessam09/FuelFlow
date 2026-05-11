import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_flow/data/models/medication_models.dart';

void main() {
  group('MedicationSchedule.fromJson', () {
    test('parses daysOfWeek from comma-separated string with invalid tokens', () {
      final schedule = MedicationSchedule.fromJson({
        'id': 10,
        'userId': 'u1',
        'medicationId': 3,
        'daysOfWeek': '1, 2, bad, 7',
        'time': '08:00',
        'enabled': true,
        'createdAt': '2026-04-02T12:00:00.000Z',
      });

      expect(schedule.daysOfWeek, [1, 2, 7]);
    });

    test('parses daysOfWeek from list values', () {
      final schedule = MedicationSchedule.fromJson({
        'id': 11,
        'userId': 'u1',
        'medicationId': 3,
        'daysOfWeek': [1, '2', 'x', 5],
        'time': '20:15',
        'enabled': true,
        'createdAt': '2026-04-02T12:00:00.000Z',
      });

      expect(schedule.daysOfWeek, [1, 2, 5]);
    });
  });

  group('MedicationLog.toCreateJson', () {
    test('converts numeric IDs to ints and keeps notes', () {
      final now = DateTime.parse('2026-04-02T12:00:00.000Z');
      final log = MedicationLog(
        id: '0',
        userId: 'u1',
        medicationId: '12',
        mealId: '34',
        takenAt: now,
        notes: 'Taken with water',
      );

      final json = log.toCreateJson();
      expect(json['medicationId'], 12);
      expect(json['mealId'], 34);
      expect(json['notes'], 'Taken with water');
      expect(json['takenAt'], now.toIso8601String());
    });
  });
}

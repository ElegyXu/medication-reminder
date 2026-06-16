import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/models/schedule.dart';

void main() {
  group('MedicationSchedule model', () {
    final now = DateTime.parse('2026-06-16T08:00:00.000');

    test('fromMap creates daily schedule correctly', () {
      final map = {
        'id': 'sch-001',
        'medicine_id': 'med-001',
        'medicine_name': '阿莫西林',
        'dosage': '1粒',
        'frequency': 'daily',
        'time_points': '08:00,20:00',
        'start_date': now.toIso8601String(),
        'end_date': null,
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      final s = MedicationSchedule.fromMap(map);
      expect(s.id, 'sch-001');
      expect(s.frequency, ScheduleFrequency.daily);
      expect(s.timePoints, ['08:00', '20:00']);
      expect(s.frequencyLabel, '每日');
      expect(s.isActive, true);
    });

    test('fromMap handles weekly schedule with weekDays', () {
      final map = {
        'id': 'sch-002',
        'medicine_id': 'med-001',
        'medicine_name': '二甲双胍',
        'dosage': '1片',
        'frequency': 'weekly',
        'time_points': '09:00',
        'week_days': '1,3,5',
        'start_date': now.toIso8601String(),
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      final s = MedicationSchedule.fromMap(map);
      expect(s.frequency, ScheduleFrequency.weekly);
      expect(s.weekDays, [1, 3, 5]);
      expect(s.frequencyLabel, '每周');
    });

    test('fromMap handles monthly schedule', () {
      final map = {
        'id': 'sch-003',
        'medicine_id': 'med-002',
        'medicine_name': '钙片',
        'dosage': '1片',
        'frequency': 'monthly',
        'time_points': '08:00',
        'month_days': '1,15',
        'start_date': now.toIso8601String(),
        'is_active': 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      final s = MedicationSchedule.fromMap(map);
      expect(s.frequency, ScheduleFrequency.monthly);
      expect(s.monthDays, [1, 15]);
      expect(s.isActive, false);
    });

    test('toMap produces correct map', () {
      final s = MedicationSchedule(
        id: 'sch-001',
        medicineId: 'med-001',
        medicineName: '阿莫西林',
        dosage: '1粒',
        frequency: ScheduleFrequency.daily,
        timePoints: ['08:00', '20:00'],
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final map = s.toMap();
      expect(map['time_points'], '08:00,20:00');
      expect(map['frequency'], 'daily');
      expect(map['is_active'], 1);
      expect(map['end_date'], null);
      expect(map['week_days'], null);
    });

    test('frequencyLabel returns correct labels', () {
      final daily = MedicationSchedule(
        id: 's1', medicineId: 'm1', medicineName: 'N/A',
        dosage: '1', frequency: ScheduleFrequency.daily,
        timePoints: ['08:00'], startDate: now,
        createdAt: now, updatedAt: now,
      );
      expect(daily.frequencyLabel, '每日');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/models/medicine.dart';
import 'package:medication_reminder/models/schedule.dart';
import 'package:medication_reminder/models/reminder.dart';

/// Comprehensive edge case tests for existing models
void main() {
  group('Medicine edge cases', () {
    test('notes is nullable - null handled correctly', () {
      final now = DateTime.now();
      final m = Medicine(
        id: 'm1', name: '测试', dosageForm: '片剂',
        specification: '100mg', createdAt: now, updatedAt: now,
      );
      expect(m.notes, isNull);
      expect(m.toMap()['notes'], isNull);
    });
    test('isActive defaults to true', () {
      final now = DateTime.now();
      final m = Medicine(id: 'm1', name: '测试', dosageForm: '片剂',
        specification: '100mg', createdAt: now, updatedAt: now);
      expect(m.isActive, true);
    });
    test('toMap converts isActive to int', () {
      final now = DateTime.now();
      final active = Medicine(id: 'a', name: 'a', dosageForm: '片剂',
        specification: '1', isActive: true, createdAt: now, updatedAt: now);
      final inactive = Medicine(id: 'b', name: 'b', dosageForm: '片剂',
        specification: '1', isActive: false, createdAt: now, updatedAt: now);
      expect(active.toMap()['is_active'], 1);
      expect(inactive.toMap()['is_active'], 0);
    });
    test('copyWith partial overwrite', () {
      final now = DateTime.now();
      final m = Medicine(id: 'm1', name: 'A', dosageForm: '片',
        specification: 'x', notes: 'n', colorValue: 1, isActive: true,
        createdAt: now, updatedAt: now);
      final c = m.copyWith(name: 'B', isActive: false);
      expect(c.name, 'B');
      expect(c.isActive, false);
      expect(c.notes, 'n');
      expect(c.colorValue, 1);
      expect(c.id, 'm1');
    });
  });

  group('MedicationSchedule edge cases', () {
    final now = DateTime.now();
    test('frequencyLabel for all enum values', () {
      MedicationSchedule s(ScheduleFrequency f, String id) =>
        MedicationSchedule(id: id, medicineId: 'm1', medicineName: '药',
          dosage: '1片', frequency: f, timePoints: ['08:00'],
          startDate: now, createdAt: now, updatedAt: now);
      expect(s(ScheduleFrequency.daily, '1').frequencyLabel, '每日');
      expect(s(ScheduleFrequency.weekly, '2').frequencyLabel, '每周');
      expect(s(ScheduleFrequency.monthly, '3').frequencyLabel, '每月');
      expect(s(ScheduleFrequency.prn, '4').frequencyLabel, '按需');
    });
    test('weekDays and monthDays nullable - null handled', () {
      final s = MedicationSchedule(
        id: 's1', medicineId: 'm1', medicineName: '药', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: now, createdAt: now, updatedAt: now,
      );
      expect(s.weekDays, isNull);
      expect(s.monthDays, isNull);
      final map = s.toMap();
      expect(map['week_days'], isNull);
      expect(map['month_days'], isNull);
    });
    test('toMap serializes timePoints as comma-joined string', () {
      final s = MedicationSchedule(
        id: 's1', medicineId: 'm1', medicineName: '药', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00', '12:00', '20:00'],
        startDate: now, createdAt: now, updatedAt: now,
      );
      expect(s.toMap()['time_points'], '08:00,12:00,20:00');
    });
    test('PRN fields serialize correctly', () {
      final s = MedicationSchedule(
        id: 's1', medicineId: 'm1', medicineName: '药', dosage: '1片',
        frequency: ScheduleFrequency.prn, timePoints: ['08:00'],
        prnMaxDaily: 3, prnMinIntervalMinutes: 240,
        startDate: now, createdAt: now, updatedAt: now,
      );
      expect(s.prnMaxDaily, 3);
      expect(s.prnMinIntervalMinutes, 240);
      expect(s.toMap()['prn_max_daily'], 3);
      expect(s.toMap()['prn_min_interval_minutes'], 240);
    });
    test('fromMap parses weekDays correctly', () {
      final s = MedicationSchedule.fromMap({
        'id': 's1', 'medicine_id': 'm1', 'medicine_name': '药',
        'dosage': '1片', 'frequency': 'weekly', 'time_points': '08:00',
        'week_days': '1,3,5', 'month_days': null,
        'start_date': now.toIso8601String(), 'end_date': null,
        'prn_max_daily': null, 'prn_min_interval_minutes': null,
        'is_active': 1, 'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      expect(s.weekDays, [1, 3, 5]);
      expect(s.monthDays, isNull);
    });
  });

  group('Reminder edge cases', () {
    final now = DateTime.now();
    test('statusLabel for all enum values', () {
      Reminder r(ReminderStatus s) => Reminder(
        id: 'r1', scheduleId: 's1', medicineName: '药', dosage: '1片',
        scheduledTime: now, status: s, createdAt: now);
      expect(r(ReminderStatus.pending).statusLabel, '待服');
      expect(r(ReminderStatus.taken).statusLabel, '已服');
      expect(r(ReminderStatus.skipped).statusLabel, '跳过');
      expect(r(ReminderStatus.missed).statusLabel, '漏服');
    });
    test('default status is pending', () {
      final r = Reminder(id: 'r1', scheduleId: 's1', medicineName: '药',
        dosage: '1片', scheduledTime: now, createdAt: now);
      expect(r.status, ReminderStatus.pending);
    });
    test('copyWith only overwrites given fields', () {
      final original = Reminder(
        id: 'r1', scheduleId: 's1', medicineName: '药', dosage: '1片',
        scheduledTime: now, createdAt: now);
      final taken = original.copyWith(status: ReminderStatus.taken, takenAt: now);
      expect(taken.status, ReminderStatus.taken);
      expect(taken.takenAt, now);
      expect(taken.id, original.id);
      expect(taken.medicineName, original.medicineName);
    });
    test('source is nullable and serialized correctly', () {
      final r = Reminder(id: 'r1', scheduleId: 's1', medicineName: '药',
        dosage: '1片', scheduledTime: now, source: 'notification', createdAt: now);
      expect(r.toMap()['source'], 'notification');
      final r2 = Reminder.fromMap(r.toMap());
      expect(r2.source, 'notification');
    });
  });
}

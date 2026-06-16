import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/models/reminder.dart';

void main() {
  group('Reminder model', () {
    final now = DateTime.parse('2026-06-16T08:00:00.000');
    final scheduled = DateTime.parse('2026-06-16T09:00:00.000');

    test('fromMap creates pending reminder', () {
      final map = {
        'id': 'rem-001',
        'schedule_id': 'sch-001',
        'medicine_name': '阿莫西林',
        'dosage': '1粒',
        'scheduled_time': scheduled.toIso8601String(),
        'status': 'pending',
        'source': null,
        'taken_at': null,
        'created_at': now.toIso8601String(),
      };
      final r = Reminder.fromMap(map);
      expect(r.id, 'rem-001');
      expect(r.status, ReminderStatus.pending);
      expect(r.statusLabel, '待服');
      expect(r.takenAt, null);
    });

    test('fromMap creates taken reminder with taken_at', () {
      final takenAt = DateTime.parse('2026-06-16T09:05:00.000');
      final map = {
        'id': 'rem-002',
        'schedule_id': 'sch-001',
        'medicine_name': '阿莫西林',
        'dosage': '1粒',
        'scheduled_time': scheduled.toIso8601String(),
        'status': 'taken',
        'source': 'notification',
        'taken_at': takenAt.toIso8601String(),
        'created_at': now.toIso8601String(),
      };
      final r = Reminder.fromMap(map);
      expect(r.status, ReminderStatus.taken);
      expect(r.statusLabel, '已服');
      expect(r.source, 'notification');
      expect(r.takenAt, takenAt);
    });

    test('statusLabel returns correct labels', () {
      final pending = Reminder(
        id: '1', scheduleId: 's1', medicineName: 'N/A',
        dosage: '1', scheduledTime: scheduled, createdAt: now,
      );
      expect(pending.statusLabel, '待服');
      
      final skipped = pending.copyWith(status: ReminderStatus.skipped);
      expect(skipped.statusLabel, '跳过');
      
      final missed = pending.copyWith(status: ReminderStatus.missed);
      expect(missed.statusLabel, '漏服');
      
      final taken = pending.copyWith(status: ReminderStatus.taken, takenAt: now);
      expect(taken.statusLabel, '已服');
      expect(taken.takenAt, now);
    });

    test('toMap produces correct map', () {
      final r = Reminder(
        id: 'rem-001', scheduleId: 'sch-001',
        medicineName: '阿莫西林', dosage: '1粒',
        scheduledTime: scheduled, createdAt: now,
      );
      final map = r.toMap();
      expect(map['status'], 'pending');
      expect(map['source'], null);
      expect(map['taken_at'], null);
    });
  });
}

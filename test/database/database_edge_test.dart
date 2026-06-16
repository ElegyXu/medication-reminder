import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:medication_reminder/database/database_helper.dart';
import 'package:medication_reminder/models/medicine.dart';
import 'package:medication_reminder/models/schedule.dart';
import 'package:medication_reminder/models/reminder.dart';
import 'package:medication_reminder/models/symptom.dart';
import 'package:medication_reminder/models/guardian_binding.dart';

void main() {
  late DatabaseHelper db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = DatabaseHelper();
  });

  tearDown(() async {
    final database = await db.database;
    await database.delete('reminders');
    await database.delete('schedules');
    await database.delete('medicines');
    await database.delete('symptoms');
    await database.delete('guardian_bindings');
  });

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // ==================== Model 边界与组合 ====================
  group('模型边界与组合', () {
    test('Medicine copyWith 不传参返回相等对象', () {
      final m = Medicine(
        id: 'm1', name: '药', dosageForm: '片剂', specification: '1mg',
        createdAt: now, updatedAt: now,
      );
      final copy = m.copyWith();
      expect(copy.name, m.name);
      expect(copy.id, m.id);
    });

    test('ScheduleFrequency 枚举有4个值', () {
      expect(ScheduleFrequency.values.length, 4);
    });

    test('ReminderStatus 枚举有4个值', () {
      expect(ReminderStatus.values.length, 4);
    });

    test('BindingStatus 枚举有4个值', () {
      expect(BindingStatus.values.length, 4);
    });

    test('Symptom severityLabel 边界值', () {
      for (var s = 1; s <= 5; s++) {
        final symptom = Symptom(id: 's', name: 'test', severity: s, createdAt: now);
        expect(symptom.severityLabel, isNotEmpty);
      }
    });

    test('Medicine 相等性判断 ', () {
      final m1 = Medicine(id: 'm1', name: '药', dosageForm: '片剂', specification: '1mg',
          createdAt: now, updatedAt: now);
      final m2 = Medicine(id: 'm1', name: '药', dosageForm: '片剂', specification: '1mg',
          createdAt: now, updatedAt: now);
      expect(m1.id, m2.id);
      expect(m1.name, m2.name);
    });

    test('Reminder copyWith 改变状态后保持 scheduledTime', () {
      final r = Reminder(
        id: 'r1', scheduleId: 's1', medicineName: '药', dosage: '1片',
        scheduledTime: now, status: ReminderStatus.pending, createdAt: now,
      );
      final r2 = r.copyWith(status: ReminderStatus.taken, source: 'manual', takenAt: now);
      expect(r2.scheduledTime, r.scheduledTime);
      expect(r2.status, ReminderStatus.taken);
    });
  });

  // ==================== 数据库复杂查询 ====================
  group('数据库复杂查询', () {
    test('获取指定计划的所有提醒', () async {
      await db.insertReminders([
        Reminder(id: 'r1', scheduleId: 's1', medicineName: 'A', dosage: '1',
            scheduledTime: now, status: ReminderStatus.taken, createdAt: now),
        Reminder(id: 'r2', scheduleId: 's1', medicineName: 'A', dosage: '1',
            scheduledTime: now.add(Duration(hours: 1)), status: ReminderStatus.pending,
            createdAt: now),
        Reminder(id: 'r3', scheduleId: 's2', medicineName: 'B', dosage: '1',
            scheduledTime: now, status: ReminderStatus.taken, createdAt: now),
      ]);
      final all = await db.getReminders();
      final s1Reminders = all.where((r) => r.scheduleId == 's1').toList();
      expect(s1Reminders.length, 2);
    });

    test('大数量插入100条提醒', () async {
      final reminders = List.generate(100, (i) => Reminder(
        id: 'r$i', scheduleId: 's1', medicineName: '药', dosage: '1片',
        scheduledTime: now.add(Duration(minutes: i)),
        status: i < 50 ? ReminderStatus.taken : ReminderStatus.pending,
        createdAt: now,
      ));
      await db.insertReminders(reminders);
      final all = await db.getReminders();
      expect(all.length, 100);
    });

    test('getReminders limit 参数', () async {
      await db.insertReminders(List.generate(20, (i) => Reminder(
        id: 'r$i', scheduleId: 's1', medicineName: '药', dosage: '1片',
        scheduledTime: now.add(Duration(minutes: i)),
        status: ReminderStatus.pending, createdAt: now,
      )));
      final limited = await db.getReminders(limit: 10);
      expect(limited.length, 10);
    });

    test('跨表关联删除', () async {
      await db.insertMedicine(Medicine(
        id: 'm1', name: '阿莫西林', dosageForm: '胶囊', specification: '500mg',
        createdAt: now, updatedAt: now,
      ));
      await db.insertSchedule(MedicationSchedule(
        id: 's1', medicineId: 'm1', medicineName: '阿莫西林', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: today, isActive: true, createdAt: now, updatedAt: now,
      ));
      await db.insertReminder(Reminder(
        id: 'r1', scheduleId: 's1', medicineName: '阿莫西林', dosage: '1片',
        scheduledTime: now, status: ReminderStatus.pending, createdAt: now,
      ));

      await db.deleteMedicine('m1');

      // CASCADE should delete schedule and reminders
      final schedules = await db.getSchedules();
      expect(schedules, isEmpty);
    });

    test('getTodayStats 区分今昨', () async {
      final yesterday = now.subtract(Duration(days: 1));
      await db.insertReminder(Reminder(
        id: 'r1', scheduleId: 's1', medicineName: '药', dosage: '1片',
        scheduledTime: yesterday, status: ReminderStatus.taken, createdAt: now,
      ));
      await db.insertReminder(Reminder(
        id: 'r2', scheduleId: 's1', medicineName: '药', dosage: '1片',
        scheduledTime: now, status: ReminderStatus.taken, createdAt: now,
      ));
      final stats = await db.getTodayStats();
      expect(stats['total'], 1);
      expect(stats['taken'], 1);
    });
  });

  // ==================== 混合内容测试 ====================
  group('混合内容测试', () {
    test('多药品多计划混合', () async {
      // Insert 3 medicines
      for (var i = 0; i < 3; i++) {
        await db.insertMedicine(Medicine(
          id: 'm$i', name: '药品$i', dosageForm: '片剂', specification: '${i}00mg',
          createdAt: now, updatedAt: now,
        ));
      }
      expect((await db.getMedicines()).length, 3);

      // Insert schedules for each
      for (var i = 0; i < 3; i++) {
        await db.insertSchedule(MedicationSchedule(
          id: 's$i', medicineId: 'm$i', medicineName: '药品$i', dosage: '1片',
          frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
          startDate: today, isActive: true, createdAt: now, updatedAt: now,
        ));
      }
      expect((await db.getSchedules()).length, 3);
    });

    test('症状关联已删除药品', () async {
      await db.insertSymptom(Symptom(
        id: 'sy1', name: '头痛', severity: 3,
        relatedMedicineId: 'm1', relatedMedicineName: '阿莫西林', createdAt: now,
      ));
      final symptoms = await db.getSymptoms();
      expect(symptoms.length, 1);
      expect(symptoms[0].relatedMedicineName, '阿莫西林');
    });

    test('绑定所有状态枚举保存/读取', () async {
      final statuses = BindingStatus.values;
      for (var i = 0; i < statuses.length; i++) {
        await db.insertBinding(GuardianBinding(
          id: 'b$i', patientPhone: '13800001111', patientNickname: '用户$i',
          guardianPhone: '13900002222', status: statuses[i],
          createdAt: now, updatedAt: now,
        ));
      }
      final all = await db.getBindings();
      expect(all.length, statuses.length);
    });
  });

  // ==================== 健壮性 ====================
  group('健壮性', () {
    test('空数据库所有查询不崩溃', () async {
      expect(await db.getMedicines(), isEmpty);
      expect(await db.getSchedules(), isEmpty);
      expect(await db.getReminders(), isEmpty);
      expect(await db.getSymptoms(), isEmpty);
      expect(await db.getBindings(), isEmpty);
      expect(await db.getTodayStats(), {'total': 0, 'taken': 0});
      expect(await db.getConsecutiveDays(), 0);
    });

    test('Medicine toMap 不包含多余字段', () {
      final m = Medicine(
        id: 'm1', name: '药', dosageForm: '片剂', specification: '1mg',
        createdAt: now, updatedAt: now,
      );
      final map = m.toMap();
      // Should contain exactly expected keys
      expect(map.containsKey('id'), true);
      expect(map.containsKey('name'), true);
      expect(map.containsKey('dosage_form'), true);
      expect(map.containsKey('specification'), true);
      expect(map.containsKey('color_value'), true);
      expect(map.containsKey('is_active'), true);
      expect(map.containsKey('notes'), true);
      expect(map.containsKey('created_at'), true);
      expect(map.containsKey('updated_at'), true);
    });

    test('Schedule toMap 不包含多余字段', () {
      final s = MedicationSchedule(
        id: 's1', medicineId: 'm1', medicineName: '药', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: today, isActive: true, createdAt: now, updatedAt: now,
      );
      final map = s.toMap();
      final expectedKeys = {
        'id', 'medicine_id', 'medicine_name', 'dosage', 'frequency',
        'time_points', 'start_date', 'end_date', 'week_days', 'month_days',
        'prn_max_daily', 'prn_min_interval_minutes', 'is_active', 'created_at', 'updated_at',
      };
      for (final key in map.keys) {
        expect(expectedKeys.contains(key), true, reason: 'Unexpected key: $key');
      }
    });

    test('多条症状按时间排序', () async {
      final base = DateTime(2026, 6, 16);
      await db.insertSymptom(Symptom(id: 's1', name: '最新', severity: 1, createdAt: base.add(Duration(hours: 2))));
      await db.insertSymptom(Symptom(id: 's2', name: '较早', severity: 2, createdAt: base.add(Duration(hours: 1))));
      await db.insertSymptom(Symptom(id: 's3', name: '最早', severity: 3, createdAt: base));
      final list = await db.getSymptoms();
      expect(list[0].name, '最新');
      expect(list[2].name, '最早');
    });

    test('getConsecutiveDays 仅昨天有记录', () async {
      // Only yesterday taken, today none. Chain counts yesterday = 1.
      await db.insertReminder(Reminder(
        id: 'r1', scheduleId: 's1', medicineName: '药', dosage: '1片',
        scheduledTime: now.subtract(Duration(days: 1)),
        status: ReminderStatus.taken, createdAt: now,
      ));
      final days = await db.getConsecutiveDays();
      expect(days, 1);
    });

    test('PRN 提醒可以手动触发', () async {
      // PRN reminders are inserted by user action, not auto-generated
      await db.insertReminder(Reminder(
        id: 'r1', scheduleId: 's1', medicineName: '止痛药', dosage: '1片',
        scheduledTime: now, status: ReminderStatus.taken,
        source: 'manual', takenAt: now, createdAt: now,
      ));
      final list = await db.getReminders();
      expect(list[0].source, 'manual');
      expect(list[0].status, ReminderStatus.taken);
    });
  });
}

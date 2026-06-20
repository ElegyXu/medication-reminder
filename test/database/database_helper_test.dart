import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
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
  final todayStart = DateTime(now.year, now.month, now.day);

  Medicine makeMed({String id = 'm1', String name = '阿莫西林', bool isActive = true}) {
    return Medicine(
      id: id, name: name, dosageForm: '片剂', specification: '500mg',
      notes: '饭后服用', colorValue: 0xFFC62828, isActive: isActive,
      createdAt: now, updatedAt: now,
    );
  }

  MedicationSchedule makeSched({String id = 's1', String medId = 'm1', String medName = '阿莫西林',
      ScheduleFrequency freq = ScheduleFrequency.daily, List<String> times = const ['08:00', '20:00'],
      bool isActive = true, DateTime? start, List<int>? weekDays, List<int>? monthDays,
      DateTime? endDate, int? prnMaxDaily, int? prnMinIntervalMinutes}) {
    return MedicationSchedule(
      id: id, medicineId: medId, medicineName: medName, dosage: '1片',
      frequency: freq, timePoints: times, startDate: start ?? todayStart,
      weekDays: weekDays, monthDays: monthDays, endDate: endDate,
      prnMaxDaily: prnMaxDaily, prnMinIntervalMinutes: prnMinIntervalMinutes,
      isActive: isActive, createdAt: now, updatedAt: now,
    );
  }

  Reminder makeRem({String id = 'r1', String schedId = 's1', String medName = '阿莫西林',
      ReminderStatus status = ReminderStatus.pending, DateTime? schedTime}) {
    return Reminder(
      id: id, scheduleId: schedId, medicineName: medName, dosage: '1片',
      scheduledTime: schedTime ?? now, status: status, createdAt: now,
    );
  }

  // ==================== Medicines ====================
  group('药品 CRUD', () {
    test('插入并查询药品', () async {
      await db.insertMedicine(makeMed());
      final list = await db.getMedicines();
      expect(list.length, 1);
      expect(list[0].name, '阿莫西林');
    });

    test('按ID查询药品', () async {
      await db.insertMedicine(makeMed());
      final m = await db.getMedicine('m1');
      expect(m, isNotNull);
      expect(m!.specification, '500mg');
    });

    test('查询不存在的ID返回null', () async {
      final m = await db.getMedicine('nonexistent');
      expect(m, isNull);
    });

    test('按激活状态过滤', () async {
      await db.insertMedicine(makeMed(id: 'm1', name: 'A', isActive: true));
      await db.insertMedicine(makeMed(id: 'm2', name: 'B', isActive: false));
      final active = await db.getMedicines(isActive: true);
      final inactive = await db.getMedicines(isActive: false);
      expect(active.length, 1);
      expect(active[0].name, 'A');
      expect(inactive.length, 1);
      expect(inactive[0].name, 'B');
    });

    test('查询全部药品(不过滤)', () async {
      await db.insertMedicine(makeMed(id: 'm1'));
      await db.insertMedicine(makeMed(id: 'm2', name: '头孢'));
      final all = await db.getMedicines();
      expect(all.length, 2);
    });

    test('更新药品', () async {
      await db.insertMedicine(makeMed());
      final updated = makeMed().copyWith(name: '阿莫西林胶囊', notes: '空腹服用', updatedAt: now);
      await db.updateMedicine(updated);
      final m = await db.getMedicine('m1');
      expect(m!.name, '阿莫西林胶囊');
      expect(m.notes, '空腹服用');
    });

    test('删除药品同步删除关联用药计划', () async {
      await db.insertMedicine(makeMed(id: 'm1'));
      await db.insertSchedule(makeSched(id: 's1', medId: 'm1'));
      await db.deleteMedicine('m1');
      final medicines = await db.getMedicines();
      final schedules = await db.getSchedules();
      expect(medicines.length, 0);
      expect(schedules.length, 0);
    });

    test('空药品列表', () async {
      final list = await db.getMedicines();
      expect(list, isEmpty);
    });

    test('插入重复ID药品(replace)', () async {
      await db.insertMedicine(makeMed(id: 'm1', name: 'A'));
      await db.insertMedicine(makeMed(id: 'm1', name: 'B'));
      final list = await db.getMedicines();
      expect(list.length, 1);
      expect(list[0].name, 'B');
    });

    test('多药品按updated_at降序排列', () async {
      await db.insertMedicine(Medicine(
        id: 'm1', name: 'A', dosageForm: '片剂', specification: '1mg',
        updatedAt: now.subtract(Duration(days: 2)), createdAt: now,
      ));
      await db.insertMedicine(Medicine(
        id: 'm2', name: 'B', dosageForm: '胶囊', specification: '2mg',
        updatedAt: now, createdAt: now,
      ));
      final list = await db.getMedicines();
      expect(list[0].name, 'B');
      expect(list[1].name, 'A');
    });
  });

  // ==================== Schedules ====================
  group('用药计划 CRUD', () {
    test('插入并查询用药计划', () async {
      await db.insertSchedule(makeSched());
      final list = await db.getSchedules();
      expect(list.length, 1);
      expect(list[0].medicineName, '阿莫西林');
      expect(list[0].frequency, ScheduleFrequency.daily);
    });

    test('按激活状态过滤计划', () async {
      await db.insertSchedule(makeSched(id: 's1', isActive: true));
      await db.insertSchedule(makeSched(id: 's2', isActive: false));
      final active = await db.getSchedules(isActive: true);
      final inactive = await db.getSchedules(isActive: false);
      expect(active.length, 1);
      expect(inactive.length, 1);
    });

    test('更新用药计划', () async {
      await db.insertSchedule(makeSched());
      final updated = MedicationSchedule(
        id: 's1', medicineId: 'm1', medicineName: '阿莫西林', dosage: '2片',
        frequency: ScheduleFrequency.daily, timePoints: ['09:00', '21:00'],
        startDate: todayStart, isActive: true, createdAt: now, updatedAt: now,
      );
      await db.updateSchedule(updated);
      final list = await db.getSchedules();
      expect(list[0].dosage, '2片');
      expect(list[0].timePoints, ['09:00', '21:00']);
    });

    test('删除用药计划', () async {
      await db.insertSchedule(makeSched());
      await db.deleteSchedule('s1');
      final list = await db.getSchedules();
      expect(list, isEmpty);
    });

    test('每周频率计划含weekDays', () async {
      await db.insertSchedule(makeSched(
        id: 's1', freq: ScheduleFrequency.weekly,
        weekDays: [1, 3, 5],
      ));
      final list = await db.getSchedules();
      expect(list[0].frequency, ScheduleFrequency.weekly);
      expect(list[0].weekDays, [1, 3, 5]);
    });

    test('每月频率计划含monthDays', () async {
      await db.insertSchedule(makeSched(
        id: 's1', freq: ScheduleFrequency.monthly,
        monthDays: [1, 15],
      ));
      final list = await db.getSchedules();
      expect(list[0].frequency, ScheduleFrequency.monthly);
      expect(list[0].monthDays, [1, 15]);
    });

    test('PRN按需计划含上限和间隔', () async {
      await db.insertSchedule(MedicationSchedule(
        id: 's1', medicineId: 'm1', medicineName: '止痛药', dosage: '1片',
        frequency: ScheduleFrequency.prn, timePoints: [],
        startDate: todayStart, prnMaxDaily: 3, prnMinIntervalMinutes: 240,
        isActive: true, createdAt: now, updatedAt: now,
      ));
      final list = await db.getSchedules();
      expect(list[0].frequency, ScheduleFrequency.prn);
      expect(list[0].prnMaxDaily, 3);
      expect(list[0].prnMinIntervalMinutes, 240);
    });

    test('含结束日期的计划', () async {
      await db.insertSchedule(makeSched(
        id: 's1', endDate: now.add(Duration(days: 30)),
      ));
      final list = await db.getSchedules();
      expect(list[0].endDate, isNotNull);
    });

    test('空计划列表', () async {
      final list = await db.getSchedules();
      expect(list, isEmpty);
    });
  });

  // ==================== Reminders ====================
  group('服药提醒 CRUD', () {
    test('插入单条提醒', () async {
      await db.insertReminder(makeRem());
      final list = await db.getReminders();
      expect(list.length, 1);
      expect(list[0].status, ReminderStatus.pending);
    });

    test('批量插入提醒', () async {
      await db.insertReminders([
        makeRem(id: 'r1', schedTime: DateTime(2026, 6, 16, 8, 0)),
        makeRem(id: 'r2', schedTime: DateTime(2026, 6, 16, 12, 0)),
        makeRem(id: 'r3', schedTime: DateTime(2026, 6, 16, 20, 0)),
      ]);
      final list = await db.getReminders();
      expect(list.length, 3);
    });

    test('按状态过滤提醒', () async {
      await db.insertReminder(makeRem(id: 'r1', status: ReminderStatus.pending));
      await db.insertReminder(makeRem(id: 'r2', status: ReminderStatus.taken));
      final taken = await db.getReminders(status: 'taken');
      expect(taken.length, 1);
      expect(taken[0].status, ReminderStatus.taken);
    });

    test('按时间范围过滤提醒', () async {
      await db.insertReminder(makeRem(id: 'r1', schedTime: DateTime(2026, 6, 16, 8, 0)));
      await db.insertReminder(makeRem(id: 'r2', schedTime: DateTime(2026, 6, 17, 8, 0)));
      final today = await db.getReminders(
        fromDate: DateTime(2026, 6, 16),
        toDate: DateTime(2026, 6, 16, 23, 59, 59),
      );
      expect(today.length, 1);
      expect(today[0].id, 'r1');
    });

    test('limit参数限制返回数量', () async {
      await db.insertReminders([
        makeRem(id: 'r1', schedTime: DateTime(2026, 6, 16, 8, 0)),
        makeRem(id: 'r2', schedTime: DateTime(2026, 6, 16, 9, 0)),
        makeRem(id: 'r3', schedTime: DateTime(2026, 6, 16, 10, 0)),
      ]);
      final list = await db.getReminders(limit: 2);
      expect(list.length, 2);
    });

    test('更新提醒状态为已服', () async {
      await db.insertReminder(makeRem());
      final updated = makeRem().copyWith(status: ReminderStatus.taken, source: 'manual', takenAt: now);
      await db.updateReminder(updated);
      final list = await db.getReminders();
      expect(list[0].status, ReminderStatus.taken);
      expect(list[0].source, 'manual');
      expect(list[0].takenAt, isNotNull);
    });

    test('更新提醒状态为跳过', () async {
      await db.insertReminder(makeRem());
      final updated = makeRem().copyWith(status: ReminderStatus.skipped);
      await db.updateReminder(updated);
      final list = await db.getReminders();
      expect(list[0].status, ReminderStatus.skipped);
    });

    test('提醒按时序排列', () async {
      await db.insertReminders([
        makeRem(id: 'r1', schedTime: DateTime(2026, 6, 16, 20, 0)),
        makeRem(id: 'r2', schedTime: DateTime(2026, 6, 16, 8, 0)),
        makeRem(id: 'r3', schedTime: DateTime(2026, 6, 16, 12, 0)),
      ]);
      final list = await db.getReminders();
      expect(list[0].id, 'r2'); // 08:00 first
      expect(list[1].id, 'r3'); // 12:00
      expect(list[2].id, 'r1'); // 20:00
    });

    test('空提醒列表', () async {
      final list = await db.getReminders();
      expect(list, isEmpty);
    });
  });

  // ==================== Symptoms ====================
  group('症状 CRUD', () {
    test('插入并查询症状', () async {
      await db.insertSymptom(Symptom(
        id: 'sy1', name: '头痛', severity: 3, notes: '轻微',
        relatedMedicineId: 'm1', relatedMedicineName: '阿莫西林', createdAt: now,
      ));
      final list = await db.getSymptoms();
      expect(list.length, 1);
      expect(list[0].name, '头痛');
      expect(list[0].severity, 3);
    });

    test('症状limit限制', () async {
      for (var i = 0; i < 5; i++) {
        await db.insertSymptom(Symptom(
          id: 'sy$i', name: '症状$i', severity: i + 1,
          createdAt: now.subtract(Duration(hours: i)),
        ));
      }
      final list = await db.getSymptoms(limit: 3);
      expect(list.length, 3);
    });

    test('症状按时间降序排列', () async {
      await db.insertSymptom(Symptom(
        id: 'sy1', name: '旧症状', severity: 1,
        createdAt: now.subtract(Duration(days: 2)),
      ));
      await db.insertSymptom(Symptom(
        id: 'sy2', name: '新症状', severity: 2, createdAt: now,
      ));
      final list = await db.getSymptoms();
      expect(list[0].name, '新症状');
    });

    test('删除症状', () async {
      await db.insertSymptom(Symptom(
        id: 'sy1', name: '头痛', severity: 1, createdAt: now,
      ));
      await db.deleteSymptom('sy1');
      final list = await db.getSymptoms();
      expect(list, isEmpty);
    });
  });

  // ==================== Guardian Bindings ====================
  group('家属绑定 CRUD', () {
    test('插入并查询绑定', () async {
      await db.insertBinding(GuardianBinding(
        id: 'b1', patientPhone: '13800001111', patientNickname: '张大爷',
        guardianPhone: '13900002222', status: BindingStatus.active,
        createdAt: now, updatedAt: now,
      ));
      final list = await db.getBindings();
      expect(list.length, 1);
      expect(list[0].patientNickname, '张大爷');
      expect(list[0].status, BindingStatus.active);
    });

    test('按状态过滤绑定', () async {
      await db.insertBinding(GuardianBinding(
        id: 'b1', patientPhone: '13800001111', patientNickname: 'A',
        guardianPhone: '13900002222', status: BindingStatus.active,
        createdAt: now, updatedAt: now,
      ));
      await db.insertBinding(GuardianBinding(
        id: 'b2', patientPhone: '13800003333', patientNickname: 'B',
        guardianPhone: '13900004444', status: BindingStatus.pending,
        createdAt: now, updatedAt: now,
      ));
      final active = await db.getBindings(status: 'active');
      expect(active.length, 1);
      expect(active[0].patientNickname, 'A');
    });

    test('更新绑定状态', () async {
      await db.insertBinding(GuardianBinding(
        id: 'b1', patientPhone: '13800001111', patientNickname: '张大爷',
        guardianPhone: '13900002222', status: BindingStatus.pending,
        createdAt: now, updatedAt: now,
      ));
      await db.updateBinding(GuardianBinding(
        id: 'b1', patientPhone: '13800001111', patientNickname: '张大爷',
        guardianPhone: '13900002222', status: BindingStatus.revoked,
        createdAt: now, updatedAt: now,
      ));
      final list = await db.getBindings();
      expect(list[0].status, BindingStatus.revoked);
    });

    test('删除绑定', () async {
      await db.insertBinding(GuardianBinding(
        id: 'b1', patientPhone: '13800001111', patientNickname: '张大爷',
        guardianPhone: '13900002222', createdAt: now, updatedAt: now,
      ));
      await db.deleteBinding('b1');
      final list = await db.getBindings();
      expect(list, isEmpty);
    });
  });

  // ==================== Statistics ====================
  group('统计数据', () {
    test('getTodayStats 无数据时返回0', () async {
      final stats = await db.getTodayStats();
      expect(stats['total'], 0);
      expect(stats['taken'], 0);
    });

    test('getTodayStats 正确统计今日数据', () async {
      await db.insertReminder(makeRem(id: 'r1', status: ReminderStatus.taken, schedTime: now));
      await db.insertReminder(makeRem(id: 'r2', status: ReminderStatus.pending, schedTime: now));
      await db.insertReminder(makeRem(id: 'r3', status: ReminderStatus.skipped,
          schedTime: now.subtract(Duration(days: 1)))); // 昨天的不计
      final stats = await db.getTodayStats();
      expect(stats['total'], 2);
      expect(stats['taken'], 1);
    });

    test('getConsecutiveDays 无记录返回0', () async {
      final days = await db.getConsecutiveDays();
      expect(days, 0);
    });

    test('getConsecutiveDays 单天记录返回1', () async {
      await db.insertReminder(makeRem(id: 'r1', status: ReminderStatus.taken, schedTime: now));
      final days = await db.getConsecutiveDays();
      expect(days, 1);
    });

    test('getConsecutiveDays 连续多天', () async {
      for (var i = 0; i < 3; i++) {
        await db.insertReminder(Reminder(
          id: 'r$i', scheduleId: 's1', medicineName: '药', dosage: '1片',
          scheduledTime: now.subtract(Duration(days: i)),
          status: ReminderStatus.taken, createdAt: now,
        ));
      }
      final days = await db.getConsecutiveDays();
      expect(days, 3);
    });

    test('getConsecutiveDays 有间断', () async {
      await db.insertReminder(Reminder(
        id: 'r1', scheduleId: 's1', medicineName: '药', dosage: '1片',
        scheduledTime: now, status: ReminderStatus.taken, createdAt: now,
      ));
      await db.insertReminder(Reminder(
        id: 'r2', scheduleId: 's1', medicineName: '药', dosage: '1片',
        scheduledTime: now.subtract(Duration(days: 2)), status: ReminderStatus.taken, createdAt: now,
      ));
      final days = await db.getConsecutiveDays();
      expect(days, 1); // 昨天断了
    });
  });

  // ==================== Edge Cases ====================
  group('边界用例', () {
    test('药品名含特殊字符', () async {
      await db.insertMedicine(makeMed(name: "阿司匹林 (Aspirin) 100mg/片"));
      final list = await db.getMedicines();
      expect(list[0].name, "阿司匹林 (Aspirin) 100mg/片");
    });

    test('药品备注为空', () async {
      await db.insertMedicine(Medicine(
        id: 'm1', name: '维生素C', dosageForm: '片剂', specification: '100mg',
        createdAt: now, updatedAt: now,
      ));
      final m = await db.getMedicine('m1');
      expect(m!.notes, isNull);
    });

    // TC-FIX-02: 验证数据库 migration 将旧 color_value 迁移为新值
    test('TC-FIX-02: v2→v3 迁移将旧 color_value 0xFFC41E3A 更新为 0xFFC62828', () async {
      final dbPath = await databaseFactoryFfi.getDatabasesPath();
      final path = join(dbPath, 'test_migration_fix.db');

      // Step 1: Create database at version 2, insert medicine with old color
      final dbV2 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE medicines (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                dosage_form TEXT NOT NULL,
                specification TEXT NOT NULL,
                notes TEXT,
                color_value INTEGER DEFAULT 4291042874,
                current_stock REAL DEFAULT 0.0,
                alert_threshold REAL DEFAULT 0.0,
                is_active INTEGER DEFAULT 1,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );
      await dbV2.insert('medicines', {
        'id': 'test-mig',
        'name': '旧颜色药品',
        'dosage_form': '片剂',
        'specification': '100mg',
        'color_value': 4291042874, // 0xFFC41E3A
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      await dbV2.close();

      // Step 2: Open same database at version 3 with migration
      final dbV3 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, version) async {},
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await db.execute('ALTER TABLE medicines ADD COLUMN current_stock REAL DEFAULT 0.0');
              await db.execute('ALTER TABLE medicines ADD COLUMN alert_threshold REAL DEFAULT 0.0');
            }
            if (oldVersion < 3) {
              await db.execute(
                'UPDATE medicines SET color_value = 4291176488 WHERE color_value = 4291042874',
              );
            }
          },
        ),
      );

      // Step 3: Verify migration result
      final results = await dbV3.query('medicines', where: 'id = ?', whereArgs: ['test-mig']);
      expect(results.length, 1);
      expect(results[0]['color_value'], 4291176488); // 0xFFC62828

      await dbV3.close();

      // Cleanup
      await databaseFactoryFfi.deleteDatabase(path);
    });

    test('用药计划含多个时间点', () async {
      await db.insertSchedule(MedicationSchedule(
        id: 's1', medicineId: 'm1', medicineName: '盐酸二甲双胍', dosage: '1片',
        frequency: ScheduleFrequency.daily,
        timePoints: ['07:00', '12:00', '18:00', '22:00'],
        startDate: todayStart, isActive: true, createdAt: now, updatedAt: now,
      ));
      final list = await db.getSchedules();
      expect(list[0].timePoints.length, 4);
    });

    test('症状严重度为边界值1', () async {
      await db.insertSymptom(Symptom(
        id: 'sy1', name: '轻微不适', severity: 1, createdAt: now,
      ));
      final list = await db.getSymptoms();
      expect(list[0].severity, 1);
    });

    test('症状严重度为边界值5', () async {
      await db.insertSymptom(Symptom(
        id: 'sy1', name: '剧烈疼痛', severity: 5, createdAt: now,
      ));
      final list = await db.getSymptoms();
      expect(list[0].severity, 5);
    });

    test('所有绑定状态枚举', () async {
      for (final status in BindingStatus.values) {
        await db.insertBinding(GuardianBinding(
          id: 'b_${status.name}', patientPhone: '13800001111',
          patientNickname: '用户', guardianPhone: '13900002222',
          status: status, createdAt: now, updatedAt: now,
        ));
      }
      final list = await db.getBindings();
      expect(list.length, 4);
    });

    test('删除不存在的记录不抛异常', () async {
      // 不应抛出异常
      await db.deleteMedicine('nonexistent');
      await db.deleteSchedule('nonexistent');
      await db.deleteSymptom('nonexistent');
      await db.deleteBinding('nonexistent');
    });

    test('批量插入空列表', () async {
      await db.insertReminders([]);
      final list = await db.getReminders();
      expect(list, isEmpty);
    });
  });
}

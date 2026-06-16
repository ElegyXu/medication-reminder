import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:medication_reminder/database/database_helper.dart';
import 'package:medication_reminder/models/schedule.dart';
import 'package:medication_reminder/models/reminder.dart';
import 'package:medication_reminder/providers/medicine_provider.dart';
import 'package:medication_reminder/providers/schedule_provider.dart';
import 'package:medication_reminder/providers/reminder_provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  late MedicineProvider medicineProvider;
  late ScheduleProvider scheduleProvider;
  late ReminderProvider reminderProvider;
  late DatabaseHelper db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tz_data.initializeTimeZones();
    db = DatabaseHelper();
  });

  setUp(() async {
    // Clean database before each test
    final database = await db.database;
    await database.delete('reminders');
    await database.delete('schedules');
    await database.delete('medicines');
    medicineProvider = MedicineProvider();
    scheduleProvider = ScheduleProvider();
    reminderProvider = ReminderProvider();
  });

  tearDown(() async {
    final database = await db.database;
    await database.delete('reminders');
    await database.delete('schedules');
    await database.delete('medicines');
  });

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  group('MedicineProvider 边界', () {
    test('并发添加多个药品', () async {
      await Future.wait([
        medicineProvider.addMedicine(name: 'A药', dosageForm: '片剂', specification: '1mg'),
        medicineProvider.addMedicine(name: 'B药', dosageForm: '胶囊', specification: '2mg'),
        medicineProvider.addMedicine(name: 'C药', dosageForm: '冲剂', specification: '3g'),
      ]);
      expect(medicineProvider.medicines.length, 3);
    });

    test('删除后重新添加同名药品', () async {
      await medicineProvider.addMedicine(name: '阿莫西林', dosageForm: '胶囊', specification: '500mg');
      final oldId = medicineProvider.medicines[0].id;
      await medicineProvider.removeMedicine(oldId);
      await medicineProvider.addMedicine(name: '阿莫西林', dosageForm: '胶囊', specification: '500mg');
      expect(medicineProvider.medicines[0].name, '阿莫西林');
      expect(medicineProvider.medicines[0].id, isNot(oldId));
    });

    test('切换两次激活状态回到原位', () async {
      await medicineProvider.addMedicine(name: '阿莫西林', dosageForm: '胶囊', specification: '500mg');
      final med = medicineProvider.medicines[0];
      await medicineProvider.toggleMedicineActive(med);
      await medicineProvider.toggleMedicineActive(medicineProvider.medicines[0]);
      expect(medicineProvider.medicines[0].isActive, true);
    });

    test('空药品列表 activeMedicines 也为空', () {
      expect(medicineProvider.activeMedicines, isEmpty);
    });

    test('isLoading 状态切换', () async {
      // After add, isLoading should be false
      await medicineProvider.addMedicine(name: '测试', dosageForm: '片剂', specification: '1mg');
      expect(medicineProvider.isLoading, false);
    });

    test('addMedicine 后 medicines 和 activeMedicines 同步更新', () async {
      await medicineProvider.addMedicine(name: '测试', dosageForm: '片剂', specification: '1mg');
      expect(medicineProvider.medicines.length, medicineProvider.activeMedicines.length);
    });
  });

  group('ScheduleProvider 边界', () {
    test('添加计划含结束日期', () async {
      await scheduleProvider.addSchedule(
        medicineId: 'm1', medicineName: '药', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: todayStart,
        endDate: now.add(Duration(days: 30)),
      );
      expect(scheduleProvider.schedules[0].endDate, isNotNull);
    });

    test('更新计划激活状态后刷新', () async {
      await scheduleProvider.addSchedule(
        medicineId: 'm1', medicineName: '药', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: todayStart,
      );
      await scheduleProvider.toggleScheduleActive(scheduleProvider.schedules[0]);
      await scheduleProvider.loadSchedules();
      expect(scheduleProvider.schedules[0].isActive, false);
    });

    test('PRN 计划不包含时间点', () async {
      await scheduleProvider.addSchedule(
        medicineId: 'm1', medicineName: '止痛药', dosage: '1片',
        frequency: ScheduleFrequency.prn, timePoints: [],
        startDate: todayStart,
      );
      expect(scheduleProvider.schedules[0].timePoints, isEmpty);
    });

    test('删除后列表为空', () async {
      await scheduleProvider.addSchedule(
        medicineId: 'm1', medicineName: '药', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: todayStart,
      );
      await scheduleProvider.removeSchedule(scheduleProvider.schedules[0].id);
      expect(scheduleProvider.schedules, isEmpty);
      expect(scheduleProvider.activeSchedules, isEmpty);
    });
  });

  group('ReminderProvider 边界', () {
    test('空列表依从率 0%', () {
      expect(reminderProvider.todayAdherence, 0.0);
    });

    test('无提醒时连续天数为 0', () async {
      await reminderProvider.loadTodayReminders();
      expect(reminderProvider.consecutiveDays, 0);
    });

    test('loadTodayReminders 不崩溃', () async {
      await reminderProvider.loadTodayReminders();
      expect(reminderProvider.errorMessage, isNull);
    });
  });

  group('跨 Provider 集成', () {
    test('添加药品→创建计划→生成提醒完整流程', () async {
      // 1. 添加药品
      await medicineProvider.addMedicine(
        name: '阿莫西林', dosageForm: '胶囊', specification: '500mg',
      );
      final med = medicineProvider.medicines[0];

      // 2. 创建用药计划
      await scheduleProvider.addSchedule(
        medicineId: med.id, medicineName: med.name, dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00', '20:00'],
        startDate: todayStart,
      );

      // 3. 生成今日提醒
      await reminderProvider.generateTodayReminders(scheduleProvider.activeSchedules);
      await reminderProvider.loadTodayReminders();

      expect(reminderProvider.todayReminders.length, 2);
      expect(reminderProvider.todayStats['total'], 2);
      expect(reminderProvider.todayStats['taken'], 0);
    });

    test('生成提醒后打卡', () async {
      await medicineProvider.addMedicine(
        name: '阿莫西林', dosageForm: '胶囊', specification: '500mg',
      );
      final med = medicineProvider.medicines[0];
      await scheduleProvider.addSchedule(
        medicineId: med.id, medicineName: med.name, dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: todayStart,
      );
      await reminderProvider.generateTodayReminders(scheduleProvider.activeSchedules);

      final rem = reminderProvider.todayReminders[0];
      await reminderProvider.takeMedicine(rem);

      await reminderProvider.loadTodayReminders();
      expect(reminderProvider.todayStats['taken'], 1);
    });

    test('跳过服药', () async {
      await medicineProvider.addMedicine(
        name: '阿莫西林', dosageForm: '胶囊', specification: '500mg',
      );
      final med = medicineProvider.medicines[0];
      await scheduleProvider.addSchedule(
        medicineId: med.id, medicineName: med.name, dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: todayStart,
      );
      await reminderProvider.generateTodayReminders(scheduleProvider.activeSchedules);
      final rem = reminderProvider.todayReminders[0];

      await reminderProvider.skipMedicine(rem);
      await reminderProvider.loadTodayReminders();
      expect(reminderProvider.todayReminders[0].status, ReminderStatus.skipped);
    });

    test('重复生成提醒不会重复插入', () async {
      await medicineProvider.addMedicine(
        name: '阿莫西林', dosageForm: '胶囊', specification: '500mg',
      );
      final med = medicineProvider.medicines[0];
      await scheduleProvider.addSchedule(
        medicineId: med.id, medicineName: med.name, dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: todayStart,
      );
      await reminderProvider.generateTodayReminders(scheduleProvider.activeSchedules);
      await reminderProvider.generateTodayReminders(scheduleProvider.activeSchedules);
      expect(reminderProvider.todayReminders.length, 1);
    });

    test('停用计划不生成提醒', () async {
      await medicineProvider.addMedicine(
        name: '阿莫西林', dosageForm: '胶囊', specification: '500mg',
      );
      final med = medicineProvider.medicines[0];
      await scheduleProvider.addSchedule(
        medicineId: med.id, medicineName: med.name, dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: todayStart,
      );
      await scheduleProvider.toggleScheduleActive(scheduleProvider.schedules[0]);
      await reminderProvider.generateTodayReminders(scheduleProvider.activeSchedules);
      expect(reminderProvider.todayReminders, isEmpty);
    });

    test('MedicineProvider 重复加载数据幂等', () async {
      await medicineProvider.addMedicine(name: 'A', dosageForm: '片剂', specification: '1mg');
      await medicineProvider.loadMedicines();
      expect(medicineProvider.medicines.length, 1);
    });

    test('ScheduleProvider 重复加载数据幂等', () async {
      await scheduleProvider.addSchedule(
        medicineId: 'm1', medicineName: 'A', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['09:00'],
        startDate: todayStart,
      );
      await scheduleProvider.loadSchedules();
      expect(scheduleProvider.schedules.length, 1);
    });

    test('ReminderProvider todayReminders 默认空', () {
      expect(reminderProvider.todayReminders, isEmpty);
      expect(reminderProvider.todayAdherence, 0.0);
    });

    test('添加药品后 isActive 默认为 true', () async {
      await medicineProvider.addMedicine(name: 'A', dosageForm: '片剂', specification: '1mg');
      expect(medicineProvider.medicines[0].isActive, true);
    });

    test('ScheduleProvider 初始 loading 状态', () {
      expect(scheduleProvider.isLoading, false);
      expect(scheduleProvider.errorMessage, isNull);
    });

    test('添加相同名称药品不冲突', () async {
      await medicineProvider.addMedicine(name: 'A', dosageForm: '片剂', specification: '1mg');
      await medicineProvider.addMedicine(name: 'A', dosageForm: '胶囊', specification: '2mg');
      expect(medicineProvider.medicines.length, 2);
    });

    test('多个时间点计划全部生成提醒', () async {
      await medicineProvider.addMedicine(name: '多时间', dosageForm: '片剂', specification: '1mg');
      final med = medicineProvider.medicines[0];
      await scheduleProvider.addSchedule(
        medicineId: med.id, medicineName: med.name, dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00', '12:00', '18:00'],
        startDate: todayStart,
      );
      await reminderProvider.generateTodayReminders(scheduleProvider.activeSchedules);
      expect(reminderProvider.todayReminders.length, 3);
    });

    test('takeMedicine 后状态变为 taken', () async {
      await medicineProvider.addMedicine(name: 'A', dosageForm: '片剂', specification: '1mg');
      final med = medicineProvider.medicines[0];
      await scheduleProvider.addSchedule(
        medicineId: med.id, medicineName: med.name, dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: todayStart,
      );
      await reminderProvider.generateTodayReminders(scheduleProvider.activeSchedules);
      final r = reminderProvider.todayReminders[0];
      await reminderProvider.takeMedicine(r);
      expect(reminderProvider.todayReminders[0].status, ReminderStatus.taken);
    });

    test('skipMedicine 后状态变为 skipped', () async {
      await medicineProvider.addMedicine(name: 'A', dosageForm: '片剂', specification: '1mg');
      final med = medicineProvider.medicines[0];
      await scheduleProvider.addSchedule(
        medicineId: med.id, medicineName: med.name, dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: todayStart,
      );
      await reminderProvider.generateTodayReminders(scheduleProvider.activeSchedules);
      final r = reminderProvider.todayReminders[0];
      await reminderProvider.skipMedicine(r);
      expect(reminderProvider.todayReminders[0].status, ReminderStatus.skipped);
    });
  });
}

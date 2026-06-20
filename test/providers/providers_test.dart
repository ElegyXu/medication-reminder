import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:medication_reminder/database/database_helper.dart';
import 'package:medication_reminder/models/schedule.dart';
import 'package:medication_reminder/providers/medicine_provider.dart';
import 'package:medication_reminder/providers/schedule_provider.dart';
import 'package:medication_reminder/providers/reminder_provider.dart';

void main() {
  late MedicineProvider medicineProvider;
  late ScheduleProvider scheduleProvider;
  late ReminderProvider reminderProvider;
  late DatabaseHelper db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = DatabaseHelper();
    // Clean database from prior test files
    final database = await db.database;
    await database.delete('reminders');
    await database.delete('symptoms');
    await database.delete('guardian_bindings');
    await database.delete('schedules');
    await database.delete('medicines');
  });

  setUp(() {
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

  // ==================== MedicineProvider ====================
  group('MedicineProvider', () {
    test('初始状态为空', () {
      expect(medicineProvider.medicines, isEmpty);
      expect(medicineProvider.activeMedicines, isEmpty);
      expect(medicineProvider.isLoading, false);
      expect(medicineProvider.errorMessage, isNull);
    });

    test('添加药品后列表包含该药品', () async {
      await medicineProvider.addMedicine(
        name: '阿莫西林', dosageForm: '胶囊', specification: '500mg',
      );
      expect(medicineProvider.medicines.length, 1);
      expect(medicineProvider.medicines[0].name, '阿莫西林');
      expect(medicineProvider.activeMedicines.length, 1);
    });

    test('添加多个药品', () async {
      await medicineProvider.addMedicine(
        name: '阿莫西林', dosageForm: '胶囊', specification: '500mg',
      );
      await medicineProvider.addMedicine(
        name: '头孢拉定', dosageForm: '片剂', specification: '250mg',
      );
      expect(medicineProvider.medicines.length, 2);
    });

    test('添加药品含备注', () async {
      await medicineProvider.addMedicine(
        name: '布洛芬', dosageForm: '片剂', specification: '200mg',
        notes: '饭后服用，避免空腹',
      );
      expect(medicineProvider.medicines[0].notes, '饭后服用，避免空腹');
    });

    test('更新药品信息', () async {
      await medicineProvider.addMedicine(
        name: '阿莫西林', dosageForm: '胶囊', specification: '500mg',
      );
      final med = medicineProvider.medicines[0];
      await medicineProvider.updateMedicineData(
        med.copyWith(name: '阿莫西林克拉维酸钾', specification: '625mg'),
      );
      expect(medicineProvider.medicines[0].name, '阿莫西林克拉维酸钾');
      expect(medicineProvider.medicines[0].specification, '625mg');
    });

    test('切换药品激活状态', () async {
      await medicineProvider.addMedicine(
        name: '阿莫西林', dosageForm: '胶囊', specification: '500mg',
      );
      final med = medicineProvider.medicines[0];
      expect(med.isActive, true);
      await medicineProvider.toggleMedicineActive(med);
      expect(medicineProvider.medicines[0].isActive, false);
      expect(medicineProvider.activeMedicines, isEmpty);
    });

    test('删除药品', () async {
      await medicineProvider.addMedicine(
        name: '阿莫西林', dosageForm: '胶囊', specification: '500mg',
      );
      final med = medicineProvider.medicines[0];
      await medicineProvider.removeMedicine(med.id);
      expect(medicineProvider.medicines, isEmpty);
    });

    test('loadMedicines 刷新列表', () async {
      await medicineProvider.addMedicine(
        name: '阿莫西林', dosageForm: '胶囊', specification: '500mg',
      );
      await medicineProvider.loadMedicines();
      expect(medicineProvider.medicines.length, 1);
    });

    test('activeMedicines 仅返回活动药品', () async {
      await medicineProvider.addMedicine(
        name: 'A药', dosageForm: '片剂', specification: '1mg',
      );
      await medicineProvider.addMedicine(
        name: 'B药', dosageForm: '胶囊', specification: '2mg',
      );
      final bMed = medicineProvider.medicines.firstWhere((m) => m.name == 'B药');
      await medicineProvider.toggleMedicineActive(bMed);
      final actives = medicineProvider.activeMedicines;
      expect(actives.length, 1);
      expect(actives.any((m) => m.name == 'A药'), true);
      expect(actives.any((m) => m.name == 'B药'), false);
    });

    test('添加自定义颜色药品', () async {
      await medicineProvider.addMedicine(
        name: '维C', dosageForm: '片剂', specification: '100mg',
        colorValue: 0xFF2196F3,
      );
      expect(medicineProvider.medicines[0].colorValue, 0xFF2196F3);
    });

    // TC-FIX-01: 验证 Provider 默认 colorValue 为 0xFFC62828
    test('TC-FIX-01: 默认 colorValue 为新红绿融合配色', () async {
      await medicineProvider.addMedicine(
        name: '测试药品', dosageForm: '片剂', specification: '100mg',
      );
      expect(medicineProvider.medicines[0].colorValue, 0xFFC62828);
    });
  });

  // ==================== ScheduleProvider ====================
  group('ScheduleProvider', () {
    test('初始状态为空', () {
      expect(scheduleProvider.schedules, isEmpty);
      expect(scheduleProvider.activeSchedules, isEmpty);
      expect(scheduleProvider.isLoading, false);
    });

    test('添加每日计划', () async {
      await scheduleProvider.addSchedule(
        medicineId: 'med-001', medicineName: '阿莫西林', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00', '20:00'],
        startDate: todayStart,
      );
      expect(scheduleProvider.schedules.length, 1);
      expect(scheduleProvider.schedules[0].frequency, ScheduleFrequency.daily);
    });

    test('添加每周计划', () async {
      await scheduleProvider.addSchedule(
        medicineId: 'med-001', medicineName: '维生素D', dosage: '2粒',
        frequency: ScheduleFrequency.weekly, timePoints: ['09:00'],
        weekDays: [1, 3, 5], startDate: todayStart,
      );
      expect(scheduleProvider.schedules[0].frequency, ScheduleFrequency.weekly);
      expect(scheduleProvider.schedules[0].weekDays, [1, 3, 5]);
    });

    test('添加每月计划', () async {
      await scheduleProvider.addSchedule(
        medicineId: 'med-001', medicineName: '钙片', dosage: '1片',
        frequency: ScheduleFrequency.monthly, timePoints: ['08:00'],
        monthDays: [1, 15], startDate: todayStart,
      );
      expect(scheduleProvider.schedules[0].frequency, ScheduleFrequency.monthly);
      expect(scheduleProvider.schedules[0].monthDays, [1, 15]);
    });

    test('添加 PRN 按需计划', () async {
      await scheduleProvider.addSchedule(
        medicineId: 'med-001', medicineName: '止痛药', dosage: '1片',
        frequency: ScheduleFrequency.prn, timePoints: [],
        prnMaxDaily: 3, prnMinIntervalMinutes: 240,
        startDate: todayStart,
      );
      expect(scheduleProvider.schedules[0].frequency, ScheduleFrequency.prn);
      expect(scheduleProvider.schedules[0].prnMaxDaily, 3);
    });

    test('切换计划激活状态', () async {
      await scheduleProvider.addSchedule(
        medicineId: 'med-001', medicineName: '阿莫西林', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: todayStart,
      );
      await scheduleProvider.toggleScheduleActive(scheduleProvider.schedules[0]);
      expect(scheduleProvider.schedules[0].isActive, false);
      expect(scheduleProvider.activeSchedules, isEmpty);
    });

    test('删除计划', () async {
      await scheduleProvider.addSchedule(
        medicineId: 'med-001', medicineName: '阿莫西林', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: todayStart,
      );
      await scheduleProvider.removeSchedule(scheduleProvider.schedules[0].id);
      expect(scheduleProvider.schedules, isEmpty);
    });

    test('更新计划信息', () async {
      await scheduleProvider.addSchedule(
        medicineId: 'med-001', medicineName: '阿莫西林', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: todayStart,
      );
      final sched = scheduleProvider.schedules[0];
      await scheduleProvider.updateScheduleData(MedicationSchedule(
        id: sched.id, medicineId: sched.medicineId, medicineName: sched.medicineName,
        dosage: '2片', frequency: sched.frequency, timePoints: ['09:00', '21:00'],
        startDate: todayStart, createdAt: sched.createdAt, updatedAt: now,
      ));
      expect(scheduleProvider.schedules[0].dosage, '2片');
      expect(scheduleProvider.schedules[0].timePoints, ['09:00', '21:00']);
    });

    test('activeSchedules 仅返回活动的', () async {
      await scheduleProvider.addSchedule(
        medicineId: 'med-001', medicineName: 'A药', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: todayStart,
      );
      await scheduleProvider.addSchedule(
        medicineId: 'med-002', medicineName: 'B药', dosage: '2片',
        frequency: ScheduleFrequency.daily, timePoints: ['20:00'],
        startDate: todayStart,
      );
      final aSched = scheduleProvider.schedules.firstWhere((s) => s.medicineName == 'A药');
      await scheduleProvider.toggleScheduleActive(aSched);
      final actives = scheduleProvider.activeSchedules;
      expect(actives.length, 1);
      expect(actives.any((s) => s.medicineName == 'B药'), true);
      expect(actives.any((s) => s.medicineName == 'A药'), false);
    });

    test('loadSchedules 刷新列表', () async {
      await scheduleProvider.addSchedule(
        medicineId: 'med-001', medicineName: '阿莫西林', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: todayStart,
      );
      await scheduleProvider.loadSchedules();
      expect(scheduleProvider.schedules.length, 1);
    });
  });

  // ==================== ReminderProvider ====================
  group('ReminderProvider', () {
    test('初始状态', () {
      expect(reminderProvider.todayReminders, isEmpty);
      expect(reminderProvider.isLoading, false);
      expect(reminderProvider.todayAdherence, 0.0);
      expect(reminderProvider.consecutiveDays, 0);
    });

    test('todayAdherence 无数据时为 0', () {
      expect(reminderProvider.todayAdherence, 0.0);
    });

    test('loadTodayReminders 正常加载', () async {
      await reminderProvider.loadTodayReminders();
      expect(reminderProvider.todayReminders, isEmpty);
      expect(reminderProvider.isLoading, false);
    });

    test('todayStats 默认值', () {
      expect(reminderProvider.todayStats['total'], 0);
      expect(reminderProvider.todayStats['taken'], 0);
    });
  });
}

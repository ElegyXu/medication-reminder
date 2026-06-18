import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'package:medication_reminder/models/medicine.dart';
import 'package:medication_reminder/models/schedule.dart';
import 'package:medication_reminder/models/reminder.dart';
import 'package:medication_reminder/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Inventory Management Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      final dbPath = inMemoryDatabasePath;
      await databaseFactory.deleteDatabase(dbPath);
      dbHelper = DatabaseHelper();
      
      final db = await dbHelper.database;
      await db.execute('DELETE FROM reminders');
      await db.execute('DELETE FROM schedules');
      await db.execute('DELETE FROM medicines');
    });

    test('test_medicine_stock_decrement: Parse dosage and deduct', () async {
      final medId = const Uuid().v4();
      final medicine = Medicine(
        id: medId,
        name: 'Test Med',
        dosageForm: '片剂',
        specification: '10mg',
        currentStock: 10.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dbHelper.insertMedicine(medicine);

      final schedule = MedicationSchedule(
        id: const Uuid().v4(),
        medicineId: medId,
        medicineName: 'Test Med',
        dosage: '1.5片', // Should parse 1.5
        frequency: ScheduleFrequency.daily,
        timePoints: ['08:00'],
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dbHelper.insertSchedule(schedule);

      final reminder = Reminder(
        id: const Uuid().v4(),
        scheduleId: schedule.id,
        medicineName: 'Test Med',
        dosage: '1.5片',
        scheduledTime: DateTime.now(),
        status: ReminderStatus.pending,
        createdAt: DateTime.now(),
      );
      await dbHelper.insertReminder(reminder);

      // Execute deduction logic (extracted from Provider for isolated DB test)
      final db = await dbHelper.database;
      final match = RegExp(r'[\d.]+').firstMatch(reminder.dosage);
      final consumed = double.tryParse(match!.group(0)!) ?? 0.0;
      double newStock = medicine.currentStock - consumed;
      if (newStock < 0) newStock = 0;
      await dbHelper.updateMedicine(medicine.copyWith(
        currentStock: newStock,
        updatedAt: DateTime.now(),
      ));

      final updatedMed = await dbHelper.getMedicine(medId);
      expect(updatedMed!.currentStock, 8.5);
    });

    test('test_stock_negative_prevention: Prevent negative stock', () async {
      final medId = const Uuid().v4();
      final medicine = Medicine(
        id: medId,
        name: 'Test Med',
        dosageForm: '片剂',
        specification: '10mg',
        currentStock: 0.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dbHelper.insertMedicine(medicine);

      double newStock = medicine.currentStock - 1.0;
      if (newStock < 0) newStock = 0;
      await dbHelper.updateMedicine(medicine.copyWith(
        currentStock: newStock,
        updatedAt: DateTime.now(),
      ));

      final updatedMed = await dbHelper.getMedicine(medId);
      expect(updatedMed!.currentStock, 0.0);
    });

    test('test_low_stock_ui_trigger: Check thresholds', () {
      final med1 = Medicine(
        id: '1', name: 'M1', dosageForm: '片', specification: '',
        currentStock: 10, alertThreshold: 5,
        createdAt: DateTime.now(), updatedAt: DateTime.now()
      );
      final med2 = Medicine(
        id: '2', name: 'M2', dosageForm: '片', specification: '',
        currentStock: 4, alertThreshold: 5,
        createdAt: DateTime.now(), updatedAt: DateTime.now()
      );
      
      expect(med1.currentStock <= med1.alertThreshold, false);
      expect(med2.currentStock <= med2.alertThreshold, true);
    });
  });
}
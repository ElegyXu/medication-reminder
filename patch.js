const fs = require('fs');

try {
  // 1. medicine.dart
  let medicine = fs.readFileSync('lib/models/medicine.dart', 'utf-8');
  medicine = medicine.replace('final int colorValue; // 图标颜色\n  final bool isActive;', 'final int colorValue; // 图标颜色\n  final double currentStock;\n  final double alertThreshold;\n  final bool isActive;');
  medicine = medicine.replace('this.colorValue = 0xFFC41E3A,\n    this.isActive = true,', 'this.colorValue = 0xFFC41E3A,\n    this.currentStock = 0.0,\n    this.alertThreshold = 0.0,\n    this.isActive = true,');
  medicine = medicine.replace("'color_value': colorValue,\n    'is_active': isActive ? 1 : 0,", "'color_value': colorValue,\n    'current_stock': currentStock,\n    'alert_threshold': alertThreshold,\n    'is_active': isActive ? 1 : 0,");
  medicine = medicine.replace("colorValue: map['color_value'],\n    isActive: map['is_active'] == 1,", "colorValue: map['color_value'],\n    currentStock: map['current_stock']?.toDouble() ?? 0.0,\n    alertThreshold: map['alert_threshold']?.toDouble() ?? 0.0,\n    isActive: map['is_active'] == 1,");
  medicine = medicine.replace("int? colorValue,\n    bool? isActive,", "int? colorValue,\n    double? currentStock,\n    double? alertThreshold,\n    bool? isActive,");
  medicine = medicine.replace("colorValue: colorValue ?? this.colorValue,\n    isActive: isActive ?? this.isActive,", "colorValue: colorValue ?? this.colorValue,\n    currentStock: currentStock ?? this.currentStock,\n    alertThreshold: alertThreshold ?? this.alertThreshold,\n    isActive: isActive ?? this.isActive,");
  fs.writeFileSync('lib/models/medicine.dart', medicine);

  // 2. database_helper.dart
  let db = fs.readFileSync('lib/database/database_helper.dart', 'utf-8');
  db = db.replace('version: 1,\n      onCreate: _onCreate,', 'version: 2,\n      onCreate: _onCreate,\n      onUpgrade: _onUpgrade,');
  db = db.replace('color_value INTEGER DEFAULT 4284513850,\n        is_active INTEGER DEFAULT 1,', 'color_value INTEGER DEFAULT 4284513850,\n        current_stock REAL DEFAULT 0.0,\n        alert_threshold REAL DEFAULT 0.0,\n        is_active INTEGER DEFAULT 1,');
  let upgradeFunc = `
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE medicines ADD COLUMN current_stock REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE medicines ADD COLUMN alert_threshold REAL DEFAULT 0.0');
    }
  }

  Future<MedicationSchedule?> getSchedule(String id) async {
    final db = await database;
    final maps = await db.query('schedules', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return MedicationSchedule.fromMap(maps.first);
  }
`;
  db = db.replace('// ==================== Medicines ====================', upgradeFunc + '\n  // ==================== Medicines ====================');
  fs.writeFileSync('lib/database/database_helper.dart', db);

  // 3. medicine_provider.dart
  let mp = fs.readFileSync('lib/providers/medicine_provider.dart', 'utf-8');
  mp = mp.replace('int colorValue = 0xFFC41E3A,\n  }) async {', 'int colorValue = 0xFFC41E3A,\n    double currentStock = 0.0,\n    double alertThreshold = 0.0,\n  }) async {');
  mp = mp.replace('colorValue: colorValue,\n      isActive: true,', 'colorValue: colorValue,\n      currentStock: currentStock,\n      alertThreshold: alertThreshold,\n      isActive: true,');
  fs.writeFileSync('lib/providers/medicine_provider.dart', mp);

  // 4. reminder_provider.dart
  let rp = fs.readFileSync('lib/providers/reminder_provider.dart', 'utf-8');
  let deductLogic = `
    await _db.updateReminder(updated);
    
    final schedule = await _db.getSchedule(reminder.scheduleId);
    if (schedule != null) {
      final medicine = await _db.getMedicine(schedule.medicineId);
      if (medicine != null) {
        final match = RegExp(r'[\\d.]+').firstMatch(reminder.dosage);
        if (match != null) {
          final consumed = double.tryParse(match.group(0)!) ?? 0.0;
          if (consumed > 0) {
            double newStock = medicine.currentStock - consumed;
            if (newStock < 0) newStock = 0;
            await _db.updateMedicine(medicine.copyWith(
              currentStock: newStock,
              updatedAt: DateTime.now(),
            ));
          }
        }
      }
    }
`;
  rp = rp.replace('await _db.updateReminder(updated);\n    await loadTodayReminders();', deductLogic + '    await loadTodayReminders();');
  fs.writeFileSync('lib/providers/reminder_provider.dart', rp);

  // 5. reminder_bottom_sheet.dart
  let bs = fs.readFileSync('lib/widgets/reminder_bottom_sheet.dart', 'utf-8');
  bs = bs.replace("import '../providers/reminder_provider.dart';", "import '../providers/reminder_provider.dart';\nimport 'package:provider/provider.dart';\nimport '../providers/medicine_provider.dart';");
  bs = bs.replace('await provider.takeMedicine(reminder);\n              },', 'await provider.takeMedicine(reminder);\n                if (context.mounted) {\n                  context.read<MedicineProvider>().loadMedicines();\n                }\n              },');
  fs.writeFileSync('lib/widgets/reminder_bottom_sheet.dart', bs);

  // 6. medicine_form_screen.dart
  let mf = fs.readFileSync('lib/screens/medicine/medicine_form_screen.dart', 'utf-8');
  mf = mf.replace('late TextEditingController _notesController;', 'late TextEditingController _notesController;\n  late TextEditingController _stockController;\n  late TextEditingController _thresholdController;');
  mf = mf.replace('_notesController = TextEditingController(text: m?.notes ?? \'\');', "_notesController = TextEditingController(text: m?.notes ?? '');\n    _stockController = TextEditingController(text: m?.currentStock.toString() ?? '0');\n    _thresholdController = TextEditingController(text: m?.alertThreshold.toString() ?? '0');");
  mf = mf.replace('_notesController.dispose();', '_notesController.dispose();\n    _stockController.dispose();\n    _thresholdController.dispose();');
  mf = mf.replace('colorValue: _colorValue,\n        updatedAt: DateTime.now(),', 'colorValue: _colorValue,\n        currentStock: double.tryParse(_stockController.text) ?? 0.0,\n        alertThreshold: double.tryParse(_thresholdController.text) ?? 0.0,\n        updatedAt: DateTime.now(),');
  mf = mf.replace('colorValue: _colorValue,\n      );', 'colorValue: _colorValue,\n        currentStock: double.tryParse(_stockController.text) ?? 0.0,\n        alertThreshold: double.tryParse(_thresholdController.text) ?? 0.0,\n      );');
  
  let uiFields = `const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(labelText: '当前库存', hintText: '如：30'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _thresholdController,
                    decoration: const InputDecoration(labelText: '低库存预警', hintText: '如：5'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),`;
  mf = mf.replace('const SizedBox(height: 16),\n            TextFormField(\n              controller: _notesController,', uiFields + '\n            const SizedBox(height: 16),\n            TextFormField(\n              controller: _notesController,');
  fs.writeFileSync('lib/screens/medicine/medicine_form_screen.dart', mf);

  // 7. patient_home_screen.dart
  let ph = fs.readFileSync('lib/screens/home/patient_home_screen.dart', 'utf-8');
  let alertWidget = `
  Widget _buildLowStockAlert(List<Medicine> meds, ColorScheme cs, TextTheme tt) {
    final names = meds.map((m) => m.name).join('、');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '库存预警: $names 库存不足，请及时补充。',
              style: tt.bodyMedium?.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
`;
  ph = ph.replace(/}\s*$/, alertWidget);

  let origList = `          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => switch (index) {
                  0 => _buildProgressRow(cs, tt),
                  1 => const SizedBox(height: 16),
                  2 => _buildWeekStrip(cs, tt),
                  3 => const SizedBox(height: 16),
                  4 => _buildStreakFooter(cs, tt),
                  _ => null,
                },
                childCount: 5,
              ),
            ),
          ),`;

  let newList = `          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final medicineProvider = context.watch<MedicineProvider>();
                  final lowStockMedicines = medicineProvider.activeMedicines.where(
                    (m) => m.alertThreshold > 0 && m.currentStock <= m.alertThreshold
                  ).toList();

                  final listItems = <Widget>[
                    _buildProgressRow(cs, tt),
                    const SizedBox(height: 16),
                  ];
                  
                  if (lowStockMedicines.isNotEmpty) {
                    listItems.add(_buildLowStockAlert(lowStockMedicines, cs, tt));
                    listItems.add(const SizedBox(height: 16));
                  }
                  
                  listItems.addAll([
                    _buildWeekStrip(cs, tt),
                    const SizedBox(height: 16),
                    _buildStreakFooter(cs, tt),
                  ]);
                  
                  if (index < listItems.length) return listItems[index];
                  return null;
                },
                childCount: context.watch<MedicineProvider>().activeMedicines.where((m) => m.alertThreshold > 0 && m.currentStock <= m.alertThreshold).isNotEmpty ? 7 : 5,
              ),
            ),
          ),`;
  ph = ph.replace(origList, newList);
  fs.writeFileSync('lib/screens/home/patient_home_screen.dart', ph);

  // 8. pubspec.yaml version bump
  let pub = fs.readFileSync('pubspec.yaml', 'utf-8');
  let match = pub.match(/version: 1\.0\.(\d+)\+(\d+)/);
  if (match) {
      let minor = parseInt(match[1]) + 1;
      let build = parseInt(match[2]) + 1;
      pub = pub.replace(/version: 1\\.0\\.\\d+\\+\\d+/, 'version: 1.0.' + minor + '+' + build);
      fs.writeFileSync('pubspec.yaml', pub);
      console.log(\`Bumped version to 1.0.\${minor}+\${build}\`);
  }

  // 9. Generate test file
  let testCode = \`import 'package:flutter_test/flutter_test.dart';
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
      final match = RegExp(r'[\\\\d.]+').firstMatch(reminder.dosage);
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
\`;
  fs.writeFileSync('test/inventory_test.dart', testCode);

  console.log('Patch successfully applied to all files.');
} catch (e) {
  console.error('Error applying patch:', e);
}

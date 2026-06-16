import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medicine.dart';
import '../models/schedule.dart';
import '../models/reminder.dart';
import '../models/symptom.dart';
import '../models/guardian_binding.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medication_reminder.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medicines (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        dosage_form TEXT NOT NULL,
        specification TEXT NOT NULL,
        notes TEXT,
        color_value INTEGER DEFAULT 4284513850,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id TEXT PRIMARY KEY,
        medicine_id TEXT NOT NULL,
        medicine_name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        time_points TEXT NOT NULL,
        week_days TEXT,
        month_days TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT,
        prn_max_daily INTEGER,
        prn_min_interval_minutes INTEGER,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (medicine_id) REFERENCES medicines(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        schedule_id TEXT NOT NULL,
        medicine_name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        scheduled_time TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        source TEXT,
        taken_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (schedule_id) REFERENCES schedules(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE symptoms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        severity INTEGER NOT NULL,
        notes TEXT,
        related_medicine_id TEXT,
        related_medicine_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE guardian_bindings (
        id TEXT PRIMARY KEY,
        patient_phone TEXT NOT NULL,
        patient_nickname TEXT NOT NULL,
        guardian_phone TEXT NOT NULL,
        status TEXT DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_reminders_scheduled ON reminders(scheduled_time)'
    );
    await db.execute(
      'CREATE INDEX idx_reminders_status ON reminders(status)'
    );
    await db.execute(
      'CREATE INDEX idx_symptoms_created ON symptoms(created_at)'
    );
  }

  // ==================== Medicines ====================

  Future<List<Medicine>> getMedicines({bool? isActive}) async {
    final db = await database;
    final maps = await db.query(
      'medicines',
      where: isActive != null ? 'is_active = ?' : null,
      whereArgs: isActive != null ? [isActive ? 1 : 0] : null,
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => Medicine.fromMap(m)).toList();
  }

  Future<Medicine?> getMedicine(String id) async {
    final db = await database;
    final maps = await db.query('medicines', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Medicine.fromMap(maps.first);
  }

  Future<void> insertMedicine(Medicine medicine) async {
    final db = await database;
    await db.insert('medicines', medicine.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateMedicine(Medicine medicine) async {
    final db = await database;
    await db.update('medicines', medicine.toMap(),
        where: 'id = ?', whereArgs: [medicine.id]);
  }

  Future<void> deleteMedicine(String id) async {
    final db = await database;
    await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
    // 同步删除关联的用药计划
    await db.delete('schedules', where: 'medicine_id = ?', whereArgs: [id]);
  }

  // ==================== Schedules ====================

  Future<List<MedicationSchedule>> getSchedules({bool? isActive}) async {
    final db = await database;
    final maps = await db.query(
      'schedules',
      where: isActive != null ? 'is_active = ?' : null,
      whereArgs: isActive != null ? [isActive ? 1 : 0] : null,
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => MedicationSchedule.fromMap(m)).toList();
  }

  Future<void> insertSchedule(MedicationSchedule schedule) async {
    final db = await database;
    await db.insert('schedules', schedule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSchedule(MedicationSchedule schedule) async {
    final db = await database;
    await db.update('schedules', schedule.toMap(),
        where: 'id = ?', whereArgs: [schedule.id]);
  }

  Future<void> deleteSchedule(String id) async {
    final db = await database;
    await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Reminders ====================

  Future<List<Reminder>> getReminders({
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (status != null) {
      conditions.add('status = ?');
      args.add(status);
    }
    if (fromDate != null) {
      conditions.add('scheduled_time >= ?');
      args.add(fromDate.toIso8601String());
    }
    if (toDate != null) {
      conditions.add('scheduled_time <= ?');
      args.add(toDate.toIso8601String());
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    return (await db.query(
      'reminders',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'scheduled_time ASC',
      limit: limit,
    )).map((m) => Reminder.fromMap(m)).toList();
  }

  Future<void> insertReminder(Reminder reminder) async {
    final db = await database;
    await db.insert('reminders', reminder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await database;
    await db.update('reminders', reminder.toMap(),
        where: 'id = ?', whereArgs: [reminder.id]);
  }

  Future<void> insertReminders(List<Reminder> reminders) async {
    final db = await database;
    final batch = db.batch();
    for (final r in reminders) {
      batch.insert('reminders', r.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ==================== Symptoms ====================

  Future<List<Symptom>> getSymptoms({int? limit}) async {
    final db = await database;
    final maps = await db.query('symptoms',
        orderBy: 'created_at DESC', limit: limit);
    return maps.map((m) => Symptom.fromMap(m)).toList();
  }

  Future<void> insertSymptom(Symptom symptom) async {
    final db = await database;
    await db.insert('symptoms', symptom.toMap());
  }

  Future<void> deleteSymptom(String id) async {
    final db = await database;
    await db.delete('symptoms', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Guardian Bindings ====================

  Future<List<GuardianBinding>> getBindings({String? status}) async {
    final db = await database;
    String where = status != null ? 'status = ?' : '';
    final maps = await db.query(
      'guardian_bindings',
      where: status != null ? where : null,
      whereArgs: status != null ? [status] : null,
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => GuardianBinding.fromMap(m)).toList();
  }

  Future<void> insertBinding(GuardianBinding binding) async {
    final db = await database;
    await db.insert('guardian_bindings', binding.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateBinding(GuardianBinding binding) async {
    final db = await database;
    await db.update('guardian_bindings', binding.toMap(),
        where: 'id = ?', whereArgs: [binding.id]);
  }

  Future<void> deleteBinding(String id) async {
    final db = await database;
    await db.delete('guardian_bindings', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Statistics ====================

  Future<Map<String, int>> getTodayStats() async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final total = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM reminders WHERE scheduled_time BETWEEN ? AND ?',
      [todayStart, todayEnd],
    )) ?? 0;

    final taken = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM reminders WHERE scheduled_time BETWEEN ? AND ? AND status = ?',
      [todayStart, todayEnd, 'taken'],
    )) ?? 0;

    return {'total': total, 'taken': taken};
  }

  Future<int> getConsecutiveDays() async {
    final db = await database;
    // 简化版：统计有服药记录的连续天数
    final result = await db.rawQuery('''
      SELECT DISTINCT date(scheduled_time) as d
      FROM reminders
      WHERE status = 'taken'
      ORDER BY d DESC
      LIMIT 30
    ''');

    if (result.isEmpty) return 0;

    int consecutive = 1;
    for (int i = 1; i < result.length; i++) {
      final prev = DateTime.parse(result[i - 1]['d'] as String);
      final curr = DateTime.parse(result[i]['d'] as String);
      if (prev.difference(curr).inDays == 1) {
        consecutive++;
      } else {
        break;
      }
    }
    return consecutive;
  }
}

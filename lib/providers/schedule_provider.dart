import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule.dart';
import '../database/database_helper.dart';

class ScheduleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<MedicationSchedule> _schedules = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MedicationSchedule> get schedules => _schedules;
  List<MedicationSchedule> get activeSchedules =>
      _schedules.where((s) => s.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSchedules() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _schedules = await _db.getSchedules();
    } catch (e) {
      _errorMessage = '加载失败: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSchedule({
    required String medicineId,
    required String medicineName,
    required String dosage,
    required ScheduleFrequency frequency,
    required List<String> timePoints,
    List<int>? weekDays,
    List<int>? monthDays,
    required DateTime startDate,
    DateTime? endDate,
    int? prnMaxDaily,
    int? prnMinIntervalMinutes,
  }) async {
    final now = DateTime.now();
    final schedule = MedicationSchedule(
      id: const Uuid().v4(),
      medicineId: medicineId,
      medicineName: medicineName,
      dosage: dosage,
      frequency: frequency,
      timePoints: timePoints,
      weekDays: weekDays,
      monthDays: monthDays,
      startDate: startDate,
      endDate: endDate,
      prnMaxDaily: prnMaxDaily,
      prnMinIntervalMinutes: prnMinIntervalMinutes,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertSchedule(schedule);
    await loadSchedules();
  }

  Future<void> updateScheduleData(MedicationSchedule schedule) async {
    final updated = MedicationSchedule(
      id: schedule.id,
      medicineId: schedule.medicineId,
      medicineName: schedule.medicineName,
      dosage: schedule.dosage,
      frequency: schedule.frequency,
      timePoints: schedule.timePoints,
      weekDays: schedule.weekDays,
      monthDays: schedule.monthDays,
      startDate: schedule.startDate,
      endDate: schedule.endDate,
      prnMaxDaily: schedule.prnMaxDaily,
      prnMinIntervalMinutes: schedule.prnMinIntervalMinutes,
      isActive: schedule.isActive,
      createdAt: schedule.createdAt,
      updatedAt: DateTime.now(),
    );
    await _db.updateSchedule(updated);
    await loadSchedules();
  }

  Future<void> toggleScheduleActive(MedicationSchedule schedule) async {
    final updated = MedicationSchedule(
      id: schedule.id,
      medicineId: schedule.medicineId,
      medicineName: schedule.medicineName,
      dosage: schedule.dosage,
      frequency: schedule.frequency,
      timePoints: schedule.timePoints,
      weekDays: schedule.weekDays,
      monthDays: schedule.monthDays,
      startDate: schedule.startDate,
      endDate: schedule.endDate,
      prnMaxDaily: schedule.prnMaxDaily,
      prnMinIntervalMinutes: schedule.prnMinIntervalMinutes,
      isActive: !schedule.isActive,
      createdAt: schedule.createdAt,
      updatedAt: DateTime.now(),
    );
    await _db.updateSchedule(updated);
    await loadSchedules();
  }

  Future<void> removeSchedule(String id) async {
    await _db.deleteSchedule(id);
    await loadSchedules();
  }
}

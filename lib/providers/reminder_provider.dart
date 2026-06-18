import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder.dart';
import '../models/schedule.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class ReminderProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();

  List<Reminder> _todayReminders = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, int> _todayStats = {'total': 0, 'taken': 0};
  int _consecutiveDays = 0;

  List<Reminder> get todayReminders => _todayReminders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, int> get todayStats => _todayStats;
  int get consecutiveDays => _consecutiveDays;
  double get todayAdherence =>
      _todayStats['total']! > 0
          ? _todayStats['taken']! / _todayStats['total']!
          : 0.0;

  Future<void> loadTodayReminders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      _todayReminders = await _db.getReminders(
        fromDate: todayStart,
        toDate: todayEnd,
      );

      _todayStats = await _db.getTodayStats();
      _consecutiveDays = await _db.getConsecutiveDays();
    } catch (e) {
      _errorMessage = '加载失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 根据活跃的用药计划生成今日提醒
  Future<void> generateTodayReminders(List<MedicationSchedule> schedules) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // 检查是否已生成今日提醒
    final existing = await _db.getReminders(
      fromDate: todayStart,
      toDate: todayEnd,
    );
    if (existing.isNotEmpty) return; // 已生成，跳过

    final reminders = <Reminder>[];
    final todayWeekday = now.weekday; // 1=Mon, 7=Sun
    final todayDay = now.day;

    for (final schedule in schedules) {
      if (!schedule.isActive) continue;
      if (schedule.startDate.isAfter(todayEnd)) continue;
      if (schedule.endDate != null && schedule.endDate!.isBefore(todayStart)) continue;

      // 检查频率匹配
      bool matches = false;
      switch (schedule.frequency) {
        case ScheduleFrequency.daily:
          matches = true;
          break;
        case ScheduleFrequency.weekly:
          matches = schedule.weekDays?.contains(todayWeekday) ?? false;
          break;
        case ScheduleFrequency.monthly:
          matches = schedule.monthDays?.contains(todayDay) ?? false;
          break;
        case ScheduleFrequency.prn:
          continue; // PRN不自动生成，手动触发
      }

      if (!matches) continue;

      for (final timeStr in schedule.timePoints) {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

        final reminder = Reminder(
          id: const Uuid().v4(),
          scheduleId: schedule.id,
          medicineName: schedule.medicineName,
          dosage: schedule.dosage,
          scheduledTime: scheduledTime,
          status: ReminderStatus.pending,
          createdAt: now,
        );
        reminders.add(reminder);
      }
    }

    if (reminders.isNotEmpty) {
      await _db.insertReminders(reminders);

      // 安排通知 (非关键路径，失败不影响数据完整性)
      for (final r in reminders) {
        try {
          await _notificationService.scheduleReminder(
            medicineName: r.medicineName,
            dosage: r.dosage,
            scheduledTime: r.scheduledTime,
            reminderId: r.id,
          );
        } catch (_) {
          // Notification scheduling failure is non-critical
        }
      }
    }

    await loadTodayReminders();
  }

  /// 标记已服药
  Future<void> takeMedicine(Reminder reminder) async {
    final updated = reminder.copyWith(
      status: ReminderStatus.taken,
      source: 'manual',
      takenAt: DateTime.now(),
    );
    await _db.updateReminder(updated);
    await _deductStock(reminder.scheduleId, reminder.dosage);
    await loadTodayReminders();
  }

  Future<void> _deductStock(String scheduleId, String dosageStr) async {
    final schedule = await _db.getSchedule(scheduleId);
    if (schedule != null) {
      final medicine = await _db.getMedicine(schedule.medicineId);
      if (medicine != null) {
        final match = RegExp(r'[\d.]+').firstMatch(dosageStr);
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
  }

  /// 跳过服药
  Future<void> skipMedicine(Reminder reminder) async {
    final updated = reminder.copyWith(
      status: ReminderStatus.skipped,
    );
    await _db.updateReminder(updated);
    await loadTodayReminders();
  }

  /// 延迟服药
  Future<void> delayMedicine(Reminder reminder, {int minutes = 15}) async {
    final delayedTime = DateTime.now().add(Duration(minutes: minutes));
    final updated = reminder.copyWith(
      scheduledTime: delayedTime,
    );
    await _db.updateReminder(updated);
    await loadTodayReminders();
  }

  /// PRN按需服药
  Future<bool> takePrnMedicine({
    required MedicationSchedule schedule,
  }) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // 检查每日上限
    if (schedule.prnMaxDaily != null) {
      final todayPrnCount = (await _db.getReminders(
        fromDate: todayStart,
        toDate: todayEnd,
      )).where((r) => r.scheduleId == schedule.id && r.status == ReminderStatus.taken).length;

      if (todayPrnCount >= schedule.prnMaxDaily!) return false;
    }

    // 检查最小间隔
    if (schedule.prnMinIntervalMinutes != null) {
      final lastPrn = (await _db.getReminders(
        fromDate: todayStart,
        toDate: todayEnd,
      ))
          .where((r) => r.scheduleId == schedule.id && r.status == ReminderStatus.taken)
          .toList();

      if (lastPrn.isNotEmpty) {
        lastPrn.sort((a, b) => b.takenAt!.compareTo(a.takenAt!));
        final minutesSinceLast = now.difference(lastPrn.first.takenAt!).inMinutes;
        if (minutesSinceLast < schedule.prnMinIntervalMinutes!) return false;
      }
    }

    final reminder = Reminder(
      id: const Uuid().v4(),
      scheduleId: schedule.id,
      medicineName: schedule.medicineName,
      dosage: schedule.dosage,
      scheduledTime: now,
      status: ReminderStatus.taken,
      source: 'manual',
      takenAt: now,
      createdAt: now,
    );
    await _db.insertReminder(reminder);
    await _deductStock(schedule.id, schedule.dosage);
    await loadTodayReminders();
    return true;
  }
}

enum ScheduleFrequency { daily, weekly, monthly, prn }

class MedicationSchedule {
  final String id;
  final String medicineId;
  final String medicineName; // 冗余字段便于显示
  final String dosage; // 剂量如 "1片"
  final ScheduleFrequency frequency;
  final List<String> timePoints; // ["08:00", "20:00"]
  final List<int>? weekDays; // weekly: [1,3,5] = 周一三五
  final List<int>? monthDays; // monthly: [1,15]
  final DateTime startDate;
  final DateTime? endDate;
  final int? prnMaxDaily; // PRN每日最大次数
  final int? prnMinIntervalMinutes; // PRN最小间隔分钟
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicationSchedule({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.timePoints,
    this.weekDays,
    this.monthDays,
    required this.startDate,
    this.endDate,
    this.prnMaxDaily,
    this.prnMinIntervalMinutes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get frequencyLabel {
    switch (frequency) {
      case ScheduleFrequency.daily: return '每日';
      case ScheduleFrequency.weekly: return '每周';
      case ScheduleFrequency.monthly: return '每月';
      case ScheduleFrequency.prn: return '按需';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'medicine_id': medicineId,
    'medicine_name': medicineName,
    'dosage': dosage,
    'frequency': frequency.name,
    'time_points': timePoints.join(','),
    'week_days': (weekDays != null && weekDays!.isNotEmpty) ? weekDays!.join(',') : null,
    'month_days': (monthDays != null && monthDays!.isNotEmpty) ? monthDays!.join(',') : null,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'prn_max_daily': prnMaxDaily,
    'prn_min_interval_minutes': prnMinIntervalMinutes,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory MedicationSchedule.fromMap(Map<String, dynamic> map) => MedicationSchedule(
    id: map['id'],
    medicineId: map['medicine_id'],
    medicineName: map['medicine_name'],
    dosage: map['dosage'],
    frequency: ScheduleFrequency.values.byName(map['frequency']),
    timePoints: (map['time_points'] as String).isEmpty
        ? []
        : (map['time_points'] as String).split(','),
    weekDays: map['week_days'] != null
        ? (map['week_days'] as String).split(',').map(int.parse).toList()
        : null,
    monthDays: map['month_days'] != null
        ? (map['month_days'] as String).split(',').map(int.parse).toList()
        : null,
    startDate: DateTime.parse(map['start_date']),
    endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
    prnMaxDaily: map['prn_max_daily'],
    prnMinIntervalMinutes: map['prn_min_interval_minutes'],
    isActive: map['is_active'] == 1,
    createdAt: DateTime.parse(map['created_at']),
    updatedAt: DateTime.parse(map['updated_at']),
  );
}

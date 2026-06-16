enum ReminderStatus { pending, taken, skipped, missed }

class Reminder {
  final String id;
  final String scheduleId;
  final String medicineName;
  final String dosage;
  final DateTime scheduledTime;
  final ReminderStatus status;
  final String? source; // 'notification' / 'manual'
  final DateTime? takenAt;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.scheduleId,
    required this.medicineName,
    required this.dosage,
    required this.scheduledTime,
    this.status = ReminderStatus.pending,
    this.source,
    this.takenAt,
    required this.createdAt,
  });

  String get statusLabel {
    switch (status) {
      case ReminderStatus.pending: return '待服';
      case ReminderStatus.taken: return '已服';
      case ReminderStatus.skipped: return '跳过';
      case ReminderStatus.missed: return '漏服';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'schedule_id': scheduleId,
    'medicine_name': medicineName,
    'dosage': dosage,
    'scheduled_time': scheduledTime.toIso8601String(),
    'status': status.name,
    'source': source,
    'taken_at': takenAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  factory Reminder.fromMap(Map<String, dynamic> map) => Reminder(
    id: map['id'],
    scheduleId: map['schedule_id'],
    medicineName: map['medicine_name'],
    dosage: map['dosage'],
    scheduledTime: DateTime.parse(map['scheduled_time']),
    status: ReminderStatus.values.byName(map['status']),
    source: map['source'],
    takenAt: map['taken_at'] != null ? DateTime.parse(map['taken_at']) : null,
    createdAt: DateTime.parse(map['created_at']),
  );

  Reminder copyWith({
    ReminderStatus? status,
    String? source,
    DateTime? takenAt,
    DateTime? scheduledTime,
  }) => Reminder(
    id: id,
    scheduleId: scheduleId,
    medicineName: medicineName,
    dosage: dosage,
    scheduledTime: scheduledTime ?? this.scheduledTime,
    status: status ?? this.status,
    source: source ?? this.source,
    takenAt: takenAt ?? this.takenAt,
    createdAt: createdAt,
  );
}

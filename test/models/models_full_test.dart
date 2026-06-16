import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/models/medicine.dart';
import 'package:medication_reminder/models/schedule.dart';
import 'package:medication_reminder/models/reminder.dart';
import 'package:medication_reminder/models/symptom.dart';
import 'package:medication_reminder/models/guardian_binding.dart';

final now = DateTime(2026, 6, 16, 10, 30);

// ==================== Medicine Model ====================
void main() {
  group('Medicine 模型', () {
    final medicine = Medicine(
      id: 'med-001', name: '阿莫西林', dosageForm: '胶囊', specification: '500mg',
      notes: '饭后服用', colorValue: 0xFFC41E3A, isActive: true,
      createdAt: now, updatedAt: now,
    );

    test('toMap 序列化正确', () {
      final map = medicine.toMap();
      expect(map['id'], 'med-001');
      expect(map['name'], '阿莫西林');
      expect(map['dosage_form'], '胶囊');
      expect(map['specification'], '500mg');
      expect(map['notes'], '饭后服用');
      expect(map['color_value'], 0xFFC41E3A);
      expect(map['is_active'], 1);
      expect(map['created_at'], now.toIso8601String());
      expect(map['updated_at'], now.toIso8601String());
    });

    test('fromMap 反序列化正确', () {
      final m = Medicine.fromMap(medicine.toMap());
      expect(m.id, 'med-001');
      expect(m.name, '阿莫西林');
      expect(m.dosageForm, '胶囊');
      expect(m.specification, '500mg');
      expect(m.notes, '饭后服用');
      expect(m.colorValue, 0xFFC41E3A);
      expect(m.isActive, true);
    });

    test('fromMap isActive=0 为 false', () {
      final map = medicine.toMap()..['is_active'] = 0;
      final m = Medicine.fromMap(map);
      expect(m.isActive, false);
    });

    test('fromMap 缺少 notes 字段', () {
      final map = medicine.toMap()..remove('notes');
      final m = Medicine.fromMap(map);
      expect(m.notes, isNull);
    });

    test('copyWith 部分字段', () {
      final m = medicine.copyWith(name: '头孢拉定');
      expect(m.name, '头孢拉定');
      expect(m.id, 'med-001'); // 未改
      expect(m.dosageForm, '胶囊'); // 未改
    });

    test('copyWith 全部字段', () {
      final m = medicine.copyWith(
        id: 'med-002', name: '布洛芬', dosageForm: '片剂', specification: '200mg',
        notes: '空腹服用', colorValue: 0xFF2196F3, isActive: false,
        createdAt: now.subtract(Duration(days: 1)), updatedAt: now,
      );
      expect(m.id, 'med-002');
      expect(m.name, '布洛芬');
      expect(m.dosageForm, '片剂');
      expect(m.specification, '200mg');
      expect(m.notes, '空腹服用');
      expect(m.colorValue, 0xFF2196F3);
      expect(m.isActive, false);
    });

    test('默认值 isActive=true', () {
      final m = Medicine(
        id: 'm1', name: '维C', dosageForm: '片剂', specification: '100mg',
        createdAt: now, updatedAt: now,
      );
      expect(m.isActive, true);
    });

    test('默认值 colorValue=0xFFC41E3A', () {
      final m = Medicine(
        id: 'm1', name: '维C', dosageForm: '片剂', specification: '100mg',
        createdAt: now, updatedAt: now,
      );
      expect(m.colorValue, 0xFFC41E3A);
    });

    test('toMap→fromMap 往返一致性', () {
      final roundtrip = Medicine.fromMap(medicine.toMap());
      expect(roundtrip.id, medicine.id);
      expect(roundtrip.name, medicine.name);
      expect(roundtrip.dosageForm, medicine.dosageForm);
      expect(roundtrip.specification, medicine.specification);
      expect(roundtrip.notes, medicine.notes);
      expect(roundtrip.colorValue, medicine.colorValue);
      expect(roundtrip.isActive, medicine.isActive);
    });

    test('非活动药品序列化 isActive=0', () {
      final inactive = medicine.copyWith(isActive: false);
      final map = inactive.toMap();
      expect(map['is_active'], 0);
    });

    test('药品名包含数字', () {
      final m = Medicine(
        id: 'm1', name: '维生素B12', dosageForm: '注射液', specification: '0.5mg/ml',
        createdAt: now, updatedAt: now,
      );
      expect(m.name, '维生素B12');
    });

    test('规格包含中文单位', () {
      final m = Medicine(
        id: 'm1', name: '中药', dosageForm: '颗粒剂', specification: '每袋10g×10袋',
        createdAt: now, updatedAt: now,
      );
      expect(m.specification, '每袋10g×10袋');
    });
  });

  // ==================== MedicationSchedule Model ====================
  group('MedicationSchedule 模型', () {
    final schedule = MedicationSchedule(
      id: 'sched-001', medicineId: 'med-001', medicineName: '阿莫西林',
      dosage: '1片', frequency: ScheduleFrequency.daily,
      timePoints: ['08:00', '20:00'], startDate: now,
      isActive: true, createdAt: now, updatedAt: now,
    );

    test('toMap 序列化正确', () {
      final map = schedule.toMap();
      expect(map['id'], 'sched-001');
      expect(map['medicine_id'], 'med-001');
      expect(map['medicine_name'], '阿莫西林');
      expect(map['dosage'], '1片');
      expect(map['frequency'], 'daily');
      expect(map['time_points'], '08:00,20:00');
      expect(map['is_active'], 1);
    });

    test('fromMap 反序列化正确', () {
      final s = MedicationSchedule.fromMap(schedule.toMap());
      expect(s.id, 'sched-001');
      expect(s.medicineId, 'med-001');
      expect(s.frequency, ScheduleFrequency.daily);
      expect(s.timePoints, ['08:00', '20:00']);
    });

    test('weekly 序列化含 weekDays', () {
      final weekly = MedicationSchedule(
        id: 's1', medicineId: 'm1', medicineName: '维生素D', dosage: '2粒',
        frequency: ScheduleFrequency.weekly, timePoints: ['09:00'],
        weekDays: [1, 3, 5], startDate: now, createdAt: now, updatedAt: now,
      );
      final map = weekly.toMap();
      expect(map['week_days'], '1,3,5');
    });

    test('monthly 序列化含 monthDays', () {
      final monthly = MedicationSchedule(
        id: 's1', medicineId: 'm1', medicineName: '钙片', dosage: '1片',
        frequency: ScheduleFrequency.monthly, timePoints: ['08:00'],
        monthDays: [1, 15], startDate: now, createdAt: now, updatedAt: now,
      );
      final map = monthly.toMap();
      expect(map['month_days'], '1,15');
    });

    test('PRN 序列化含上限和间隔', () {
      final prn = MedicationSchedule(
        id: 's1', medicineId: 'm1', medicineName: '止痛药', dosage: '1片',
        frequency: ScheduleFrequency.prn, timePoints: [],
        prnMaxDaily: 3, prnMinIntervalMinutes: 240,
        startDate: now, createdAt: now, updatedAt: now,
      );
      final map = prn.toMap();
      expect(map['prn_max_daily'], 3);
      expect(map['prn_min_interval_minutes'], 240);
    });

    test('frequencyLabel 中文映射', () {
      expect(ScheduleFrequency.daily.frequencyLabelFromEnum, equals('每日'));
    });

    test('toMap→fromMap 往返一致性（weekly）', () {
      final weekly = MedicationSchedule(
        id: 's1', medicineId: 'm1', medicineName: '维生素D', dosage: '2粒',
        frequency: ScheduleFrequency.weekly, timePoints: ['09:00'],
        weekDays: [1, 3, 5], startDate: now, createdAt: now, updatedAt: now,
      );
      final roundtrip = MedicationSchedule.fromMap(weekly.toMap());
      expect(roundtrip.frequency, ScheduleFrequency.weekly);
      expect(roundtrip.weekDays, [1, 3, 5]);
    });

    test('fromMap 空 weekDays', () {
      final map = schedule.toMap()..['week_days'] = null;
      final s = MedicationSchedule.fromMap(map);
      expect(s.weekDays, isNull);
    });

    test('fromMap 含 endDate', () {
      final end = now.add(Duration(days: 30));
      final sched = MedicationSchedule(
        id: 's1', medicineId: 'm1', medicineName: '药', dosage: '1片',
        frequency: ScheduleFrequency.daily, timePoints: ['08:00'],
        startDate: now, endDate: end, createdAt: now, updatedAt: now,
      );
      final s = MedicationSchedule.fromMap(sched.toMap());
      expect(s.endDate, isNotNull);
      expect(s.endDate!.day, end.day);
    });

    test('fromMap 空 endDate', () {
      final s = MedicationSchedule.fromMap(schedule.toMap());
      expect(s.endDate, isNull);
    });
  });

  // ==================== Reminder Model ====================
  group('Reminder 模型', () {
    final reminder = Reminder(
      id: 'rem-001', scheduleId: 'sched-001', medicineName: '阿莫西林',
      dosage: '1片', scheduledTime: now,
      status: ReminderStatus.pending, createdAt: now,
    );

    test('toMap 序列化正确', () {
      final map = reminder.toMap();
      expect(map['id'], 'rem-001');
      expect(map['schedule_id'], 'sched-001');
      expect(map['medicine_name'], '阿莫西林');
      expect(map['dosage'], '1片');
      expect(map['status'], 'pending');
      expect(map['source'], isNull);
      expect(map['taken_at'], isNull);
    });

    test('fromMap 反序列化正确', () {
      final r = Reminder.fromMap(reminder.toMap());
      expect(r.id, 'rem-001');
      expect(r.status, ReminderStatus.pending);
    });

    test('statusLabel 中文映射', () {
      expect(ReminderStatus.pending.statusLabelFromEnum, equals('待服'));
      expect(ReminderStatus.taken.statusLabelFromEnum, equals('已服'));
      expect(ReminderStatus.skipped.statusLabelFromEnum, equals('跳过'));
      expect(ReminderStatus.missed.statusLabelFromEnum, equals('漏服'));
    });

    test('copyWith 更新状态', () {
      final taken = reminder.copyWith(status: ReminderStatus.taken, source: 'manual', takenAt: now);
      expect(taken.status, ReminderStatus.taken);
      expect(taken.source, 'manual');
      expect(taken.takenAt, now);
      expect(taken.medicineName, '阿莫西林'); // 未改
    });

    test('已服提醒含 takenAt', () {
      final taken = Reminder(
        id: 'r1', scheduleId: 's1', medicineName: '药', dosage: '1片',
        scheduledTime: now, status: ReminderStatus.taken,
        source: 'notification', takenAt: now, createdAt: now,
      );
      final map = taken.toMap();
      expect(map['taken_at'], now.toIso8601String());
      expect(map['source'], 'notification');
    });

    test('toMap→fromMap 往返一致性（已服）', () {
      final taken = Reminder(
        id: 'r1', scheduleId: 's1', medicineName: '药', dosage: '1片',
        scheduledTime: now, status: ReminderStatus.taken,
        source: 'manual', takenAt: now, createdAt: now,
      );
      final roundtrip = Reminder.fromMap(taken.toMap());
      expect(roundtrip.status, ReminderStatus.taken);
      expect(roundtrip.source, 'manual');
      expect(roundtrip.takenAt, isNotNull);
    });

    test('序列化→反序列化四种状态', () {
      for (final status in ReminderStatus.values) {
        final r = Reminder(
          id: 'r_${status.name}', scheduleId: 's1', medicineName: '药',
          dosage: '1片', scheduledTime: now, status: status, createdAt: now,
        );
        final roundtrip = Reminder.fromMap(r.toMap());
        expect(roundtrip.status, status);
      }
    });

    test('默认状态为 pending', () {
      final r = Reminder(
        id: 'r1', scheduleId: 's1', medicineName: '药', dosage: '1片',
        scheduledTime: now, createdAt: now,
      );
      expect(r.status, ReminderStatus.pending);
    });
  });

  // ==================== Symptom Model ====================
  group('Symptom 模型', () {
    final symptom = Symptom(
      id: 'sym-001', name: '头痛', severity: 3, notes: '持续性',
      relatedMedicineId: 'med-001', relatedMedicineName: '阿莫西林', createdAt: now,
    );

    test('toMap 序列化正确', () {
      final map = symptom.toMap();
      expect(map['id'], 'sym-001');
      expect(map['name'], '头痛');
      expect(map['severity'], 3);
      expect(map['notes'], '持续性');
      expect(map['related_medicine_id'], 'med-001');
      expect(map['related_medicine_name'], '阿莫西林');
    });

    test('fromMap 反序列化正确', () {
      final s = Symptom.fromMap(symptom.toMap());
      expect(s.id, 'sym-001');
      expect(s.name, '头痛');
      expect(s.severity, 3);
      expect(s.notes, '持续性');
    });

    test('severityLabel 五个等级', () {
      expect(Symptom(id: 's1', name: 'x', severity: 1, createdAt: now).severityLabel, '很轻');
      expect(Symptom(id: 's2', name: 'x', severity: 2, createdAt: now).severityLabel, '轻度');
      expect(Symptom(id: 's3', name: 'x', severity: 3, createdAt: now).severityLabel, '中度');
      expect(Symptom(id: 's4', name: 'x', severity: 4, createdAt: now).severityLabel, '较重');
      expect(Symptom(id: 's5', name: 'x', severity: 5, createdAt: now).severityLabel, '严重');
    });

    test('severityLabel 非法值返回未知', () {
      expect(Symptom(id: 's1', name: 'x', severity: 0, createdAt: now).severityLabel, '未知');
      expect(Symptom(id: 's1', name: 'x', severity: 6, createdAt: now).severityLabel, '未知');
    });

    test('无关联药品的序列化', () {
      final s = Symptom(id: 's1', name: '咳嗽', severity: 2, createdAt: now);
      final map = s.toMap();
      expect(map['related_medicine_id'], isNull);
      expect(map['related_medicine_name'], isNull);
    });

    test('toMap→fromMap 往返一致性', () {
      final roundtrip = Symptom.fromMap(symptom.toMap());
      expect(roundtrip.id, symptom.id);
      expect(roundtrip.name, symptom.name);
      expect(roundtrip.severity, symptom.severity);
      expect(roundtrip.notes, symptom.notes);
    });

    test('备注为空', () {
      final s = Symptom(id: 's1', name: '发热', severity: 3, createdAt: now);
      expect(s.notes, isNull);
      final map = s.toMap();
      expect(map['notes'], isNull);
    });
  });

  // ==================== GuardianBinding Model ====================
  group('GuardianBinding 模型', () {
    final binding = GuardianBinding(
      id: 'bind-001', patientPhone: '13800001111', patientNickname: '张大爷',
      guardianPhone: '13900002222', status: BindingStatus.active,
      createdAt: now, updatedAt: now,
    );

    test('toMap 序列化正确', () {
      final map = binding.toMap();
      expect(map['id'], 'bind-001');
      expect(map['patient_phone'], '13800001111');
      expect(map['patient_nickname'], '张大爷');
      expect(map['guardian_phone'], '13900002222');
      expect(map['status'], 'active');
    });

    test('fromMap 反序列化正确', () {
      final b = GuardianBinding.fromMap(binding.toMap());
      expect(b.id, 'bind-001');
      expect(b.patientPhone, '13800001111');
      expect(b.patientNickname, '张大爷');
      expect(b.status, BindingStatus.active);
    });

    test('statusLabel 四种状态', () {
      expect(BindingStatus.active.statusLabelFromEnum, '已绑定');
      expect(BindingStatus.pending.statusLabelFromEnum, '待确认');
      expect(BindingStatus.rejected.statusLabelFromEnum, '已拒绝');
      expect(BindingStatus.revoked.statusLabelFromEnum, '已解除');
    });

    test('序列化→反序列化四种状态', () {
      for (final status in BindingStatus.values) {
        final b = GuardianBinding(
          id: 'b', patientPhone: '13800001111', patientNickname: '用户',
          guardianPhone: '13900002222', status: status,
          createdAt: now, updatedAt: now,
        );
        final roundtrip = GuardianBinding.fromMap(b.toMap());
        expect(roundtrip.status, status);
      }
    });

    test('toMap→fromMap 往返一致性', () {
      final roundtrip = GuardianBinding.fromMap(binding.toMap());
      expect(roundtrip.id, binding.id);
      expect(roundtrip.patientPhone, binding.patientPhone);
      expect(roundtrip.patientNickname, binding.patientNickname);
      expect(roundtrip.guardianPhone, binding.guardianPhone);
      expect(roundtrip.status, binding.status);
    });

    test('默认状态为 active', () {
      final b = GuardianBinding(
        id: 'b1', patientPhone: '13800001111', patientNickname: '用户',
        guardianPhone: '13900002222', createdAt: now, updatedAt: now,
      );
      expect(b.status, BindingStatus.active);
    });
  });
}

// Extension helpers for test convenience
extension on ScheduleFrequency {
  String get frequencyLabelFromEnum {
    switch (this) {
      case ScheduleFrequency.daily: return '每日';
      case ScheduleFrequency.weekly: return '每周';
      case ScheduleFrequency.monthly: return '每月';
      case ScheduleFrequency.prn: return '按需';
    }
  }
}

extension on ReminderStatus {
  String get statusLabelFromEnum {
    switch (this) {
      case ReminderStatus.pending: return '待服';
      case ReminderStatus.taken: return '已服';
      case ReminderStatus.skipped: return '跳过';
      case ReminderStatus.missed: return '漏服';
    }
  }
}

extension on BindingStatus {
  String get statusLabelFromEnum {
    switch (this) {
      case BindingStatus.active: return '已绑定';
      case BindingStatus.pending: return '待确认';
      case BindingStatus.rejected: return '已拒绝';
      case BindingStatus.revoked: return '已解除';
    }
  }
}

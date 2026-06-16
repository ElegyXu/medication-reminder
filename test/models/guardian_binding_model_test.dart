import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/models/guardian_binding.dart';

void main() {
  group('GuardianBinding model', () {
    test('fromMap with all fields', () {
      final createdAt = DateTime.parse('2026-06-16T10:00:00');
      final updatedAt = DateTime.parse('2026-06-16T11:00:00');
      final gb = GuardianBinding.fromMap({
        'id': 'gb-001',
        'patient_phone': '13800138000',
        'patient_nickname': '张大爷',
        'guardian_phone': '13900139000',
        'status': 'active',
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      });
      expect(gb.id, 'gb-001');
      expect(gb.patientPhone, '13800138000');
      expect(gb.patientNickname, '张大爷');
      expect(gb.guardianPhone, '13900139000');
      expect(gb.status, BindingStatus.active);
      expect(gb.createdAt, createdAt);
      expect(gb.updatedAt, updatedAt);
    });

    test('toMap produces correct map', () {
      final gb = GuardianBinding(
        id: 'gb-002',
        patientPhone: '15800158000',
        patientNickname: '李奶奶',
        guardianPhone: '15900159000',
        status: BindingStatus.pending,
        createdAt: DateTime.parse('2026-06-16T09:00:00'),
        updatedAt: DateTime.parse('2026-06-16T09:30:00'),
      );
      final map = gb.toMap();
      expect(map['id'], 'gb-002');
      expect(map['patient_phone'], '15800158000');
      expect(map['guardian_phone'], '15900159000');
      expect(map['status'], 'pending');
    });

    test('statusLabel for all statuses', () {
      final now = DateTime.now();
      GuardianBinding gb(BindingStatus s) => GuardianBinding(
        id: 'x', patientPhone: '1', patientNickname: 'n',
        guardianPhone: '2', status: s, createdAt: now, updatedAt: now,
      );
      expect(gb(BindingStatus.active).statusLabel, '已绑定');
      expect(gb(BindingStatus.pending).statusLabel, '待确认');
      expect(gb(BindingStatus.rejected).statusLabel, '已拒绝');
      expect(gb(BindingStatus.revoked).statusLabel, '已解除');
    });

    test('default status is active', () {
      final now = DateTime.now();
      final gb = GuardianBinding(
        id: 'gb-003', patientPhone: '1', patientNickname: 'n',
        guardianPhone: '2', createdAt: now, updatedAt: now,
      );
      expect(gb.status, BindingStatus.active);
    });
  });
}

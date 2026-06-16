import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/models/symptom.dart';

void main() {
  group('Symptom model', () {
    test('fromMap with all fields', () {
      final now = DateTime.parse('2026-06-16T12:00:00');
      final m = Symptom.fromMap({
        'id': 'sym-001',
        'name': '头痛',
        'severity': 3,
        'notes': '持续2小时',
        'related_medicine_id': 'med-001',
        'related_medicine_name': '布洛芬',
        'created_at': now.toIso8601String(),
      });
      expect(m.id, 'sym-001');
      expect(m.name, '头痛');
      expect(m.severity, 3);
      expect(m.notes, '持续2小时');
      expect(m.relatedMedicineId, 'med-001');
      expect(m.relatedMedicineName, '布洛芬');
      expect(m.createdAt, now);
    });

    test('fromMap with minimal fields (nullable null)', () {
      final m = Symptom.fromMap({
        'id': 'sym-002',
        'name': '头晕',
        'severity': 1,
        'notes': null,
        'related_medicine_id': null,
        'related_medicine_name': null,
        'created_at': '2026-06-16T08:00:00',
      });
      expect(m.notes, isNull);
      expect(m.relatedMedicineId, isNull);
      expect(m.relatedMedicineName, isNull);
    });

    test('toMap produces correct map', () {
      final m = Symptom(
        id: 'sym-001',
        name: '发热',
        severity: 4,
        notes: '38.5°C',
        relatedMedicineId: 'med-002',
        relatedMedicineName: '退烧药',
        createdAt: DateTime.parse('2026-06-16T14:00:00'),
      );
      final map = m.toMap();
      expect(map['id'], 'sym-001');
      expect(map['name'], '发热');
      expect(map['severity'], 4);
      expect(map['notes'], '38.5°C');
      expect(map['related_medicine_id'], 'med-002');
      expect(map['related_medicine_name'], '退烧药');
    });

    test('severityLabel returns correct labels', () {
      final now = DateTime.now();
      Symptom s(int sev) => Symptom(id: 's', name: '测试', severity: sev, createdAt: now);
      expect(s(1).severityLabel, '很轻');
      expect(s(2).severityLabel, '轻度');
      expect(s(3).severityLabel, '中度');
      expect(s(4).severityLabel, '较重');
      expect(s(5).severityLabel, '严重');
      expect(s(0).severityLabel, '未知');
      expect(s(6).severityLabel, '未知');
    });
  });
}

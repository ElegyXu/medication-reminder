import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/models/medicine.dart';

void main() {
  group('Medicine model', () {
    test('fromMap creates valid Medicine', () {
      final now = DateTime.now();
      final map = {
        'id': 'med-001',
        'name': '阿莫西林',
        'dosage_form': '胶囊',
        'specification': '500mg',
        'notes': '饭后服用',
        'color_value': 0xFFC62828,
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      final m = Medicine.fromMap(map);
      expect(m.id, 'med-001');
      expect(m.name, '阿莫西林');
      expect(m.dosageForm, '胶囊');
      expect(m.specification, '500mg');
      expect(m.notes, '饭后服用');
      expect(m.colorValue, 0xFFC62828);
      expect(m.isActive, true);
    });

    test('toMap produces correct map', () {
      final now = DateTime.parse('2026-06-16T10:00:00.000');
      final m = Medicine(
        id: 'med-001',
        name: '阿莫西林',
        dosageForm: '胶囊',
        specification: '500mg',
        colorValue: 0xFF2196F3,
        isActive: false,
        createdAt: now,
        updatedAt: now,
      );
      final map = m.toMap();
      expect(map['id'], 'med-001');
      expect(map['is_active'], 0);
      expect(map['color_value'], 0xFF2196F3);
    });

    test('copyWith preserves unchanged fields', () {
      final now = DateTime.now();
      final original = Medicine(
        id: 'med-001', name: '原始', dosageForm: '片剂',
        specification: '100mg', createdAt: now, updatedAt: now,
      );
      final copied = original.copyWith(name: '修改后');
      expect(copied.id, 'med-001');
      expect(copied.name, '修改后');
      expect(copied.dosageForm, '片剂');
    });

    test('default colorValue is primary red', () {
      final now = DateTime.now();
      final m = Medicine(
        id: 'med-001', name: '测试', dosageForm: '片剂',
        specification: '100mg', createdAt: now, updatedAt: now,
      );
      expect(m.colorValue, 0xFFC62828);
    });
  });
}

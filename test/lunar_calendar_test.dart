import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/utils/lunar_calendar.dart';

void main() {
  group('LunarCalendar', () {
    test('getLunarDate returns non-empty for 2026-06-16', () {
      final result = LunarCalendar.getLunarDate(DateTime(2026, 6, 16));
      expect(result.isNotEmpty, true);
      expect(result, contains('年'));
      expect(result, contains('月'));
    });

    test('getLunarDate handles boundary dates', () {
      final dates = [
        DateTime(2024, 2, 10),
        DateTime(2025, 1, 29),
        DateTime(2020, 1, 1),
        DateTime(2026, 12, 31),
        DateTime(2000, 1, 1),
      ];
      for (final d in dates) {
        final result = LunarCalendar.getLunarDate(d);
        expect(result.isNotEmpty, true,
            reason: 'Failed for $d');
        expect(result.contains('年') && result.contains('月'), true,
            reason: 'Bad format for $d: $result');
      }
    });

    test('getLunarDate handles today gracefully', () {
      final result = LunarCalendar.getLunarDate(DateTime.now());
      expect(result.isNotEmpty, true);
      print('Today lunar: $result');
    });
  });
}

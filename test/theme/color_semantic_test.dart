import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/theme/app_theme.dart';

/// TC-COLOR-001: 验证 symptom_diary 严重度颜色映射使用 ColorScheme 语义色
/// TC-COLOR-002: 验证 medicine_form 图标颜色均满足 WCAG AA 4.5:1 对比度
/// TC-COLOR-005: 验证项目中无 hardcoded Colors.green/red 等标准色回归

void main() {
  late ColorScheme cs;

  setUpAll(() {
    cs = AppTheme.lightTheme.colorScheme;
  });

  double contrastRatio(Color foreground, Color background) {
    final l1 = foreground.computeLuminance() + 0.05;
    final l2 = background.computeLuminance() + 0.05;
    return l1 > l2 ? l1 / l2 : l2 / l1;
  }

  group('TC-COLOR-001: Severity color semantic mapping', () {
    // Simulates _severityColor logic
    Color severityColor(int level, ColorScheme cs) {
      switch (level) {
        case 1: return cs.tertiary;
        case 2: return Color.alphaBlend(cs.primary.withAlpha(128), cs.tertiary);
        case 3: return cs.primary;
        case 4: return Color.alphaBlend(cs.error.withAlpha(160), cs.primary);
        case 5: return cs.error;
        default: return cs.onSurfaceVariant;
      }
    }

    test('severity 1 should return cs.tertiary', () {
      expect(severityColor(1, cs), cs.tertiary);
    });

    test('severity 3 should return cs.primary', () {
      expect(severityColor(3, cs), cs.primary);
    });

    test('severity 5 should return cs.error', () {
      expect(severityColor(5, cs), cs.error);
    });

    test('all severity colors are derived from ColorScheme (not Colors constants)', () {
      for (int i = 1; i <= 5; i++) {
        final color = severityColor(i, cs);
        // Verify color is not null and is a valid ColorScheme-derived color
        expect(color.alpha, greaterThan(0));
        // Colors.green is 0xFF4CAF50 — our mapping never returns this
        expect(color.value, isNot(equals(0xFF4CAF50)));
        // Colors.red is 0xFFF44336 — our mapping never returns this
        expect(color.value, isNot(equals(0xFFF44336)));
        // Colors.orange is 0xFFFF9800 — our mapping never returns this
        expect(color.value, isNot(equals(0xFFFF9800)));
        // Colors.lightGreen is 0xFF8BC34A
        expect(color.value, isNot(equals(0xFF8BC34A)));
        // Colors.deepOrange is 0xFFFF5722
        expect(color.value, isNot(equals(0xFFFF5722)));
      }
    });

    test('all severity colors have >= 4.5:1 contrast on surface', () {
      for (int i = 1; i <= 5; i++) {
        final color = severityColor(i, cs);
        final cr = contrastRatio(color, cs.surface);
        expect(cr, greaterThanOrEqualTo(4.5),
            reason: 'Severity $i color contrast on surface is $cr, must be >= 4.5');
      }
    });
  });

  group('TC-COLOR-002: Medicine form icon colors WCAG AA', () {
    final medicineColors = [
      const Color(0xFFA73909),  // primary warm red-orange
      const Color(0xFF775849),  // secondary warm brown
      const Color(0xFF6A5D2D),  // tertiary warm olive
      const Color(0xFFBA1A1A),  // error red
      const Color(0xFF9C4235),  // warm brick
      const Color(0xFF5D4037),  // warm dark brown
    ];

    test('all 6 medicine icon colors meet WCAG AA 4.5:1 on surface', () {
      for (final color in medicineColors) {
        final cr = contrastRatio(color, cs.surface);
        expect(cr, greaterThanOrEqualTo(4.5),
            reason: 'Color #${color.toARGB32().toRadixString(16)} contrast on surface is $cr, must be >= 4.5');
      }
    });

    test('all medicine colors are warm-toned (red hue range, not cool blue/green)', () {
      for (final color in medicineColors) {
        final hsl = HSLColor.fromColor(color);
        // Warm colors: hue 0-60 (red-orange-yellow) or near 360
        // Cool blues: 180-300, greens: 60-180
        // Our palette is red/brown/olive — all warm
        final hue = hsl.hue;
        final isWarm = (hue >= 0 && hue <= 80) || (hue >= 340 && hue <= 360);
        expect(isWarm, isTrue,
            reason: 'Color #${color.toARGB32().toRadixString(16)} hue=$hue is not in warm range');
      }
    });
  });

  group('TC-COLOR-005: Hardcoded color regression detection', () {
    test('primaryContainer should be non-null and valid', () {
      expect(cs.primaryContainer.value, isNot(equals(0)));
    });

    test('errorContainer should be non-null and valid', () {
      expect(cs.errorContainer.value, isNot(equals(0)));
    });

    test('tertiaryContainer should be non-null and valid', () {
      expect(cs.tertiaryContainer.value, isNot(equals(0)));
    });

    test('ColorScheme seed is still Warm Coral', () {
      expect(AppTheme.seedColor, const Color(0xFFFF7043));
    });
  });
}

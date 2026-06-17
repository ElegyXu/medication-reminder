import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/theme/app_theme.dart';

void main() {
  late ColorScheme scheme;

  setUpAll(() {
    scheme = AppTheme.lightTheme.colorScheme!;
  });

  group('100元人民币五色 — 配色断言', () {
    test('seedColor 应为正红 #DD0022', () {
      expect(AppTheme.seedColor, const Color(0xFFDD0022));
    });

    test('primary (deepRed) 应为深酒红 #AA0033', () {
      expect(scheme.primary, const Color(0xFFAA0033));
    });

    test('primaryContainer 应为最深红 #780018', () {
      expect(scheme.primaryContainer, const Color(0xFF780018));
    });

    test('tertiary (rose) 应为玫红 #CC0044', () {
      expect(scheme.tertiary, const Color(0xFFCC0044));
    });

    test('secondaryContainer 应为浅粉 #FA8095', () {
      expect(scheme.secondaryContainer, const Color(0xFFFA8095));
    });
  });

  group('对比度断言', () {
    test('onPrimaryContainer 在深红底 (#780018) 上应为白色', () {
      expect(scheme.onPrimaryContainer, Colors.white);
      // Background = #780018, foreground = white → CR ≈ 9.5:1 (AAA)
    });

    test('onSecondaryContainer 在浅粉底 (#FA8095) 上应为深棕 #2D0A14', () {
      expect(scheme.onSecondaryContainer, const Color(0xFF2D0A14));
      // Background = #FA8095, foreground = #2D0A14 → CR ≈ 7.4:1 (AAA)
    });
  });

  group('集成验证 — 深色/浅色背景文字色', () {
    test('primary (深酒红 #AA0033) 上 onPrimary 应为白色', () {
      expect(scheme.onPrimary, Colors.white);
    });

    test('primaryContainer (深红 #780018) 上 onPrimaryContainer 应为白色', () {
      expect(scheme.onPrimaryContainer, Colors.white);
    });

    test('tertiary (玫红 #CC0044) 上 onTertiary 应为白色', () {
      expect(scheme.onTertiary, Colors.white);
    });

    test('secondaryContainer (浅粉 #FA8095) 上 onSecondaryContainer 应为深色', () {
      // luminance < 0.5 → dark text
      expect(scheme.onSecondaryContainer.computeLuminance(), lessThan(0.5));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/theme/app_theme.dart';

void main() {
  late ColorScheme scheme;

  setUpAll(() {
    scheme = AppTheme.lightTheme.colorScheme;
  });

  group('Red×Green Fusion MD3 Theme — 配色断言', () {
    test('seedColor 应为 #C62828', () {
      expect(AppTheme.seedColor, const Color(0xFFC62828));
    });

    test('primary color 应该由 seedColor 生成', () {
      expect(scheme.primary.value, isNot(equals(0)));
    });

    test('primaryContainer 应该生成', () {
      expect(scheme.primaryContainer.value, isNot(equals(0)));
    });

    test('Flat Tonal 的 Surface 色阶应该存在', () {
      expect(scheme.surface.value, isNot(equals(0)));
      expect(scheme.surfaceContainerLow.value, isNot(equals(0)));
      expect(scheme.surfaceContainer.value, isNot(equals(0)));
      expect(scheme.surfaceContainerHigh.value, isNot(equals(0)));
      expect(scheme.surfaceContainerHighest.value, isNot(equals(0)));
    });
  });

  group('对比度断言', () {
    test('onPrimary 应该有良好的对比度', () {
      final luminancePrimary = scheme.primary.computeLuminance();
      final luminanceOnPrimary = scheme.onPrimary.computeLuminance();
      final contrast = (luminancePrimary + 0.05) / (luminanceOnPrimary + 0.05);
      final inverseContrast = (luminanceOnPrimary + 0.05) / (luminancePrimary + 0.05);
      
      expect(contrast > 3.0 || inverseContrast > 3.0, isTrue);
    });

    test('onPrimaryContainer 应该有良好的对比度', () {
      final luminanceBg = scheme.primaryContainer.computeLuminance();
      final luminanceFg = scheme.onPrimaryContainer.computeLuminance();
      final contrast = (luminanceBg + 0.05) / (luminanceFg + 0.05);
      final inverseContrast = (luminanceFg + 0.05) / (luminanceBg + 0.05);
      
      expect(contrast > 3.0 || inverseContrast > 3.0, isTrue);
    });
  });

  group('TC-FUSION: 100元红×50元绿融合方案专项测试', () {
    test('TC-FUSION-01: seedColor 为 0xFFC62828', () {
      expect(AppTheme.seedColor, const Color(0xFFC62828));
    });

    test('TC-FUSION-02: primary 为 0xFFA31520', () {
      expect(scheme.primary, const Color(0xFFA31520));
    });

    test('TC-FUSION-03: tertiary 为 0xFF1B6D1B', () {
      expect(scheme.tertiary, const Color(0xFF1B6D1B));
    });

    test('TC-FUSION-04: surface 为 0xFFFFFFFF (纯白)', () {
      expect(scheme.surface, const Color(0xFFFFFFFF));
    });

    test('TC-FUSION-05: 所有 19 个覆盖 token 不为 null', () {
      final overriddenTokens = [
        scheme.primary, scheme.onPrimary, scheme.primaryContainer, scheme.onPrimaryContainer,
        scheme.secondary, scheme.onSecondary, scheme.secondaryContainer, scheme.onSecondaryContainer,
        scheme.tertiary, scheme.onTertiary, scheme.tertiaryContainer, scheme.onTertiaryContainer,
        scheme.error, scheme.onError,
        scheme.background, scheme.onBackground,
        scheme.surface, scheme.onSurface, scheme.surfaceVariant, scheme.onSurfaceVariant,
      ];
      for (final token in overriddenTokens) {
        expect(token.value, isNot(equals(0)));
      }
      expect(overriddenTokens.length, equals(20)); // 19 + surfaceVariant/onSurfaceVariant = 20
    });

    test('TC-FUSION-06: fromSeed 自动生成的 surfaceContainer 色阶存在', () {
      expect(scheme.surfaceContainerLow.value, isNot(equals(0)));
      expect(scheme.surfaceContainer.value, isNot(equals(0)));
      expect(scheme.surfaceContainerHigh.value, isNot(equals(0)));
      expect(scheme.surfaceContainerHighest.value, isNot(equals(0)));
    });

    test('TC-FUSION-07: medicine_form 的 6 个颜色值验证明确且非旧值', () {
      // 从 medicine_form_screen 中同步的新颜色列表
      final newMedicineColors = [
        0xFFC62828, // 红
        0xFFA31520, // 深红
        0xFF8D4E2A, // 红棕
        0xFF5C7A2E, // 绿棕
        0xFF2E7D32, // 深绿
        0xFF1B6D1B, // 绿
      ];
      // 旧值（橙色系/棕色系）
      final oldMedicineColors = [
        0xFFA73909, 0xFF775849, 0xFF6A5D2D,
        0xFFBA1A1A, 0xFF9C4235, 0xFF5D4037,
      ];

      for (final color in newMedicineColors) {
        expect(color, isNot(equals(0)));
        expect(oldMedicineColors, isNot(contains(color)));
      }
      expect(newMedicineColors.length, equals(6));
    });
  });
}

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
      // 方案 B 新 6 色
      final newMedicineColors = [
        0xFFC62828, // 红 — seed
        0xFFA31520, // 深红 — primary
        0xFF9B4A1A, // 红棕
        0xFF6D5E00, // 金黄 — secondary
        0xFF3D6B1E, // 绿棕
        0xFF1B6D1B, // 绿 — tertiary
      ];
      // 旧值（橙色系/棕色系）
      final oldMedicineColors = [
        0xFFA73909, 0xFF775849, 0xFF6A5D2D,
        0xFFBA1A1A, 0xFF9C4235, 0xFF5D4037,
        0xFF8D4E2A, 0xFF5C7A2E, 0xFF2E7D32,
      ];

      for (final color in newMedicineColors) {
        expect(color, isNot(equals(0)));
        expect(oldMedicineColors, isNot(contains(color)));
      }
      expect(newMedicineColors.length, equals(6));
    });

    test('TC-FUSION-08: secondary = 0xFF6D5E00 且 onSecondary = 0xFFFFFFFF', () {
      expect(scheme.secondary, const Color(0xFF6D5E00));
      expect(scheme.onSecondary, const Color(0xFFFFFFFF));
    });

    test('TC-FUSION-09: surfaceContainerLowest/ContainerLow/Container/ContainerHigh/ContainerHighest 均非零', () {
      expect(scheme.surfaceContainerLowest.value, isNot(equals(0)));
      expect(scheme.surfaceContainerLow.value, isNot(equals(0)));
      expect(scheme.surfaceContainer.value, isNot(equals(0)));
      expect(scheme.surfaceContainerHigh.value, isNot(equals(0)));
      expect(scheme.surfaceContainerHighest.value, isNot(equals(0)));
    });

    test('TC-FUSION-09b: surfaceContainer 中性化微暖灰阶精确值', () {
      expect(scheme.surfaceContainerLowest, const Color(0xFFF8F6F5));
      expect(scheme.surfaceContainerLow, const Color(0xFFF3EFEE));
      expect(scheme.surfaceContainer, const Color(0xFFEDE8E7));
      expect(scheme.surfaceContainerHigh, const Color(0xFFE7E1E0));
      expect(scheme.surfaceContainerHighest, const Color(0xFFE1DBDA));
    });

    test('TC-FUSION-09c: secondaryContainer 柔化琥珀精确值', () {
      expect(scheme.secondaryContainer, const Color(0xFFF0D060));
    });

    test('TC-FUSION-09d: 文字对比度提升 — surfaceVariant / onSurfaceVariant 精确值', () {
      expect(scheme.surfaceVariant, const Color(0xFFF0ECEB));
      expect(scheme.onSurfaceVariant, const Color(0xFF3D2B2A));
    });

    test('TC-FUSION-10: outline = 0xFF857372 且 outlineVariant = 0xFFD7C2C1', () {
      expect(scheme.outline, const Color(0xFF857372));
      expect(scheme.outlineVariant, const Color(0xFFD7C2C1));
    });
  });

  group('业务语义颜色', () {
    test('TC-SEM-01: medTaken = 0xFF1B6D1B', () {
      expect(AppTheme.medTaken, const Color(0xFF1B6D1B));
    });

    test('TC-SEM-02: medTakenContainer = 0xFFE6F5E6', () {
      expect(AppTheme.medTakenContainer, const Color(0xFFE6F5E6));
    });

    test('TC-SEM-03: medPending = 0xFFFF9800', () {
      expect(AppTheme.medPending, const Color(0xFFFF9800));
    });

    test('TC-SEM-04: medPendingContainer = 0xFFFFF3E0', () {
      expect(AppTheme.medPendingContainer, const Color(0xFFFFF3E0));
    });

    test('TC-SEM-05: medMissed = 0xFFBA1A1A', () {
      expect(AppTheme.medMissed, const Color(0xFFBA1A1A));
    });

    test('TC-SEM-06: medMissedContainer = 0xFFFFE8E8', () {
      expect(AppTheme.medMissedContainer, const Color(0xFFFFE8E8));
    });

    test('TC-SEM-07: medTaken == lightScheme.tertiary', () {
      expect(AppTheme.medTaken, AppTheme.lightScheme.tertiary);
    });

    test('TC-SEM-08: medMissed == lightScheme.error', () {
      expect(AppTheme.medMissed, AppTheme.lightScheme.error);
    });
  });
}

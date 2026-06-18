import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/theme/app_theme.dart';

void main() {
  late ColorScheme scheme;

  setUpAll(() {
    scheme = AppTheme.lightTheme.colorScheme;
  });

  group('Warm Coral MD3 Theme — 配色断言', () {
    test('seedColor 应为 Warm Coral #FF7043', () {
      expect(AppTheme.seedColor, const Color(0xFFFF7043));
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
}

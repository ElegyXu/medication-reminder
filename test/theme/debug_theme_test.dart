import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/theme/app_theme.dart';

void main() {
  test('Debug ColorScheme and TextTheme', () {
    final theme = AppTheme.lightTheme;
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    print('=== ColorScheme (light) ===');
    print('primary: #${cs.primary.toARGB32().toRadixString(16).toUpperCase()}');
    print('onPrimary: #${cs.onPrimary.toARGB32().toRadixString(16).toUpperCase()}');
    print('surface: #${cs.surface.toARGB32().toRadixString(16).toUpperCase()}');
    print('onSurface: #${cs.onSurface.toARGB32().toRadixString(16).toUpperCase()}');
    
    print('=== TextTheme Colors ===');
    print('bodyLarge color: ${tt.bodyLarge?.color}');
    print('titleLarge color: ${tt.titleLarge?.color}');
    print('labelMedium color: ${tt.labelMedium?.color}');
  });
}

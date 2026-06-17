import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder/theme/app_theme.dart';

void main() {
  test('Print ColorScheme values', () {
    final theme = AppTheme.lightTheme;
    final cs = theme.colorScheme;

    void p(String name, Color c) {
      final hex = c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
      // ignore: avoid_print
      print('$name: #$hex (r=${c.red}, g=${c.green}, b=${c.blue})');
    }

    // ignore: avoid_print
    print('=== ColorScheme (light) ===');
    p('primary             ', cs.primary);
    p('onPrimary           ', cs.onPrimary);
    p('primaryContainer    ', cs.primaryContainer);
    p('onPrimaryContainer  ', cs.onPrimaryContainer);
    p('secondaryContainer  ', cs.secondaryContainer);
    p('onSecondaryContainer', cs.onSecondaryContainer);
    p('tertiary            ', cs.tertiary);
    p('onTertiary          ', cs.onTertiary);
    p('surface             ', cs.surface);
    p('onSurface           ', cs.onSurface);
    p('error               ', cs.error);
    p('onError             ', cs.onError);
    // ignore: avoid_print
    print('========================');
  });
}

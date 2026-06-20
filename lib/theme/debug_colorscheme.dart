import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Debug utility: prints ColorScheme tokens to console.
/// Usage: call printColorScheme() from within an existing main() or debug context.
void printColorScheme() {
  final theme = AppTheme.lightTheme;
  final cs = theme.colorScheme;

  void p(String name, Color c) {
    final hex = c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    print('$name: #$hex (r=${c.red} g=${c.green} b=${c.blue})');
  }

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
  print('========================');
}

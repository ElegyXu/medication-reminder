import 'package:flutter/material.dart';
import '../models/reminder.dart';


class AppTheme {
  // Warm Coral Palette for Healthcare App
  static const Color seedColor = Color(0xFFC62828);

  /// 方案 B：语义增强 — 34 token 全色阶 + 业务语义色
  /// seedColor #C62828 | Primary红 Secondary金 Tertiary绿
  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  ).copyWith(
    // === Primary 红 ===
    primary:                const Color(0xFFA31520),
    onPrimary:              const Color(0xFFFFFFFF),
    primaryContainer:       const Color(0xFFFFDAD5),
    onPrimaryContainer:     const Color(0xFF410005),
    // === Secondary 金 ===
    secondary:              const Color(0xFF6D5E00),
    onSecondary:            const Color(0xFFFFFFFF),
    secondaryContainer:     const Color(0xFFF0D060),
    onSecondaryContainer:   const Color(0xFF221B00),
    // === Tertiary 绿 ===
    tertiary:               const Color(0xFF1B6D1B),
    onTertiary:             const Color(0xFFFFFFFF),
    tertiaryContainer:      const Color(0xFFA5F0A3),
    onTertiaryContainer:    const Color(0xFF002106),
    // === Error ===
    error:                  const Color(0xFFBA1A1A),
    onError:                const Color(0xFFFFFFFF),
    errorContainer:         const Color(0xFFFFDAD5),
    onErrorContainer:       const Color(0xFF410005),
    // === Surface + 色阶 ===
    surface:                const Color(0xFFFFFFFF),
    onSurface:              const Color(0xFF201A1A),
    surfaceVariant:         const Color(0xFFF0ECEB),
    onSurfaceVariant:       const Color(0xFF3D2B2A),
    surfaceContainerLowest:  const Color(0xFFF8F6F5),
    surfaceContainerLow:     const Color(0xFFF3EFEE),
    surfaceContainer:        const Color(0xFFEDE8E7),
    surfaceContainerHigh:    const Color(0xFFE7E1E0),
    surfaceContainerHighest: const Color(0xFFE1DBDA),
    surfaceTint:            const Color(0xFFA31520),
    // === Background ===
    background:             const Color(0xFFFFF8F7),
    onBackground:           const Color(0xFF201A1A),
    // === Outline ===
    outline:                const Color(0xFF857372),
    outlineVariant:         const Color(0xFFD7C2C1),
    // === Inverse ===
    inverseSurface:         const Color(0xFF352F2F),
    onInverseSurface:       const Color(0xFFFAEDEC),
    // === Scrim / Shadow ===
    scrim:                  const Color(0xFF000000),
    shadow:                 const Color(0xFF000000),
  );

  /// 服药业务语义颜色
  static const medTaken            = Color(0xFF1B6D1B);
  static const medTakenContainer   = Color(0xFFE6F5E6);
  static const medPending          = Color(0xFFFF9800);
  static const medPendingContainer = Color(0xFFFFF3E0);
  static const medMissed           = Color(0xFFBA1A1A);
  static const medMissedContainer  = Color(0xFFFFE8E8);

  static ThemeData get lightTheme {
    final colorScheme = lightScheme;

    // ── Text Theme ──
    final tt = Typography.material2021(platform: TargetPlatform.android).englishLike;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface, // Base surface

      textTheme: tt.copyWith(
        headlineSmall: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        titleLarge: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        bodyMedium: tt.bodyMedium,
        labelMedium: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0, // Flat Tonal: no shadow on scroll
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Card (Flat Tonal) ──
      cardTheme: CardThemeData(
        elevation: 0, // No shadow
        color: colorScheme.surfaceContainerLow, // Tonal separation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── FAB (Flat Tonal) ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0, // No shadow
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── NavigationBar ──
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 65,
      ),

      // ── ElevatedButton (Flat) ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0, // No shadow
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // ── OutlinedButton ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // ── Input ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // Flat look
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),

      // ── Dialog (Flat Tonal) ──
      dialogTheme: DialogThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: colorScheme.surfaceContainerHigh,
      ),

      // ── BottomSheet (Flat Tonal) ──
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainerLow,
        dragHandleColor: colorScheme.onSurfaceVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.normal,
        ),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),

      // ── SegmentedButton ──
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primaryContainer;
            }
            return colorScheme.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimaryContainer;
            }
            return colorScheme.onSurface;
          }),
          side: WidgetStateProperty.all(BorderSide(color: colorScheme.outlineVariant)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return colorScheme.outline;
        }),
      ),

      // ── ProgressIndicator ──
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }

  static Color getStatusColor(ReminderStatus status, ColorScheme cs) {
    switch (status) {
      case ReminderStatus.taken:
        return medTaken;
      case ReminderStatus.skipped:
        return medTaken;
      case ReminderStatus.pending:
        return medPending;
      case ReminderStatus.missed:
        return medMissed;
    }
  }

  static IconData getStatusIcon(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.taken:
        return Icons.check_circle;
      case ReminderStatus.skipped:
        return Icons.skip_next;
      case ReminderStatus.pending:
        return Icons.access_time;
      case ReminderStatus.missed:
        return Icons.warning_amber;
    }
  }
}


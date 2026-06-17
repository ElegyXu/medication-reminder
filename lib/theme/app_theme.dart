import 'package:flutter/material.dart';

class AppTheme {
  // 100元人民币五色体系
  static const Color seedColor = Color(0xFFDD0022);            // 正红 → seed
  static const Color primaryColor = Color(0xFFDD0022);         // 正红（保留兼容旧引用）
  static const Color primaryContainerColor = Color(0xFF780018); // 最深红
  static const Color deepRed = Color(0xFFAA0033);              // 深酒红
  static const Color roseColor = Color(0xFFCC0044);            // 玫红
  static const Color lightPinkColor = Color(0xFFFA8095);       // 浅粉

  static const Color surfaceColor = Color(0xFFFFFBFE);
  static const Color backgroundColor = Color(0xFFFEF7F7);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: surfaceColor,
    );

    // 手动注入五色体系
    final customScheme = colorScheme.copyWith(
      primary: deepRed,
      primaryContainer: primaryContainerColor,
      onPrimaryContainer: const Color(0xFFFFFFFF),
      onSecondaryContainer: const Color(0xFF2D0A14),
      tertiary: roseColor,
      secondaryContainer: lightPinkColor,
    );

    // ── Text Theme ──
    final tt = Typography.material2021(platform: TargetPlatform.android).englishLike;

    return ThemeData(
      useMaterial3: true,
      colorScheme: customScheme,
      scaffoldBackgroundColor: backgroundColor,

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
        backgroundColor: customScheme.surface,
        foregroundColor: customScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          color: customScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: customScheme.surface,
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: deepRed,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),

      // ── NavigationBar ──
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: deepRed.withAlpha(30),
        backgroundColor: customScheme.surface,
        elevation: 2,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 65,
      ),

      // ── ElevatedButton ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepRed,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // ── OutlinedButton ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepRed,
          side: const BorderSide(color: deepRed),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // ── Input ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: deepRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: deepRed,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: customScheme.surfaceContainerHigh,
      ),

      // ── BottomSheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFBFE),
        dragHandleColor: Color(0xFF49454F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: customScheme.surfaceContainerHighest,
        selectedColor: customScheme.secondaryContainer,
        labelStyle: TextStyle(
          color: customScheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.normal,
        ),
        secondaryLabelStyle: TextStyle(
          color: customScheme.onSecondaryContainer,
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
              return customScheme.primaryContainer;
            }
            return customScheme.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return customScheme.onPrimaryContainer;
            }
            return customScheme.onSurface;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return customScheme.primary;
          return customScheme.surfaceContainerHighest;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return customScheme.primary.withAlpha(80);
          }
          return customScheme.surfaceContainerHighest;
        }),
      ),

      // ── ProgressIndicator ──
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: customScheme.primary,
        linearTrackColor: customScheme.surfaceContainerHighest,
      ),
    );
  }
}

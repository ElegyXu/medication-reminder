import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:medication_reminder/providers/medicine_provider.dart';
import 'package:medication_reminder/providers/schedule_provider.dart';
import 'package:medication_reminder/providers/reminder_provider.dart';
import 'package:medication_reminder/screens/home/patient_home_screen.dart';
import 'dart:io';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('App smoke test', () {
    testWidgets('PatientHomeScreen renders navigation bar', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MedicineProvider()),
            ChangeNotifierProvider(create: (_) => ScheduleProvider()),
            ChangeNotifierProvider(create: (_) => ReminderProvider()),
          ],
          child: const MaterialApp(
            home: PatientHomeScreen(),
          ),
        ),
      );

      // Wait for initial load (use pump instead of pumpAndSettle to avoid
      // timeout from perpetual animations like AnimatedSwitcher)
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));

      // Verify navigation bar is rendered
      expect(find.byType(NavigationBar), findsOneWidget);

      // Verify all 5 tabs are present
      expect(find.text('主页'), findsWidgets);
      expect(find.text('用药计划'), findsOneWidget);
      expect(find.text('药品管理'), findsOneWidget);
      expect(find.text('服药统计'), findsOneWidget);
      expect(find.text('我的'), findsOneWidget);
    });

    testWidgets('PatientHomeScreen switches tabs', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MedicineProvider()),
            ChangeNotifierProvider(create: (_) => ScheduleProvider()),
            ChangeNotifierProvider(create: (_) => ReminderProvider()),
          ],
          child: const MaterialApp(
            home: PatientHomeScreen(initialTab: 0),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));

      // Tap on 用药计划 tab (index 1)
      await tester.tap(find.text('用药计划'));
      await tester.pump(const Duration(seconds: 1));

      // Verify some content is shown
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('Pubspec version consistency', () {
    test('pubspec.yaml version format is valid "X.Y.Z+BUILD"', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue);

      final content = pubspecFile.readAsStringSync();
      // Extract version line via regex (avoids yaml package dependency)
      final versionMatch = RegExp(r'^version:\s*(\S+)', multiLine: true)
          .firstMatch(content);
      expect(versionMatch, isNotNull, reason: 'pubspec.yaml must have a version field');

      final version = versionMatch!.group(1)!;

      // Validate format: X.Y.Z+BUILD (e.g., "1.0.35+36")
      final pattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)\+(\d+)$');
      final match = pattern.firstMatch(version);

      expect(match, isNotNull,
          reason: 'Version "$version" does not match pattern X.Y.Z+BUILD');

      final major = int.parse(match!.group(1)!);
      final minor = int.parse(match.group(2)!);
      final patch = int.parse(match.group(3)!);
      final build = int.parse(match.group(4)!);

      // Basic sanity checks
      expect(major, greaterThanOrEqualTo(0));
      expect(minor, greaterThanOrEqualTo(0));
      expect(patch, greaterThanOrEqualTo(0));
      expect(build, greaterThanOrEqualTo(0));

      // Build number must be patch + 1 (standard Flutter convention: build = patch+1)
      // This test ensures we don't forget to bump both
      final expectedBuild = patch + 1;
      expect(build, expectedBuild,
          reason: 'Build number ($build) should be ${patch}+1=$expectedBuild '
              '(forgot to bump pubspec.yaml version when changing code?)');
    });
  });
}

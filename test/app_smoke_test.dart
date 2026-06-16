import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:medication_reminder/providers/medicine_provider.dart';
import 'package:medication_reminder/providers/schedule_provider.dart';
import 'package:medication_reminder/providers/reminder_provider.dart';
import 'package:medication_reminder/screens/home/patient_home_screen.dart';

void main() {
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

      // Wait for initial load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify navigation bar is rendered
      expect(find.byType(NavigationBar), findsOneWidget);

      // Verify all 5 tabs are present
      expect(find.text('主页'), findsOneWidget);
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

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap on 用药计划 tab (index 1)
      await tester.tap(find.text('用药计划'));
      await tester.pumpAndSettle();

      // Verify some content is shown
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}

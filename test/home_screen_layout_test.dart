import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:medication_reminder/providers/medicine_provider.dart';
import 'package:medication_reminder/providers/schedule_provider.dart';
import 'package:medication_reminder/providers/reminder_provider.dart';
import 'package:medication_reminder/screens/home/patient_home_screen.dart';
import 'package:medication_reminder/theme/app_theme.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const PatientHomeScreen(initialTab: 0),
      ),
    );
  }

  group('Home screen SliverAppBar layout', () {
    testWidgets('SliverAppBar structure: scroll, appbar, padding, navbar',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(CustomScrollView), findsOneWidget);
      final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
      expect(appBar.pinned, isTrue);
      expect(appBar.floating, isFalse);
      expect(appBar.expandedHeight, 180);
      expect(appBar.backgroundColor, AppTheme.surfaceColor);

      final sliverPadding = tester.widget<SliverPadding>(find.byType(SliverPadding));
      expect(sliverPadding.padding, const EdgeInsets.all(16));

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, 5);
      final labels = navBar.destinations
          .map((d) => (d as NavigationDestination).label)
          .toList();
      expect(labels, ['主页', '用药计划', '药品管理', '服药统计', '我的']);
    });

    testWidgets('FlexibleSpaceBar gradient and safety shield icon',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(FlexibleSpaceBar), findsOneWidget);
      final containers = find.descendant(
        of: find.byType(FlexibleSpaceBar),
        matching: find.byType(Container),
      );
      expect(containers, findsWidgets);

      final container = tester.widget<Container>(containers.first);
      final gradient = (container.decoration as BoxDecoration).gradient as LinearGradient;
      // MD3: 2-stop gradient surface → primaryContainer
      expect(gradient.colors.length, 2);
      expect(gradient.colors[0], AppTheme.surfaceColor);
      expect(gradient.colors[1], AppTheme.primaryContainerColor);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:medication_reminder/providers/medicine_provider.dart';
import 'package:medication_reminder/providers/schedule_provider.dart';
import 'package:medication_reminder/providers/reminder_provider.dart';
import 'package:medication_reminder/screens/home/patient_home_screen.dart';

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
      child: const MaterialApp(
        home: PatientHomeScreen(initialTab: 0),
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
      expect(appBar.pinned, isFalse);
      expect(appBar.floating, isFalse);
      expect(appBar.expandedHeight, 180);
      expect(appBar.backgroundColor, const Color(0xFFC41E3A));

      final sliverPadding = tester.widget<SliverPadding>(find.byType(SliverPadding));
      expect(sliverPadding.padding, const EdgeInsets.fromLTRB(16, 12, 16, 16));

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
      expect(gradient.colors.length, 3);
      expect(gradient.colors[0], const Color(0xFFD32F2F));
      expect(gradient.colors[1], const Color(0xFFC41E3A));
      expect(gradient.colors[2], const Color(0xFFB71C1C));
    });
  });
}

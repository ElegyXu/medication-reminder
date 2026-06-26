import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:medication_reminder/providers/medicine_provider.dart';
import 'package:medication_reminder/providers/schedule_provider.dart';
import 'package:medication_reminder/providers/reminder_provider.dart';
import 'package:medication_reminder/screens/home/patient_home_screen.dart';
import 'package:medication_reminder/theme/app_theme.dart';
import 'package:medication_reminder/screens/home/tabs/home_tab.dart';
import 'package:medication_reminder/screens/home/tabs/medicine_tab.dart';
import 'package:medication_reminder/screens/home/tabs/stats_tab.dart';
import 'package:medication_reminder/screens/home/tabs/profile_tab.dart';
import 'package:medication_reminder/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.databaseName = inMemoryDatabasePath;
  });

  tearDown(() async {
    await DatabaseHelper.closeDatabase();
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

  Future<void> _waitForLoaders(WidgetTester tester) async {
    await tester.pump();
    for (int i = 0; i < 50; i++) {
      final element = tester.element(find.byType(PatientHomeScreen));
      final med = element.read<MedicineProvider>();
      final sched = element.read<ScheduleProvider>();
      final rem = element.read<ReminderProvider>();
      if (!med.isLoading && !sched.isLoading && !rem.isLoading) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
  }

  group('Home screen SliverAppBar layout', () {
    testWidgets('SliverAppBar structure: scroll, appbar, padding, navbar',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(buildTestWidget());
        await _waitForLoaders(tester);

        expect(find.byType(CustomScrollView), findsOneWidget);
        final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
        expect(appBar.pinned, isTrue);
        expect(appBar.floating, isFalse);
        expect(appBar.expandedHeight, 180);
        expect(appBar.backgroundColor, AppTheme.lightTheme.colorScheme.surface);

        final sliverPadding = tester.widget<SliverPadding>(find.byType(SliverPadding));
        expect(sliverPadding.padding, const EdgeInsets.all(16));

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.destinations.length, 5);
        final labels = navBar.destinations
            .map((d) => (d as NavigationDestination).label)
            .toList();
        expect(labels, ['主页', '用药计划', '药品管理', '服药统计', '我的']);
      });
    });

    testWidgets('FlexibleSpaceBar gradient and safety shield icon',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(buildTestWidget());
        await _waitForLoaders(tester);

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
        expect(gradient.colors[0], AppTheme.lightTheme.colorScheme.surface);
        expect(gradient.colors[1], AppTheme.lightTheme.colorScheme.primaryContainer);
      });
    });

    testWidgets('Decoupled tabs layout verification: HomeTab, MedicineTab, StatsTab, ProfileTab',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(buildTestWidget());
        await _waitForLoaders(tester);

        // Verify HomeTab renders initially
        expect(find.byType(HomeTab), findsOneWidget);
        expect(find.text('已连续服药 0 天'), findsOneWidget);

        // Click on NavigationBar item to switch tabs
        final navBarFinder = find.byType(NavigationBar);
        expect(navBarFinder, findsOneWidget);

        // Switch to MedicineTab (index 2)
        await tester.tap(find.text('药品管理'));
        await _waitForLoaders(tester);
        expect(find.byType(MedicineTab), findsOneWidget);
        expect(find.text('暂无药品'), findsOneWidget);

        // Switch to StatsTab (index 3)
        await tester.tap(find.text('服药统计'));
        await _waitForLoaders(tester);
        expect(find.byType(StatsTab), findsOneWidget);
        expect(find.text('依从性健康风险评估'), findsOneWidget);

        // Switch to ProfileTab (index 4)
        await tester.tap(find.text('我的'));
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 300));
        await tester.pump();
        expect(find.byType(ProfileTab), findsOneWidget);
        expect(find.text('快捷入口'), findsOneWidget);
      });
    });
  });
}


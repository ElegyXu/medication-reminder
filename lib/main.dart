import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'database/database_helper.dart';
import 'providers/medicine_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/symptom_provider.dart';
import 'services/notification_service.dart';
import 'screens/home/patient_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库
  await DatabaseHelper().database;

  // 初始化通知服务
  await NotificationService().init();

  runApp(const MedicationReminderApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PatientHomeScreen(),
    ),
  ],
);

class MedicationReminderApp extends StatelessWidget {
  const MedicationReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => SymptomProvider()),
      ],
      child: MaterialApp.router(
        title: '家庭用药管家',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('zh'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh'),
        ],
        routerConfig: _router,
      ),
    );
  }
}

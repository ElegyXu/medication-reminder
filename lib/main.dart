import 'dart:convert';

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

class MedicationReminderApp extends StatefulWidget {
  const MedicationReminderApp({super.key});

  @override
  State<MedicationReminderApp> createState() => _MedicationReminderAppState();
}

class _MedicationReminderAppState extends State<MedicationReminderApp> {
  @override
  void initState() {
    super.initState();
    // 在首帧后注册通知回调，此时 Provider 树已就绪
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationCallback();
    });
  }

  void _setupNotificationCallback() {
    if (!mounted) return;
    final reminderProvider = context.read<ReminderProvider>();
    NotificationService().onNotificationAction = (response) async {
      final payload = response.payload;
      if (payload == null) return;
      try {
        final map = Map<String, dynamic>.from(
          (jsonDecode as dynamic)(payload) as Map,
        );
        final type = map['type'] as String?;
        final reminderId = map['reminder_id'] as String?;
        if (reminderId == null) return;

        if (type == 'reminder') {
          if (response.actionId == 'take_$reminderId') {
            // 从已加载的今日提醒中找到对应记录
            final reminder = reminderProvider.todayReminders
                .where((r) => r.id == reminderId)
                .firstOrNull;
            if (reminder != null) {
              await reminderProvider.takeMedicine(reminder);
            }
          } else if (response.actionId == 'skip_$reminderId') {
            final reminder = reminderProvider.todayReminders
                .where((r) => r.id == reminderId)
                .firstOrNull;
            if (reminder != null) {
              await reminderProvider.skipMedicine(reminder);
            }
          }
        }
      } catch (_) {
        // 解析失败不处理
      }
    };
  }

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

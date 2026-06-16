import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String reminderChannelId = 'medication_reminder';
  static const String reminderChannelName = '用药提醒';
  static const String missedChannelId = 'medication_missed';
  static const String missedChannelName = '漏服告警';

  static int _notificationIdCounter = 0;

  /// 外部注入的通知响应回调（通知点击 / Action 按钮）
  void Function(NotificationResponse response)? onNotificationAction;

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        reminderChannelId,
        reminderChannelName,
        description: '按时服药提醒',
        importance: Importance.high,
        enableVibration: true,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        missedChannelId,
        missedChannelName,
        description: '漏服告警通知',
        importance: Importance.max,
        enableVibration: true,
      ),
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    onNotificationAction?.call(response);
  }

  /// 安排用药提醒通知
  Future<int> scheduleReminder({
    required String medicineName,
    required String dosage,
    required DateTime scheduledTime,
    required String reminderId,
  }) async {
    final id = ++_notificationIdCounter;

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) {
      return -1;
    }

    final androidDetails = AndroidNotificationDetails(
      reminderChannelId,
      reminderChannelName,
      channelDescription: '按时服药提醒',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      actions: [
        AndroidNotificationAction(
          'take_$reminderId',
          '已服药',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'skip_$reminderId',
          '跳过',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
      category: AndroidNotificationCategory.reminder,
      fullScreenIntent: true,
    );

    await _plugin.zonedSchedule(
      id,
      '用药提醒',
      '$medicineName · $dosage',
      tzTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload:
          '{"type":"reminder","reminder_id":"$reminderId","medicine_name":"$medicineName","dosage":"$dosage"}',
    );

    return id;
  }

  /// 发送漏服告警
  Future<void> showMissedAlert({
    required String medicineName,
    required String dosage,
    required DateTime missedTime,
  }) async {
    final id = ++_notificationIdCounter;

    await _plugin.show(
      id,
      '漏服提醒',
      '$medicineName · $dosage 未按时服用',
      NotificationDetails(
        android: AndroidNotificationDetails(
          missedChannelId,
          missedChannelName,
          channelDescription: '漏服告警通知',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          playSound: true,
        ),
      ),
      payload: '{"type":"missed","medicine_name":"$medicineName"}',
    );
  }

  /// 取消指定ID的通知
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// 获取当前活跃的通知ID列表
  Future<List<ActiveNotification>> getActiveNotifications() async {
    return await _plugin.getActiveNotifications();
  }
}

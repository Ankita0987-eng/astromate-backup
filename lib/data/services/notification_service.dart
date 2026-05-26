import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? local,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _local = local ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;

  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

  Future<void> initialize() async {
    // ✅ Timezone init
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    // Android init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _local.initialize(
      const InitializationSettings(android: androidInit),
    );

    // ✅ Permission (important for Android 13+)
    await _messaging.requestPermission();

    // Android notification channel
    const channel = AndroidNotificationChannel(
      'cosmic_match_channel',
      'Cosmic Match',
      description: 'Love energy and horoscope reminders',
      importance: Importance.high,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  Future<String?> getToken() => _messaging.getToken();

  // ✅ FIXED SCHEDULE FUNCTION
  Future<void> scheduleDailyReminder() async {
    await _local.zonedSchedule(
      0,
      'Your cosmic energy awaits ✨',
      'Check today\'s love horoscope and compatibility insights.',
      _nextMorning(9),

      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cosmic_match_channel',
          'Cosmic Match',
          channelDescription: 'Daily horoscope reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),

      // ✅ REQUIRED FIX (YOUR ERROR SOLVED HERE)
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,

      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ✅ FIXED TIME FUNCTION
  tz.TZDateTime _nextMorning(int hour) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  // ✅ FOREGROUND NOTIFICATION FIX
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cosmic_match_channel',
          'Cosmic Match',
          channelDescription: 'Foreground notification',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
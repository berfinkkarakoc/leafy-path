import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings: initSettings);

    _initialized = true;
  }

  int _notificationIdFor(String plantId) => plantId.hashCode & 0x7FFFFFFF;

  Future<void> scheduleWateringReminder({
    required String plantId,
    required String plantName,
    required int wateringFrequencyDays,
  }) async {
    await init();

    final id = _notificationIdFor(plantId);
    await _plugin.cancel(id: id);

    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(days: wateringFrequencyDays));
    final reminderTime = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      9,
      0,
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: '💧 Sulama zamanı!',
        body: '$plantName susamış olabilir, kontrol etmeyi unutma.',
        scheduledDate: reminderTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'watering_channel',
            'Sulama Hatırlatmaları',
            channelDescription: 'Bitkilerin sulama zamanı geldiğinde hatırlatır',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      print("BİLDİRİM HATASI: $e");
    }
  }

  Future<void> cancelReminder(String plantId) async {
    await init();
    await _plugin.cancel(id: _notificationIdFor(plantId));
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const mac = DarwinInitializationSettings();
    // Provide macOS initialization when running on macOS to avoid runtime errors.
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios, macOS: mac));
    tz.initializeTimeZones();
    // This is a best-effort; timeZoneName may not map perfectly across platforms
    final now = DateTime.now();
    final locationName = now.timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      // fallback to local
      tz.setLocalLocation(tz.local);
    }
    _inited = true;
    // Request permissions on supported platforms.
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    // Android 13+ requires POST_NOTIFICATIONS runtime permission
    if (Platform.isAndroid) {
      await ph.Permission.notification.request();
    }
  }

  static int _idForTime(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return 20000 + h * 100 + m;
  }

  static Future<void> clearMedReminders() async {
    // Clear only our range 20000..20259
    for (var h = 0; h < 24; h++) {
      for (var m = 0; m < 60; m++) {
        final id = 20000 + h * 100 + m;
        await _plugin.cancel(id);
      }
    }
  }

  static Future<void> scheduleDailyConsolidatedReminders(Map<String, List<String>> timeToMeds) async {
    await init();
    await clearMedReminders();
    for (final entry in timeToMeds.entries) {
      final id = _idForTime(entry.key);
      final parts = entry.key.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      final meds = entry.value.join(', ');
      await _plugin.zonedSchedule(
        id,
        'Pills due',
        meds.isEmpty ? 'Medication reminder' : meds,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails('meds_channel', 'Medication Reminders', importance: Importance.max, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> showNow(int id, String title, String body) async {
    await init();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails('alerts_channel', 'Alerts', importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

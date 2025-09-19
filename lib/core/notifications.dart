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
      try {
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
      } on Exception {
        // Fall back to inexact scheduling if exact alarms are not permitted
        await _plugin.zonedSchedule(
          id,
          'Pills due',
          meds.isEmpty ? 'Medication reminder' : meds,
          scheduled,
          const NotificationDetails(
            android: AndroidNotificationDetails('meds_channel', 'Medication Reminders', importance: Importance.max, priority: Priority.high),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  static Future<void> scheduleDailyPreReminders(Map<String, List<String>> timeToMeds, {Duration offset = const Duration(minutes: 15)}) async {
    await init();
    await clearMedReminders();
    final offMin = offset.inMinutes;
    for (final entry in timeToMeds.entries) {
      // Parse due time, back off by offset minutes modulo 24h
      final parts = entry.key.split(':');
      var h = int.tryParse(parts[0]) ?? 0;
      var m = int.tryParse(parts[1]) ?? 0;
      var total = (h * 60 + m - offMin) % (24 * 60);
      if (total < 0) total += 24 * 60;
      final preH = total ~/ 60;
      final preM = total % 60;
      final id = _idForTime('${preH.toString().padLeft(2, '0')}:${preM.toString().padLeft(2, '0')}');
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, preH, preM);
      if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
      final meds = entry.value.join(', ');
      try {
        await _plugin.zonedSchedule(
          id,
          'Pills due soon',
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
      } on Exception {
        await _plugin.zonedSchedule(
          id,
          'Pills due soon',
          meds.isEmpty ? 'Medication reminder' : meds,
          scheduled,
          const NotificationDetails(
            android: AndroidNotificationDetails('meds_channel', 'Medication Reminders', importance: Importance.max, priority: Priority.high),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  static Future<void> clearMoodReminders() async {
    await _plugin.cancel(21010);
    await _plugin.cancel(21018);
  }

  static Future<void> clearJournalReminders() async {
    await _plugin.cancel(22010);
    await _plugin.cancel(22018);
  }

  static Future<void> scheduleMoodJournalReminders({required bool moodEnabled, required bool journalEnabled}) async {
    await init();
    // Mood at 10:00 and 18:00
    if (!moodEnabled) {
      await clearMoodReminders();
    } else {
      await _scheduleDaily(id: 21010, hh: 10, mm: 0, title: 'Mood check-in', body: 'Log how you feel today.');
      await _scheduleDaily(id: 21018, hh: 18, mm: 0, title: 'Mood check-in', body: 'How are you feeling this evening?');
    }
    // Journal at 10:00 and 18:00
    if (!journalEnabled) {
      await clearJournalReminders();
    } else {
      await _scheduleDaily(id: 22010, hh: 10, mm: 0, title: 'Journal prompt', body: 'Capture a quick note.');
      await _scheduleDaily(id: 22018, hh: 18, mm: 0, title: 'Journal prompt', body: 'Reflect on your day.');
    }
  }

  static Future<void> _scheduleDaily({required int id, required int hh, required int mm, required String title, required String body}) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hh, mm);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails('reminders_channel', 'Daily Reminders', importance: Importance.max, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on Exception {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails('reminders_channel', 'Daily Reminders', importance: Importance.max, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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

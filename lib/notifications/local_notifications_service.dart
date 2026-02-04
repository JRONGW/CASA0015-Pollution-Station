import 'dart:io';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Base notification id for supplement reminders. Each reminder uses baseId + index.
const int supplementReminderBaseId = 100;

/// Maximum number of supplement reminders (ids 100..100+max-1).
const int supplementReminderMaxCount = 20;

/// Use a versioned channel ID so new installs get high-importance + sound (Android ignores channel updates).
const String androidSupplementChannelId = 'supplement_reminder_v2';
const String androidSupplementChannelName = 'Supplement reminder';

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

bool _initialized = false;

/// Initialize timezone database and set local location from device IANA timezone
/// so scheduled times match user's clock (including DST).
Future<void> _initTimezone() async {
  tz_data.initializeTimeZones();
  tz.Location location = tz.UTC;
  try {
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    location = tz.getLocation(tzInfo.identifier);
  } catch (_) {
    final offset = DateTime.now().timeZoneOffset;
    final offsetHours = offset.inHours + offset.inMinutes / 60.0;
    if (offsetHours != 0) {
      try {
        final sign = offsetHours > 0 ? '-' : '+';
        final hours = offsetHours.abs().toInt();
        location = tz.getLocation('Etc/GMT$sign$hours');
      } catch (_) {}
    }
  }
  tz.setLocalLocation(location);
}

/// Initialize the local notifications plugin. Call once from main().
Future<void> initLocalNotifications() async {
  if (_initialized) return;

  await _initTimezone();

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
  );
  const initSettings = InitializationSettings(
    android: android,
    iOS: ios,
  );

  await _plugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _onNotificationTapped,
  );

  if (Platform.isAndroid) {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            androidSupplementChannelId,
            androidSupplementChannelName,
            description: 'Daily reminder to take supplements',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
        );
  }

  _initialized = true;
}

void _onNotificationTapped(NotificationResponse response) {
  // Optional: navigate to supplements screen when notification is tapped
}

/// Request notification permission (Android 13+, iOS).
Future<bool> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final result = await android?.requestNotificationsPermission();
    return result == true;
  }
  if (Platform.isIOS) {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final result = await ios;
    return result == true;
  }
  return false;
}

/// Schedule one daily supplement reminder at [hour] and [minute], using [id].
Future<void> _scheduleOneReminder(int id, int hour, int minute) async {
  final now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }

  const androidDetails = AndroidNotificationDetails(
    androidSupplementChannelId,
    androidSupplementChannelName,
    channelDescription: 'Daily reminder to take supplements',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );
  const iosDetails = DarwinNotificationDetails();
  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await _plugin.zonedSchedule(
    id,
    'Supplement reminder',
    'Time to take your supplements.',
    scheduledDate,
    details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

/// Schedule daily supplement reminders for each (hour, minute) in [times].
/// Cancels all existing supplement reminders first. [times] length must be <= [supplementReminderMaxCount].
Future<void> scheduleSupplementReminders(
    List<({int hour, int minute})> times) async {
  await cancelAllSupplementReminders();
  if (times.length > supplementReminderMaxCount) return;

  for (var i = 0; i < times.length; i++) {
    final t = times[i];
    await _scheduleOneReminder(
        supplementReminderBaseId + i, t.hour, t.minute);
  }
}

/// Cancel a single supplement reminder by index [index] (0-based).
Future<void> cancelSupplementReminderAt(int index) async {
  await _plugin.cancel(supplementReminderBaseId + index);
}

/// Cancel all scheduled supplement reminders (ids 100..100+max-1).
Future<void> cancelAllSupplementReminders() async {
  for (var i = 0; i < supplementReminderMaxCount; i++) {
    await _plugin.cancel(supplementReminderBaseId + i);
  }
}

Future<bool> hasSupplementReminderScheduled() async {
  final pending = await _plugin
      .pendingNotificationRequests()
      .catchError((_) => <PendingNotificationRequest>[]);
  return pending.any((r) =>
      r.id >= supplementReminderBaseId &&
      r.id < supplementReminderBaseId + supplementReminderMaxCount);
}

/// Test id for one-off "test notification" (don't clash with supplement ids).
const int _testNotificationId = 99;

/// Schedule a one-off notification in [seconds] to verify sound and permissions.
/// Call after initLocalNotifications() and requestNotificationPermission().
Future<void> scheduleTestReminderInSeconds(int seconds) async {
  final now = tz.TZDateTime.now(tz.local);
  final scheduled = now.add(Duration(seconds: seconds));

  const androidDetails = AndroidNotificationDetails(
    androidSupplementChannelId,
    androidSupplementChannelName,
    channelDescription: 'Daily reminder to take supplements',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );
  const details = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  await _plugin.zonedSchedule(
    _testNotificationId,
    'Supplement reminder (test)',
    'If you see and hear this, reminders are working.',
    scheduled,
    details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}

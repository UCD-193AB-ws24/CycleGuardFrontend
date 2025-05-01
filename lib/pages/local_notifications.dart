import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import 'dart:developer' as developer;

class LocalNotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized; 

  Future<void> initNotification() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _notifications.initialize(settings);

    await _notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission(); 

    _isInitialized = true;
  }

  void requestExactAlarmPermission() async {
    const intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
    );
    await intent.launch();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id', 
        'Daily Notifications', 
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // Modified to add matchDateTimeComponents parameter
  Future<void> scheduleNotification({
    required int hour,
    required int minute,
    required int id, 
    String? title,
    String? body,
    DateTimeComponents? matchDateTimeComponents = DateTimeComponents.time,
  }) async {
    final permissionStatus = await Permission.notification.status;
    if (!permissionStatus.isGranted) {
      // Request permission if not granted
      requestExactAlarmPermission();
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
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

    await _notifications.cancel(id);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  // New method for weekly notifications
  Future<void> scheduleWeeklyNotification({
    required int hour,
    required int minute,
    required int dayOfWeek,
    required int id, 
    String? title,
    String? body,
  }) async {
    final permissionStatus = await Permission.notification.status;
    if (!permissionStatus.isGranted) {
      requestExactAlarmPermission();
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    
    // Calculate days until the next occurrence of the specified day of week
    int daysUntilTarget = dayOfWeek - now.weekday;
    if (daysUntilTarget < 0) {
      daysUntilTarget += 7;
    }
    
    // If it's the same day but the time has passed, add 7 days
    if (daysUntilTarget == 0 && 
        (now.hour > hour || (now.hour == hour && now.minute >= minute))) {
      daysUntilTarget = 7;
    }
    
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).add(Duration(days: daysUntilTarget));

    await _notifications.cancel(id);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // Enhanced method for one-time notifications with specific date
  Future<void> scheduleOneTimeNotification({
    required int hour,
    required int minute,
    required int id,
    required int year,
    required int month,
    required int day,
    String? title,
    String? body,
  }) async {
    final permissionStatus = await Permission.notification.status;
    if (!permissionStatus.isGranted) {
      requestExactAlarmPermission();
      return;
    }

    // Create a scheduled date with the specific date and time
    var scheduledDate = tz.TZDateTime(
      tz.local,
      year,
      month,
      day,
      hour,
      minute,
    );

    final now = tz.TZDateTime.now(tz.local);
    
    // If the specified date and time has already passed, don't schedule
    if (scheduledDate.isBefore(now)) {
      developer.log('Warning: Attempting to schedule notification in the past. Scheduling for now + 1 minute instead.',
        name: 'LocalNotificationService');
      // Schedule for 1 minute from now as fallback
      scheduledDate = now.add(const Duration(minutes: 1));
    }

    await _notifications.cancel(id);

    // For one-time notification, don't set matchDateTimeComponents
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
import 'package:cycle_guard_app/data/single_trip_history.dart';
import 'package:get_storage/get_storage.dart';
class NotificationsAccessor {
  NotificationsAccessor._();

  static Future<NotificationList> getNotifications() async {
    final response = await RequestsUtil.getWithToken("/notifications/getNotifications");

    if (response.statusCode == 200) {
      return NotificationList.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get notifications: error code ${response.statusCode}');
    }
  }

  static Future<NotificationList> addNotification(Notification notification) async {
    final body = notification.toJson();
    final response = await RequestsUtil.postWithToken("/notifications/addNotification", body);

    if (response.statusCode == 200) {
      return NotificationList.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to add notification: error message ${response.body}');
    }
  }

  static Future<NotificationList> deleteNotification(Notification notification) async {
    final body = notification.toJson();
    final response = await RequestsUtil.postWithToken("/notifications/deleteNotification", body);

    if (response.statusCode == 200) {
      return NotificationList.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to delete notification: error message ${response.body}');
    }
  }
}

class NotificationList {
  final String username;
  final List<Notification> notifications;

  const NotificationList({required this.username, required this.notifications});

  static List<Notification> _parseNotificationList(List<dynamic> list) {
    return List<Notification>.from(list.map((e) => Notification.fromJson(e)));
  }

  factory NotificationList.fromJson(Map<String, dynamic> jsonInit) {
    return switch (jsonInit) {
      {
      "username": String username,
      "notifications": List<dynamic> notifications,
      } => NotificationList(
        // username: username,
        username: username,
        notifications: _parseNotificationList(notifications)
      ),
      _ => throw const FormatException("failed to load NotificationList"),
    };
  }

  @override
  String toString() {
    return 'NotificationList{username: $username, notifications: $notifications}';
  }
}

class Notification {
  final String title, body;
  final int hour, minute, frequency, dayOfWeek;

  const Notification({
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    required this.frequency,
    required this.dayOfWeek,
  });

  factory Notification.fromJson(Map<String, dynamic> jsonInit) {
    return switch (jsonInit) {
      {
      "title": String title,
      "body": String body,
      "hour": int hour,
      "minute": int minute,
      "frequency": int frequency,
      "dayOfWeek": int dayOfWeek
      } => Notification(
        title: title,
        body: body,
        hour: hour,
        minute: minute,
        frequency: frequency,
        dayOfWeek: dayOfWeek
      ),
      _ => throw const FormatException("failed to load Notification"),
    };
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'hour': hour,
    'minute': minute,
    'frequency': frequency,
    'dayOfWeek': dayOfWeek
  };

  @override
  String toString() {
    return 'Notification{title: $title, body: $body, hour: $hour, minute: $minute, '
        'frequency: $frequency, dayOfWeek: $dayOfWeek}';
  }
}
import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
import 'package:get_storage/get_storage.dart';
class WeekHistoryAccessor {
  WeekHistoryAccessor._();

  static Future<WeekHistory> getWeekHistory() async {
    final response = await RequestsUtil.getWithToken("/history/getWeekHistory");

    if (response.statusCode == 200) {
      return WeekHistory.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get health info');
    }
  }
}

class DayHistory {
  final double distance, calories, time;

  const DayHistory({required this.distance, required this.calories, required this.time});

  factory DayHistory.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      "distance": String distance,
      "calories": String calories,
      "time": String time,
      } => DayHistory(
        distance: double.parse(distance),
        calories: double.parse(calories),
        time: double.parse(time),
      ),
      _ => throw const FormatException("failed to load DayHistory"),
    };
  }

  @override
  String toString() {
    return 'DayHistory{distance: $distance, calories: $calories, time: $time}';
  }
}

class WeekHistory {
  // final String username;
  final Map<int, DayHistory> dayHistoryMap;

  const WeekHistory({required this.dayHistoryMap});

  static Map<int, DayHistory> _parseDayHistoryMap(Map<String, dynamic> stringMap) {
    Map<int, DayHistory> intMap = {};

    for (var entry in stringMap.entries) {
      intMap[int.parse(entry.key)] = DayHistory.fromJson(entry.value);
    }

    return intMap;
  }

  factory WeekHistory.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      "dayHistoryMap": Map<String, dynamic> dayHistoryMap,
      } => WeekHistory(
        // username: username,
        dayHistoryMap: _parseDayHistoryMap(dayHistoryMap),
      ),
      _ => throw const FormatException("failed to load WeekHistory"),
    };
  }

  @override
  String toString() {
    return 'WeekHistory{dayHistoryMap: $dayHistoryMap}';
  }
}
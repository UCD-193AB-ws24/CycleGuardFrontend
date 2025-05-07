import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
import 'package:cycle_guard_app/data/single_trip_history.dart';

class WeekHistoryAccessor {
  WeekHistoryAccessor._();

  static Future<WeekHistory> getWeekHistory({String username=""}) async {
    var endpoint = "/history/getWeekHistory";
    if (username.isNotEmpty) endpoint += "/$username";
    final response = await RequestsUtil.getWithToken(endpoint);

    if (response.statusCode == 200) {
      return WeekHistory.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get health info');
    }
  }
}

class WeekHistory {
  // final String username;
  final Map<int, SingleTripInfo> dayHistoryMap;

  const WeekHistory({required this.dayHistoryMap});

  static Map<int, SingleTripInfo> _parseDayHistoryMap(Map<String, dynamic> stringMap) {
    Map<int, SingleTripInfo> intMap = {};

    for (var entry in stringMap.entries) {
      intMap[int.parse(entry.key)] = SingleTripInfo.fromJson(entry.value);
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
import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
import 'package:cycle_guard_app/data/single_trip_history.dart';
class TripHistoryAccessor {
  TripHistoryAccessor._();

  static Future<TripHistory> getTripHistory() async {
    final response = await RequestsUtil.getWithToken("/history/getTripHistory");

    if (response.statusCode == 200) {
      return TripHistory.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get trip history');
    }
  }
}

class TripHistory {
  // final String username;
  final Map<int, SingleTripInfo> timestampTripHistoryMap;

  const TripHistory({required this.timestampTripHistoryMap});

  static Map<int, SingleTripInfo> _parseDayHistoryMap(Map<String, dynamic> stringMap) {
    Map<int, SingleTripInfo> intMap = {};

    for (var entry in stringMap.entries) {
      intMap[int.parse(entry.key)] = SingleTripInfo.fromJson(entry.value);
    }

    return intMap;
  }

  factory TripHistory.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      "timestampTripHistoryMap": Map<String, dynamic> timestampTripHistoryMap,
      } => TripHistory(
        // username: username,
        timestampTripHistoryMap: _parseDayHistoryMap(timestampTripHistoryMap),
      ),
      _ => throw const FormatException("failed to load TripHistory"),
    };
  }

  @override
  String toString() {
    return 'TripHistory{timestampTripHistoryMap: $timestampTripHistoryMap}';
  }
}
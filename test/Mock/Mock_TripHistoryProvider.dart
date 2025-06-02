import 'dart:convert';

import 'package:cycle_guard_app/data/single_trip_history.dart';
import 'package:cycle_guard_app/data/trip_history_accessor.dart';
import 'package:flutter/cupertino.dart';
import 'package:mockito/mockito.dart';
import 'package:cycle_guard_app/data/trip_history_provider.dart';

// Mock class for TripHistoryProvider
class MockTripHistoryProvider extends ChangeNotifier implements TripHistoryProvider {
  // Example method to mock fetching trip history
  Future<void> fetchTripHistory() async {
    final tripHistoryData = TripHistory.fromJson(jsonDecode("{\"username\": \"dreamwarrior\", \"timestampTripHistoryMap\": {\"1748562424\": {\"distance\": \"0.6\", \"calories\": \"28.7\", \"time\": \"3.4\", \"averageAltitude\": \"0.0\", \"climb\": \"0.0\"}, \"1748568542\": {\"distance\": \"1.3\", \"calories\": \"63.2\", \"time\": \"6.6\", \"averageAltitude\": \"0.0\", \"climb\": \"0.0\"}}}") as Map<String, dynamic>);

    tripHistory = tripHistoryData.timestampTripHistoryMap;

    notifyListeners();
  }

  @override
  late Map<int, SingleTripInfo> tripHistory;

  @override
  SingleTripInfo? getTripByTimestamp(int timestamp) {
    return tripHistory[timestamp];
  }

}



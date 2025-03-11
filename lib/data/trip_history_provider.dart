import 'package:flutter/material.dart';
import 'package:cycle_guard_app/data/trip_history_accessor.dart';
import 'package:cycle_guard_app/data/single_trip_history.dart';

class TripHistoryProvider with ChangeNotifier {
  Map<int, SingleTripInfo> tripHistory = {};

  Future<void> fetchTripHistory() async {
    final tripHistoryData = await TripHistoryAccessor.getTripHistory();
    
    tripHistory = tripHistoryData.timestampTripHistoryMap;
    
    notifyListeners(); 
  }

  SingleTripInfo? getTripByTimestamp(int timestamp) {
    return tripHistory[timestamp];
  }
}
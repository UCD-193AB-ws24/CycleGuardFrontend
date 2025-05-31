import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:cycle_guard_app/data/single_trip_history.dart';
import 'package:cycle_guard_app/data/week_history_accessor.dart';
import 'package:cycle_guard_app/data/week_history_provider.dart';

class MockWeekHistoryProvider extends ChangeNotifier implements WeekHistoryProvider {
  @override
  Map<int, SingleTripInfo> dayHistoryMap = {};

  @override
  List<double> dayDistances = [];

  @override
  List<int> days = [];

  @override
  double averageDistance = 0.0;

  @override
  double averageCalories = 0.0;

  @override
  double averageTime = 0.0;

  @override
  Future<void> fetchWeekHistory() async {
    final jsonString = '''
      {
        "username": "dreamwarrior",
        "dayHistoryMap": {
          "1748476800": {
            "distance": "2.3",
            "calories": "112.6",
            "time": "12.7",
            "overFiveMiles": false,
            "distanceDouble": 2.3,
            "timeDouble": 12.7,
            "caloriesDouble": 112.6
          },
          "1748563200": {
            "distance": "0.3",
            "calories": "13.0",
            "time": "2.0",
            "overFiveMiles": false,
            "distanceDouble": 0.3,
            "timeDouble": 2.0,
            "caloriesDouble": 13.0
          }
        },
        "primaryKey": "dreamwarrior"
      }
    ''';

    final weekHistory = WeekHistory.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    dayHistoryMap = weekHistory.dayHistoryMap;

    double totalDistance = 0.0, totalCalories = 0.0, totalTime = 0.0;
    int numberOfDays = dayHistoryMap.length;

    if (numberOfDays > 0) {
      dayHistoryMap.forEach((day, history) {
        totalDistance += history.distance;
        totalCalories += history.calories;
        totalTime += history.time;
        dayDistances.add(history.distance);
        days.add(day);
      });

      averageDistance = totalDistance / numberOfDays;
      averageCalories = totalCalories / numberOfDays;
      averageTime = totalTime / numberOfDays;
    }

    notifyListeners();
  }

  @override
  late double userAverageCalories;

  @override
  late double userAverageDistance;

  @override
  late double userAverageTime;

  @override
  late List<double> userDayDistances;

  @override
  late Map<int, SingleTripInfo> userDayHistoryMap;

  @override
  late List<int> userDays;

  @override
  Future<void> fetchUserWeekHistory(String username) {
    // TODO: implement fetchUserWeekHistory
    throw UnimplementedError();
  }
}

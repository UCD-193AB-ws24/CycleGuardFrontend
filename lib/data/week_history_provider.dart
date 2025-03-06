import 'package:cycle_guard_app/data/single_trip_history.dart';
import 'package:flutter/material.dart';
import 'package:cycle_guard_app/data/week_history_accessor.dart';

class WeekHistoryProvider with ChangeNotifier {
  Map<int, SingleTripInfo> dayHistoryMap = {};
  double averageDistance = 0.0;
  double averageCalories = 0.0;
  double averageTime = 0.0;
  List<double> dayDistances = [];
  List<int> days = [];

  Future<void> fetchWeekHistory() async {
    final weekHistory = await WeekHistoryAccessor.getWeekHistory();
    
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
}
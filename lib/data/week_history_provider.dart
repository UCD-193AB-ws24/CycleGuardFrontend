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

  Map<int, SingleTripInfo> userDayHistoryMap = {};
  double userAverageDistance = 0.0;
  double userAverageCalories = 0.0;
  double userAverageTime = 0.0;
  List<double> userDayDistances = [];
  List<int> userDays = [];

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

  Future<void> fetchUserWeekHistory(String username) async {
    final weekHistory = await WeekHistoryAccessor.getWeekHistory(username: username);

    userDayHistoryMap = weekHistory.dayHistoryMap;

    double totalDistance = 0.0, totalCalories = 0.0, totalTime = 0.0;
    int numberOfDays = dayHistoryMap.length;

    if (numberOfDays > 0) {
      userDayHistoryMap.forEach((day, history) {
        totalDistance += history.distance;
        totalCalories += history.calories;
        totalTime += history.time;
        userDayDistances.add(history.distance);
        userDays.add(day);
      });

      userAverageDistance = totalDistance / numberOfDays;
      userAverageCalories = totalCalories / numberOfDays;
      userAverageTime = totalTime / numberOfDays;
    }

    notifyListeners();
  }
}
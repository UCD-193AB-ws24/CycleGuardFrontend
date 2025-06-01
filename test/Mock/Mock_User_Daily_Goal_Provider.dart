import 'package:cycle_guard_app/data/user_daily_goal_provider.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';

class MockUserDailyGoalProvider extends ChangeNotifier implements UserDailyGoalProvider {
  Future<void> fetchDailyGoals() async {
    dailyDistanceGoal = 10;
    dailyTimeGoal = 10;
    dailyCaloriesGoal = 10;
    notifyListeners();
  }

  Future<void> updateUserGoals(double distance, double time, double calories) async {
      // Update the local provider values
      dailyDistanceGoal = 10;
      dailyTimeGoal = 10;
      dailyCaloriesGoal = 10;
      // Notify listeners that the data has changed
      notifyListeners();
  }

  @override
  late double dailyCaloriesGoal;

  @override
  late double dailyDistanceGoal;

  @override
  late double dailyTimeGoal;
}
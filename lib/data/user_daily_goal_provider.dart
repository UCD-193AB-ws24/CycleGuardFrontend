import 'package:flutter/material.dart';
import 'package:cycle_guard_app/data/user_daily_goal_accessor.dart';

class UserDailyGoalProvider with ChangeNotifier {
  double dailyDistanceGoal = 0;
  double dailyTimeGoal = 0;
  double dailyCaloriesGoal = 0;

  Future<void> fetchDailyGoals() async {
    final dailyGoal = await UserDailyGoalAccessor.getUserDailyGoal();

    dailyDistanceGoal = dailyGoal.distance;
    dailyTimeGoal = dailyGoal.time;
    dailyCaloriesGoal = dailyGoal.calories;

    notifyListeners();
  }

  Future<void> updateUserGoals(double distance, double time, double calories) async {
    try {
      // Create a new goal object
      final newGoal = UserDailyGoal(
        distance: distance,
        time: time,
        calories: calories,
      );

      // Update the goal via accessor
      await UserDailyGoalAccessor.updateUserDailyGoal(newGoal);

      // Update the local provider values
      dailyDistanceGoal = distance;
      dailyTimeGoal = time;
      dailyCaloriesGoal = calories;

      // Notify listeners that the data has changed
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update goals: $e');
    }
  }
}
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:mockito/mockito.dart';

class MockUserStatsProvider extends ChangeNotifier implements UserStatsProvider {
  // Method to fetch user stats and update the state
  Future<void> fetchUserStats() async {

    accountCreationTime  = 10;
    totalDistance        = 10;
    totalTime            = 10;
    rideStreak           = 10;
    bestStreak           = 10;
    lastRideDay          = 10;
    username             = "test";
    bestPackGoalProgress = 20;
    notifyListeners(); // Notify listeners that stats are updated
  }

  @override
  late int accountCreationTime;

  @override
  late int bestPackGoalProgress;

  @override
  late int bestStreak;

  @override
  late int lastRideDay;

  @override
  late int rideStreak;

  @override
  late double totalDistance;

  @override
  late double totalTime;

  @override
  late String username;
}
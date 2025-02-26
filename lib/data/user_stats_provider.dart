// user_stats_provider.dart
import 'package:flutter/material.dart';
import 'package:cycle_guard_app/data/user_stats_accessor.dart'; // Assuming the accessor is here

class UserStatsProvider with ChangeNotifier {
  String username = ""; 
  double totalDistance = 0;
  double totalTime = 0;
  int rideStreak = 0;
  int bestStreak = 0;
  int accountCreationTime = 0;
  int lastRideDay = 0;

  // Method to fetch user stats and update the state
  Future<void> fetchUserStats() async {
    final userStats = await UserStatsAccessor.getUserStats();
    
    accountCreationTime = userStats.accountCreationTime;
    totalDistance = userStats.totalDistance;
    totalTime = userStats.totalTime;
    rideStreak = userStats.rideStreak;
    bestStreak = userStats.bestStreak;
    lastRideDay = userStats.lastRideDay;
    username = userStats.username;
    notifyListeners(); // Notify listeners that stats are updated
  }
}
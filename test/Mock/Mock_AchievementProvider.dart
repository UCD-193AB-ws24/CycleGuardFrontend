import 'dart:convert';

import 'package:cycle_guard_app/data/achievements_accessor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:cycle_guard_app/data/achievements_progress_provider.dart';

// Mock class for AchievementsProgressProvider
class MockAchievementsProgressProvider extends ChangeNotifier implements AchievementsProgressProvider {
  // Method to fetch user stats and update the state
  Future<void> fetchAchievementProgress() async {

    achievementsCompleted = AchievementInfo.fromJson(jsonDecode("{\"username\":\"javagod123\",\"achievementProgressMap\":{\"11\":{\"currentProgress\":8,\"complete\":false},\"12\":{\"currentProgress\":50,\"complete\":false},\"13\":{\"currentProgress\":50,\"complete\":false},\"14\":{\"currentProgress\":50,\"complete\":false},\"15\":{\"currentProgress\":50,\"complete\":false},\"0\":{\"currentProgress\":1,\"complete\":false},\"1\":{\"currentProgress\":1,\"complete\":false},\"2\":{\"currentProgress\":8,\"complete\":false},\"3\":{\"currentProgress\":100,\"complete\":false},\"4\":{\"currentProgress\":1000,\"complete\":false},\"5\":{\"currentProgress\":10000,\"complete\":false},\"6\":{\"currentProgress\":600,\"complete\":false},\"7\":{\"currentProgress\":1663,\"complete\":false},\"8\":{\"currentProgress\":1663,\"complete\":false},\"9\":{\"currentProgress\":7,\"complete\":false},\"10\":{\"currentProgress\":8,\"complete\":false}},\"primaryKey\":\"javagod123\"}") as Map<String, dynamic>).getCompletedAchievements();

    notifyListeners();
  }


  late final List<Map<String, dynamic>> uniqueAchievements = [
    {'title': 'First Ride', 'description': 'Complete your first ride', 'icon': Icons.directions_bike, 'goalValue': 1},
    {'title': 'Rocket Boost', 'description': 'Unlock the rocket boost', 'icon': Icons.rocket, 'goalValue': 1},
    {'title': 'Achievement Hunter', 'description': 'Complete all achievements', 'icon': Icons.emoji_events, 'goalValue': 15},
  ];

  @override
  late final List<Map<String, dynamic>> distanceAchievements = [
    {'title': 'Challenger', 'description': 'Bike 100 miles', 'icon': Icons.flag, 'goalValue': 100},
    {'title': 'Champion', 'description': 'Bike 1000 miles', 'icon': Icons.flag, 'goalValue': 1000},
    {'title': 'Conqueror', 'description': 'Bike 10000 miles', 'icon': Icons.flag, 'goalValue': 10000},
  ];

  @override
  final List<Map<String, dynamic>> timeAchievements = [
    {'title': 'Pedal Pusher', 'description': 'Ride for 10 hours', 'icon': Icons.timer, 'goalValue': 10},
    {'title': 'Endurance Rider', 'description': 'Ride for 100 hours', 'icon': Icons.timer, 'goalValue': 100},
    {'title': 'Iron Cyclist', 'description': 'Ride for 1000 hours', 'icon': Icons.timer, 'goalValue': 1000},
  ];

  @override
  final List<Map<String, dynamic>> consistencyAchievements = [
    {'title': 'Daily Rider', 'description': 'Ride every day for a week', 'icon': Icons.calendar_today, 'goalValue': 7},
    {'title': 'Month of Miles', 'description': 'Ride every day for a month', 'icon': Icons.calendar_today, 'goalValue': 30},
    {'title': 'Year-Round Rider', 'description': 'Ride every day for a year', 'icon': Icons.calendar_today, 'goalValue': 365},
  ];

  @override
  final List<Map<String, dynamic>> packsAchievements = [
    {'title': 'New Joinee', 'description': 'Finish a pack goal of 50 miles', 'icon': Icons.bike_scooter_rounded, 'goalValue': 1},
    {'title': 'Helpful Rival', 'description': 'Finish a pack goal of 100 miles', 'icon': Icons.bike_scooter_rounded, 'goalValue': 1},
    {'title': 'Valuable Teammate', 'description': 'Finish a pack goal of 250 miles', 'icon': Icons.bike_scooter_rounded, 'goalValue': 1},
    {'title': 'Packmaster', 'description': 'Finish a pack goal of 500 miles', 'icon': Icons.bike_scooter_rounded, 'goalValue': 1},
  ];

  @override
  List<bool> achievementsCompleted = List.filled(AchievementInfoAccessor.NUM_ACHIEVEMENTS, false);

}
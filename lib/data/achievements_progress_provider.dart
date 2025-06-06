import 'package:flutter/material.dart';
import 'package:cycle_guard_app/data/achievements_accessor.dart';

class AchievementsProgressProvider with ChangeNotifier {
  List<bool> achievementsCompleted = List.filled(AchievementInfoAccessor.NUM_ACHIEVEMENTS, false);

  // Method to fetch user stats and update the state
  Future<void> fetchAchievementProgress() async {
    final achievementInfo = await AchievementInfoAccessor.getAchievementInfo();

    achievementsCompleted = achievementInfo.getCompletedAchievements();

    notifyListeners();
  }

  final List<Map<String, dynamic>> uniqueAchievements = [
    {'title': 'First Ride', 'description': 'Complete your first ride', 'icon': Icons.directions_bike, 'goalValue': 1},
    {'title': 'Rocket Boost', 'description': 'Unlock the rocket boost', 'icon': Icons.rocket, 'goalValue': 1},
    {'title': 'Achievement Hunter', 'description': 'Complete all achievements', 'icon': Icons.emoji_events, 'goalValue': 15},
  ];

  final List<Map<String, dynamic>> distanceAchievements = [
    {'title': 'Challenger', 'description': 'Bike 100 miles', 'icon': Icons.flag, 'goalValue': 100},
    {'title': 'Champion', 'description': 'Bike 1000 miles', 'icon': Icons.flag, 'goalValue': 1000},
    {'title': 'Conqueror', 'description': 'Bike 10000 miles', 'icon': Icons.flag, 'goalValue': 10000},
  ];

  final List<Map<String, dynamic>> timeAchievements = [
    {'title': 'Pedal Pusher', 'description': 'Ride for 10 hours', 'icon': Icons.timer, 'goalValue': 10},
    {'title': 'Endurance Rider', 'description': 'Ride for 100 hours', 'icon': Icons.timer, 'goalValue': 100},
    {'title': 'Iron Cyclist', 'description': 'Ride for 1000 hours', 'icon': Icons.timer, 'goalValue': 1000},
  ];

  final List<Map<String, dynamic>> consistencyAchievements = [
    {'title': 'Daily Rider', 'description': 'Ride every day for a week', 'icon': Icons.calendar_today, 'goalValue': 7},
    {'title': 'Month of Miles', 'description': 'Ride every day for a month', 'icon': Icons.calendar_today, 'goalValue': 30},
    {'title': 'Year-Round Rider', 'description': 'Ride every day for a year', 'icon': Icons.calendar_today, 'goalValue': 365},
  ];

  final List<Map<String, dynamic>> packsAchievements = [
    {'title': 'New Joinee', 'description': 'Finish a pack goal of 50 miles', 'icon': Icons.bike_scooter_rounded, 'goalValue': 1},
    {'title': 'Helpful Rival', 'description': 'Finish a pack goal of 100 miles', 'icon': Icons.bike_scooter_rounded, 'goalValue': 1},
    {'title': 'Valuable Teammate', 'description': 'Finish a pack goal of 250 miles', 'icon': Icons.bike_scooter_rounded, 'goalValue': 1},
    {'title': 'Packmaster', 'description': 'Finish a pack goal of 500 miles', 'icon': Icons.bike_scooter_rounded, 'goalValue': 1},
  ];
}
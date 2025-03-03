import 'package:flutter/material.dart';
import 'package:cycle_guard_app/data/achievements_accessor.dart';


class AchievementsProgressProvider with ChangeNotifier {
  List<bool> achievementsCompleted = [false, false, false, false, false, false, false, false, false, false, false];

  // Method to fetch user stats and update the state
  Future<void> fetchAchievementProgress() async {
    final achievementInfo = await AchievementInfoAccessor.getAchievementInfo();
    
    achievementsCompleted = achievementInfo.getCompletedAchievements();

    notifyListeners();
  }
}
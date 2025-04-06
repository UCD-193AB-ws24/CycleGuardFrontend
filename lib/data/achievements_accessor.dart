import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
import 'package:flutter/semantics.dart';
class AchievementInfoAccessor {
  AchievementInfoAccessor._();

  static Future<AchievementInfo> getAchievementInfo() async {
    final response = await RequestsUtil.getWithToken("/achievements/getAchievements");

    if (response.statusCode == 200) {
      print(response.body);
      return AchievementInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get achievement info');
    }
  }
}

class AchievementProgress {
  final int currentProgress;
  final bool complete;

  const AchievementProgress({required this.currentProgress, required this.complete});

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      "currentProgress": int currentProgress,
      "complete": bool complete,
      } => AchievementProgress(
          currentProgress: currentProgress,
          complete: complete,
      ),
      _ => throw const FormatException("failed to load AchievementProgress"),
    };
  }

  @override
  String toString() {
    return 'AchievementProgress{currentProgress: $currentProgress, complete: $complete}';
  }
}

class AchievementInfo {
  // final String username;
  final Map<int, AchievementProgress> achievementProgressMap;

  const AchievementInfo({required this.achievementProgressMap});

  static Map<int, AchievementProgress> _parseAchievementProgressMap(Map<String, dynamic> stringMap) {
    Map<int, AchievementProgress> intMap = {};

    for (var entry in stringMap.entries) {
      intMap[int.parse(entry.key)] = AchievementProgress.fromJson(entry.value);
    }

    return intMap;
  }

  factory AchievementInfo.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        // "username": String username,
        "achievementProgressMap": Map<String, dynamic> achievementProgressMap,
      } => AchievementInfo(
          // username: username,
          achievementProgressMap: _parseAchievementProgressMap(achievementProgressMap),
      ),
      _ => throw const FormatException("failed to load AchievementInfo"),
    };
  }

  @override
  String toString() {
    return 'AchievementInfo{achievementProgressMap: $achievementProgressMap}';
  }

  List<bool> getCompletedAchievements() {
    List<bool> res = List<bool>.filled(achievementProgressMap.length, false, growable: false);

    for (var entry in achievementProgressMap.entries) {
      int idx = entry.key;
      bool complete = entry.value.complete;

      res[idx] = complete;
    }
    return res;
  }
}
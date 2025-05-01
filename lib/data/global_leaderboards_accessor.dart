import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
class GlobalLeaderboardsAccessor {
  GlobalLeaderboardsAccessor._();

  static Future<Leaderboards> getDistanceLeaderboards() async {
    final response = await RequestsUtil.getWithToken("/leaderboards/getDistanceLeaderboards");

    if (response.statusCode == 200) {
      return Leaderboards.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get leaderboard');
    }
  }

  static Future<Leaderboards> getTimeLeaderboards() async {
    final response = await RequestsUtil.getWithToken("/leaderboards/getTimeLeaderboards");

    if (response.statusCode == 200) {
      return Leaderboards.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get leaderboard');
    }
  }
}

class LeaderboardEntry {
  final String username;
  final double value;

  const LeaderboardEntry({required this.username, required this.value});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      "username": String username,
      "value": String value,
      } => LeaderboardEntry(
        username: username,
        value: double.parse(value),
      ),
      _ => throw const FormatException("failed to load LeaderboardEntry"),
    };
  }

  @override
  String toString() {
    return 'LeaderboardEntry{username: $username, value: $value}';
  }
}

class Leaderboards {
  final String leaderboardName;
  final List<LeaderboardEntry> entries;

  const Leaderboards({required this.leaderboardName, required this.entries});

  static List<LeaderboardEntry> _parseEntryList(List<dynamic> stringMap) {
    return List<LeaderboardEntry>.from(stringMap.map((e) => LeaderboardEntry.fromJson(e)));
  }

  factory Leaderboards.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      "leaderboardName": String leaderboardName,
      "entries": List<dynamic> entries,
      } => Leaderboards(
        leaderboardName: leaderboardName,
        entries: _parseEntryList(entries),
      ),
      _ => throw const FormatException("failed to load AchievementInfo"),
    };
  }

  @override
  String toString() {
    return 'Leaderboards{leaderboardName: $leaderboardName, entries: $entries}';
  }
}
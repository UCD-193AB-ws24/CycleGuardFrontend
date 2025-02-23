import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
class UserStatsAccessor {
  UserStatsAccessor._();

  static Future<UserStats> getUserStats() async {
    final response = await RequestsUtil.getWithToken("/user/getStats");

    if (response.statusCode == 200) {
      return UserStats.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get user stats');
    }
  }
}

class UserStats {
  final String username;
  final int accountCreationTime;
  final double totalDistance, totalTime;
  final int lastRideDay;
  final int rideStreak, bestStreak;

  const UserStats({
    required this.username,
    required this.accountCreationTime,
    required this.totalDistance,
    required this.totalTime,
    required this.lastRideDay,
    required this.rideStreak,
    required this.bestStreak
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "username": String username,
        "accountCreationTime": int accountCreationTime,
        "totalDistance": String totalDistance,
        "totalTime": String totalTime,
        "lastRideDay": int lastRideDay,
        "rideStreak": int rideStreak,
        "bestStreak": int bestStreak
      } => UserStats(
        username: username,
        accountCreationTime: accountCreationTime,
        totalDistance: double.parse(totalDistance),
        totalTime: double.parse(totalTime),
        lastRideDay: lastRideDay,
        rideStreak: rideStreak,
        bestStreak: bestStreak
      ),
      _ => throw const FormatException("failed to load UserStats"),
    };
  }

  @override
  String toString() {
    return 'UserStats{username: $username, accountCreationTime: $accountCreationTime, totalDistance: $totalDistance, totalTime: $totalTime, lastRideDay: $lastRideDay, rideStreak: $rideStreak, bestStreak: $bestStreak}';
  }
}
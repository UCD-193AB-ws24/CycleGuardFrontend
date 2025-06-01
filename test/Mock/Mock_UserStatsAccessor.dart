// Mock implementation for UserStatsAccessor
import 'package:cycle_guard_app/data/user_stats_accessor.dart';

class MockUserStatsAccessor implements UserStatsAccessor{
  static Future<UserStats> getUserStats() async {
    return const UserStats(
      username: 'mockUser',
      accountCreationTime: 1234567890,
      totalDistance: 100.0,
      totalTime: 50.0,
      bestPackGoalProgress: 80,
      lastRideDay: 5,
      rideStreak: 10,
      bestStreak: 15,
    );
  }
}
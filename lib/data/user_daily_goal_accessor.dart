import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';

class UserDailyGoalAccessor {
  UserDailyGoalAccessor._();

  static Future<UserDailyGoal> getUserDailyGoal() async {
    final response = await RequestsUtil.getWithToken("/daily/getDailyGoal");

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return new UserDailyGoal(distance: 0, time: 0, calories: 0);
      return UserDailyGoal.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get user daily goal');
    }
  }

  static Future<void> updateUserDailyGoal(UserDailyGoal goal) async {
    final body = goal.toJson();
    final response = await RequestsUtil.postWithToken("/daily/setDailyGoal", body);

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to update goal');
    }
  }

  static Future<void> deleteUserDailyGoal() async {
    final body = <String, dynamic>{};
    final response = await RequestsUtil.postWithToken("/daily/setDailyGoal", body);

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to delete goal');
    }
  }
}

class UserDailyGoal {
  final double distance, time, calories;

  const UserDailyGoal({
    required this.distance,
    required this.time,
    required this.calories,
  });

  factory UserDailyGoal.fromJson(Map<String, dynamic> json) {
    return switch (json) {
    {
      "distance": String distance,
      "calories": String calories,
      "time": String time,
    } => UserDailyGoal(
      distance: double.parse(distance),
      calories: double.parse(calories),
      time: double.parse(time),
    ),
    _ => throw const FormatException("failed to load UserDailyGoal"),
    };
  }

  Map<String, dynamic> toJson() => {
    "distance": distance,
    "calories": calories,
    "time": time,
  };

  @override
  String toString() {
    return 'UserDailyGoal{distance: $distance, time: $time, calories: $calories}';
  }
}
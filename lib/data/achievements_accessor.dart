import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
class AchievementInfoAccessor {
  AchievementInfoAccessor._();

  static Future<AchievementInfo> getAchievementInfo() async {
    final response = await RequestsUtil.getWithToken("/achievements/getAchievements");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      throw Exception("TODO: implement JSON parsing. Look at health_info_accessor for an example");
      return AchievementInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get achievement info');
    }
  }
}

// TODO: change to Achievement Info variables. May need a separate "AchievementProgress" class, per achievement ID
class AchievementInfo {
  final int heightInches;
  final int weightPounds;
  final int ageYears;

  const AchievementInfo({required this.heightInches, required this.weightPounds, required this.ageYears});

  factory AchievementInfo.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "heightInches": int heightInches,
        "weightPounds": int weightPounds,
        "ageYears": int ageYears
      } => AchievementInfo(
        heightInches: heightInches,
        weightPounds: weightPounds,
        ageYears: ageYears
      ),
      _ => throw const FormatException("failed to load HealthInfo"),
    };
  }
}
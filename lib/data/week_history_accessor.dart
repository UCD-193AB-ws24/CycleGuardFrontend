import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
class WeekHistoryAccessor {
  WeekHistoryAccessor._();

  static Future<WeekHistory> getWeekHistory() async {
    final response = await RequestsUtil.getWithToken("/history/getWeekHistory");

    if (response.statusCode == 200) {
      throw Exception("TODO: implement JSON parsing. Look at health_info_accessor for an example");
      // return WeekHistory.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get health info');
    }
  }
}

// TODO: change to Week History variables. May need to create a separate "DayHistory" class.
class WeekHistory {
  final int heightInches;
  final int weightPounds;
  final int ageYears;

  const WeekHistory({required this.heightInches, required this.weightPounds, required this.ageYears});

  factory WeekHistory.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "heightInches": int heightInches,
        "weightPounds": int weightPounds,
        "ageYears": int ageYears
      } => WeekHistory(
        heightInches: heightInches,
        weightPounds: weightPounds,
        ageYears: ageYears
      ),
      _ => throw const FormatException("failed to load HealthInfo"),
    };
  }
}
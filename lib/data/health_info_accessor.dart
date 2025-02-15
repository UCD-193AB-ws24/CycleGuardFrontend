import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
class HealthInfoAccessor {
  HealthInfoAccessor._();

  static Future<HealthInfo> getHealthInfo() async {
    final response = await RequestsUtil.getWithToken("/health/get");

    if (response.statusCode == 200) {
      return HealthInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get CycleCoins');
    }
  }

  /// Sets health info, given height (inches), weight (pounds), age (years).
  static Future<int> setHealthInfo(int height, int weight, int age) async {
    final body = {
      "heightInches": "$height",
      "weightPounds": "$weight",
      "ageYears": "$age"
    };
    final response = await RequestsUtil.postWithToken("/health/set", body);

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('Failed to update CycleCoins');
    }
  }
}

class HealthInfo {
  final int heightInches;
  final int weightPounds;
  final int ageYears;

  const HealthInfo({required this.heightInches, required this.weightPounds, required this.ageYears});

  factory HealthInfo.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "heightInches": int heightInches,
        "weightPounds": int weightPounds,
        "ageYears": int ageYears
      } => HealthInfo(
        heightInches: heightInches,
        weightPounds: weightPounds,
        ageYears: ageYears
      ),
      _ => throw const FormatException("failed to load HealthInfo"),
    };
  }
}
import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
class HealthInfoAccessor {
  HealthInfoAccessor._();

  static Future<HealthInfo> getHealthInfo() async {
    final response = await RequestsUtil.getWithToken("/health/get");

    if (response.statusCode == 200) {
      return HealthInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get health info');
    }
  }

  static Future<void> setHealthInfo(String height, String weight, String age) async {
    final body = {
      "heightInches": height,
      "weightPounds": weight,
      "ageYears": age
    };
    final response = await RequestsUtil.postWithToken("/health/set", body);

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to update CycleCoins');
    }
  }

  /// Sets health info, given height (inches), weight (pounds), age (years).
  static Future<void> setHealthInfoInts(int height, int weight, int age) async {
    await setHealthInfo("$height", "$weight", "$age");
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
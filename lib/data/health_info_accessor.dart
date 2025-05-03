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

  static double _computeMET(double mph) {
    if (mph < 10) {
      // mph 0-10
      // Range 4-6
      return mph/10 * 2 + 4;
    } else if (mph < 19) {
      // mph 10-19
      // Range 6-16
      return (mph-10)/9 * 10 + 6;
    } else {
      return 16;
    }
  }

  double getCaloriesBurned(double miles, double minutes) {
    if (weightPounds==0 || ageYears==0 || heightInches==0) return 0;

    double kg = weightPounds * 0.453592;
    double mph = (miles/minutes) * 60;

    // Calories Burned per minute = MET value × body weight in Kg × 3.5/200
    double met = _computeMET(mph);

    return minutes * met * kg * 7/400;
  }
}
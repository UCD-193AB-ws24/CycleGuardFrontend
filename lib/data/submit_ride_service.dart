import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
class SubmitRideService {
  SubmitRideService._();

  static Future<void> addRide(RideInfo rideInfo) async {
    final body = rideInfo.toJson();
    final response = await RequestsUtil.postWithToken("/rides/addRide", body);

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to update CycleCoins');
    }
  }

  static Future<void> addRideRaw(double distance, double calories, double time) async {
    await addRide(new RideInfo(distance, calories, time));
  }
}

class RideInfo {
  double distance;
  double calories;
  double time;



  RideInfo(this.distance, this.calories, this.time);
  Map<String, String> toJson() => {'distance': "$distance", 'calories': "$calories", 'time': "$time"};
}
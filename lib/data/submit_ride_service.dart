import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
class SubmitRideService {
  SubmitRideService._();

  static Future<int> addRide(RideInfo rideInfo) async {
    final body = rideInfo.toJson();
    print(body);
    final response = await RequestsUtil.postWithToken("/rides/addRide", body);

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('Failed to add ride');
    }
  }

  static Future<int> addRideRaw(double distance, double calories, double time, List<double> latitudes, List<double> longitudes) async {
    return await addRide(new RideInfo(distance, calories, time, latitudes, longitudes));
  }
}

class RideInfo {
  double distance;
  double calories;
  double time;

  List<double> latitudes, longitudes;

  RideInfo(this.distance, this.calories, this.time, this.latitudes, this.longitudes);
  Map<String, dynamic> toJson() => {
    'distance': "$distance",
    'calories': "$calories",
    'time': "$time",
    'longitudes': longitudes,
    'latitudes': latitudes
  };
}
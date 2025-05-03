import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
import 'package:hive/hive.dart';
class SubmitRideService {
  SubmitRideService._();

  static final _localRideDataBox = Hive.box("localRideData");

  static Future<void> _addRideToDatabase(int timestamp, RideInfo rideInfo) async {
    print("Adding ride at timestamp $timestamp");
    print(rideInfo);

    await _localRideDataBox.put("$timestamp", rideInfo.toJson());

    print("Reading from database: ${RideInfo.fromJson(await _localRideDataBox.get('$timestamp'))}");
  }

  static void _removeFromDatabase(int timestamp) {

  }

  static List<int> getDatabaseKeys() {
    return _localRideDataBox.keys.map((e) => int.parse(e)).toList(growable: false);
  }

  static Future<int> addRide(RideInfo rideInfo) async {
    final body = rideInfo.toJson();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    _addRideToDatabase(timestamp, rideInfo);

    // final response = await RequestsUtil.postWithToken("/rides/addRide", body);
    final response = await RequestsUtil.getWithToken("/rides/getProfile");

    if (response.statusCode == 200) {
      _removeFromDatabase(timestamp);
      return int.parse(response.body);
    } else {
      throw Exception('Failed to add ride');
    }
  }

  static Future<int> addRideRaw(double distance, double calories, double time, List<double> latitudes, List<double> longitudes) async {
    return await addRide(RideInfo(distance, calories, time, latitudes, longitudes));
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

  factory RideInfo.fromJson(Map<String, dynamic> json) {

    return switch (json) {
      {
      "distance": String distance,
      "calories": String calories,
      "time": String time,
      "longitudes": List<double> longitudes,
      "latitudes": List<double> latitudes,
      } =>
          RideInfo(
            double.parse(distance),
            double.parse(calories),
            double.parse(time),
            longitudes,
            latitudes,
          ),
      _ => throw const FormatException("failed to load RideInfo from database"),
    };
  }

  @override
  String toString() {
    return 'RideInfo{distance: $distance, calories: $calories, time: $time, latitudes: $latitudes, longitudes: $longitudes}';
  }
}
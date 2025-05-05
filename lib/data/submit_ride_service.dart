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
  }

  static Future<void> _removeFromDatabase(int timestamp) async {
    await _localRideDataBox.delete("$timestamp");
  }

  static List<int> _getDatabaseKeys() {
    return _localRideDataBox.keys.map((e) => int.parse(e)).toList(growable: false);
  }

  static Future<bool> tryAddAllRides() async {
    final timestamps = _getDatabaseKeys();

    bool success = true;
    for (int timestamp in timestamps) {
      RideInfo rideInfo = await _getRideInfo(timestamp);
      if (await _tryAddRide(rideInfo)) {
        _removeFromDatabase(timestamp);
      } else {
        success = false;
        break;
      }
    }
    return success;
  }

  static Future<bool> _tryAddRide(RideInfo rideInfo) async {
    try {
      print("Trying to add ride $rideInfo");
      await RequestsUtil.postWithToken("/rides/addRide", rideInfo.toJson());
      print("Success!");
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<RideInfo> _getRideInfo(int timestamp) async {
    return RideInfo.fromJson(await _localRideDataBox.get("$timestamp"));
  }

  static Future<int> addRide(RideInfo rideInfo) async {
    final body = rideInfo.toJson();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    print(rideInfo);

    await _addRideToDatabase(timestamp, rideInfo);

    final response = await RequestsUtil.postWithToken("/rides/addRide", body);
    // final response = await RequestsUtil.getWithToken("/rides/getProfile");

    if (response.statusCode == 200) {
      _removeFromDatabase(timestamp);
      return int.parse(response.body);
    } else {
      throw Exception('Failed to add ride');
    }
  }

  static Future<int> addRideRaw(double distance, double calories, double time, List<double> latitudes, List<double> longitudes,
      double climb, double averageAltitude) async {
    return await addRide(RideInfo(distance, calories, time, latitudes, longitudes, climb, averageAltitude));
  }
}

class RideInfo {
  double distance, calories, time, climb, averageAltitude;

  List<double> latitudes, longitudes;

  RideInfo(this.distance, this.calories, this.time, this.latitudes, this.longitudes, this.climb, this.averageAltitude);
  Map<String, dynamic> toJson() => {
    'distance': "$distance",
    'calories': "$calories",
    'time': "$time",
    'latitudes': latitudes,
    'longitudes': longitudes,
    'climb': "$climb",
    'averageAltitude': "$averageAltitude"
  };

  factory RideInfo.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      "distance": String distance,
      "calories": String calories,
      "time": String time,
      "latitudes": List<double> latitudes,
      "longitudes": List<double> longitudes,
      "climb": String climb,
      "averageAltitude": String averageAltitude,
      } =>
          RideInfo(
            double.parse(distance),
            double.parse(calories),
            double.parse(time),
            latitudes,
            longitudes,
            double.parse(climb),
            double.parse(averageAltitude),
          ),
      _ => throw const FormatException("failed to load RideInfo from database"),
    };
  }

  @override
  String toString() {
    return 'RideInfo{distance: $distance, calories: $calories, time: $time, climb: $climb, '
        'averageAltitude: $averageAltitude, latitudes: $latitudes, longitudes: $longitudes}';
  }
}
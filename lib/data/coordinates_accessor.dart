import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
import 'package:cycle_guard_app/data/single_trip_history.dart';
import 'package:get_storage/get_storage.dart';
class CoordinatesAccessor {
  CoordinatesAccessor._();

  static Future<CoordinatesInfo> getCoordinates(int timestamp) async {
    final response = await RequestsUtil.getWithToken("/history/getCoordinates/$timestamp");
    print(response.body);

    if (response.statusCode == 200) {
      return CoordinatesInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get trip history');
    }
  }
}

class CoordinatesInfo {
  final List<double> latitudes, longitudes;

  const CoordinatesInfo({required this.latitudes, required this.longitudes});

  static List<double> _parseDoubleList(List<dynamic> list) {
    return List<double>.from(List<String>.from(list).map((e) => double.parse(e)));
  }

  factory CoordinatesInfo.fromJson(Map<String, dynamic> jsonInit) {
    return switch (jsonInit) {
      {
      "latitudes": List<dynamic> latitudes,
      "longitudes": List<dynamic> longitudes,
      } => CoordinatesInfo(
        // username: username,
        latitudes: _parseDoubleList(latitudes),
        longitudes: _parseDoubleList(longitudes),
      ),
      _ => throw const FormatException("failed to load Coordinates"),
    };
  }

  @override
  String toString() {
    return 'CoordinatesInfo{latitudes: $latitudes, longitudes: $longitudes}';
  }
}
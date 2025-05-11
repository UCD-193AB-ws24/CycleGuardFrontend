import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../auth/requests_util.dart';

class NavigationAccessor {
  NavigationAccessor._();

  static Future<BikeRoute> getRoute(LatLng origin, String destination) async {
    final body = {
      "startLat": origin.latitude,
      "startLng": origin.longitude,
      "destination": destination
    };

    final response = await RequestsUtil.postWithToken("/navigation/getRoute", body);
    print(response.body);

    if (response.statusCode == 200) {
      return BikeRoute.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get friends list');
    }
  }

  static Future<AutofillResult> getAutofill(String input) async {
    final body = {
      "input": input
    };

    final response = await RequestsUtil.postWithToken("/navigation/getAutofill", body);
    print(response.body);

    if (response.statusCode == 200) {
      return AutofillResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get autofill');
    }
  }
}

class BikeRoute {
  final List<LatLng> polyline;

  const BikeRoute({required this.polyline});

  static List<double> _parseDoubles(List<dynamic> list) {
    return List<double>.from(list);
  }

  static List<LatLng> _mapToLatLng(List<double> latitudes, List<double> longitudes) {
    return [for(var i=0; i<latitudes.length; i++) LatLng(latitudes[i], longitudes[i])];
  }

  factory BikeRoute.fromJson(Map<String, dynamic> jsonInit) {
    return switch (jsonInit) {
      {
      "latitudes": List<dynamic> latitudes,
      "longitudes": List<dynamic> longitudes,
      } => BikeRoute(
        // username: username,
        polyline: _mapToLatLng(_parseDoubles(latitudes), _parseDoubles(longitudes))
      ),
      _ => throw const FormatException("failed to load BikeRoute"),
    };
  }

  @override
  String toString() {
    return 'BikeRoute{polyline: $polyline}';
  }
}

class AutofillResult {
  final List<String> results;

  const AutofillResult({required this.results});

  static List<String> _parseResults(List<dynamic> list) {
    return List<String>.from(list);
    // return list.map((e) => AutofillLocation.fromJson(e)).toList(growable: false);
  }

  factory AutofillResult.fromJson(Map<String, dynamic> jsonInit) {
    return switch (jsonInit) {
      {
      "results": List<dynamic> results,
      } => AutofillResult(
        // username: username,
          results: _parseResults(results)
      ),
      _ => throw const FormatException("failed to load BikeRoute"),
    };
  }

  @override
  String toString() {
    return 'AutofillResult{results: $results}';
  }
}
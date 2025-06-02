import 'package:cycle_guard_app/data/submit_ride_service.dart';
import 'package:cycle_guard_app/data/user_daily_goal_provider.dart';
import 'package:cycle_guard_app/data/week_history_provider.dart';
import 'package:cycle_guard_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:cycle_guard_app/pages/routes_page.dart';

void main() {
  group('RoutesPage Tests', () {
    testWidgets('showPostRideDialog displays dialog with correct data', (WidgetTester tester) async {
      final rideInfo = RideInfo(
        12.3, // distance
        300.5, // calories
        45.5, // time
        [37.7749, 37.7750], // latitudes
        [-122.4194, -122.4195], // longitudes
        100.0, // climb
        50.0, // averageAltitude
      );

      final myAppState = MyAppState();
      myAppState.selectedColor = Colors.blue;

      await tester.pumpWidget(
        ChangeNotifierProvider<MyAppState>.value(
          value: myAppState,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  PostRideData.showPostRideDialog(context, rideInfo);
                });
                return Container();
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Nice!'), findsOneWidget);
      expect(find.textContaining('12.3 miles biked'), findsOneWidget);
      expect(find.textContaining('300.5 calories burned'), findsOneWidget);
      expect(find.textContaining('45 min 30 sec'), findsOneWidget);
    });

    testWidgets('Google Map widget is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(37.7749, -122.4194),
                zoom: 10,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GoogleMap), findsOneWidget);
    });

  });


}


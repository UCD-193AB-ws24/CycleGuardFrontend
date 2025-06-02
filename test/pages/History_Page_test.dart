import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:cycle_guard_app/pages/history_page.dart';
import 'package:cycle_guard_app/data/trip_history_provider.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';

import '../Mock/Mock_TripHistoryProvider.dart';
import '../Mock/Mock_UserStatsProvider.dart';

void main() {
  group('History Page Tests', () {
    testWidgets('Displays grouped trips correctly', (WidgetTester tester) async {
      // Mock providers
      final mockTripHistoryProvider = MockTripHistoryProvider();
      final mockUserStatsProvider = MockUserStatsProvider();

      await mockUserStatsProvider.fetchUserStats();
      await mockTripHistoryProvider.fetchTripHistory();

      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TripHistoryProvider>.value(value: mockTripHistoryProvider),
            ChangeNotifierProvider<UserStatsProvider>.value(value: mockUserStatsProvider),
          ],
          child: MaterialApp(
            home: HistoryPage(),
          ),
        ),
      );

      // Verify grouped trips are displayed
      expect(find.text('5-29-2025'), findsOneWidget);
    });

    testWidgets('Tapping a trip navigates correctly', (WidgetTester tester) async {
      // Mock providers
      final mockTripHistoryProvider = MockTripHistoryProvider();
      final mockUserStatsProvider = MockUserStatsProvider();

      await mockUserStatsProvider.fetchUserStats();
      await mockTripHistoryProvider.fetchTripHistory();

      // Build widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TripHistoryProvider>.value(value: mockTripHistoryProvider),
            ChangeNotifierProvider<UserStatsProvider>.value(value: mockUserStatsProvider),
          ],
          child: MaterialApp(
            home: HistoryPage(),
          ),
        ),
      );
      // Tap on a trip
      await tester.tap(find.text('5-29-2025'));
      await tester.pumpAndSettle();

      // Verify "Ride 1" is displayed
      expect(find.text('Ride 1'), findsOneWidget);

      // Verify 4 icons are displayed

      expect(find.byIcon( Icons.access_time), findsAny);
      expect(find.byIcon( Icons.directions_bike), findsAny);
      expect(find.byIcon( Icons.timer), findsAny);
      expect(find.byIcon(Icons.local_fire_department), findsAny);

      // Verify navigation logic
      // Add assertions based on your navigation implementation
    });
  });
}



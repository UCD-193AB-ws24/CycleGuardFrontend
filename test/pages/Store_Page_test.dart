import 'package:cycle_guard_app/data/achievements_progress_provider.dart';
import 'package:cycle_guard_app/data/user_daily_goal_provider.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:cycle_guard_app/data/week_history_provider.dart';
import 'package:cycle_guard_app/main.dart';
import 'package:cycle_guard_app/pages/home_page.dart';
import 'package:cycle_guard_app/pages/store_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart'; // 👈 Needed for ShowCaseWidget

import '../Mock/Mock_AchievementProvider.dart';
import '../Mock/Mock_UserStatsProvider.dart';
import '../Mock/Mock_User_Daily_Goal_Provider.dart';
import '../Mock/Mock_WeekHistoryProvider.dart';

void main() {
  group('HomePage Tests', () {
    testWidgets('Store has buttons to buy stuff', (WidgetTester tester) async {
      final mockUserStatsProvider = MockUserStatsProvider();
      final mockUserDailyGoalProvider = MockUserDailyGoalProvider();
      final mockWeekHistoryProvider = MockWeekHistoryProvider();
      final myAppState = MyAppState();
      final mockAchievementProgressProvider = MockAchievementsProgressProvider();

      await mockUserStatsProvider.fetchUserStats();
      await mockUserDailyGoalProvider.fetchDailyGoals();
      await mockAchievementProgressProvider.fetchAchievementProgress();
      await mockWeekHistoryProvider.fetchWeekHistory();

      await tester.pumpWidget(
          MediaQuery( //setting up test phone dims
            data: MediaQueryData(
              size: Size(1080, 2424),
              devicePixelRatio: 2.00,
            ) ,
            child:
            MultiProvider( //pumping all providers to widget
              providers: [
                ChangeNotifierProvider<UserDailyGoalProvider>.value(value: mockUserDailyGoalProvider),
                ChangeNotifierProvider<UserStatsProvider>.value(value: mockUserStatsProvider),
                ChangeNotifierProvider<WeekHistoryProvider>.value(value: mockWeekHistoryProvider),
                ChangeNotifierProvider<AchievementsProgressProvider>.value(value: mockAchievementProgressProvider),
                ChangeNotifierProvider<MyAppState>.value(value: myAppState),
              ],
              child: MaterialApp(
                home: ShowCaseWidget(
                  builder: (context) => StorePage(),
                ),
              ),
            ),
          )
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });

    testWidgets('Cycle Coin test', (WidgetTester tester) async {
      final mockUserStatsProvider = MockUserStatsProvider();
      final mockUserDailyGoalProvider = MockUserDailyGoalProvider();
      final mockWeekHistoryProvider = MockWeekHistoryProvider();
      final myAppState = MyAppState();
      final mockAchievementProgressProvider = MockAchievementsProgressProvider();

      await mockUserStatsProvider.fetchUserStats();
      await mockUserDailyGoalProvider.fetchDailyGoals();
      await mockAchievementProgressProvider.fetchAchievementProgress();
      await mockWeekHistoryProvider.fetchWeekHistory();

      await tester.pumpWidget(
          MediaQuery( //setting up test phone dims
            data: MediaQueryData(
              size: Size(320, 640),
              devicePixelRatio: 2.00,
            ) ,
            child:
            MultiProvider( //pumping all providers to widget
              providers: [
                ChangeNotifierProvider<UserDailyGoalProvider>.value(value: mockUserDailyGoalProvider),
                ChangeNotifierProvider<UserStatsProvider>.value(value: mockUserStatsProvider),
                ChangeNotifierProvider<WeekHistoryProvider>.value(value: mockWeekHistoryProvider),
                ChangeNotifierProvider<AchievementsProgressProvider>.value(value: mockAchievementProgressProvider),
                ChangeNotifierProvider<MyAppState>.value(value: myAppState),
              ],
              child: MaterialApp(
                home: ShowCaseWidget(
                  builder: (context) => StorePage(),
                ),
              ),
            ),
          )
      );
      await tester.pumpAndSettle();

      expect(find.text("10 CycleCoins"), findsAny);

    });

    testWidgets('Cycle Coin test', (WidgetTester tester) async {
      final mockUserStatsProvider = MockUserStatsProvider();
      final mockUserDailyGoalProvider = MockUserDailyGoalProvider();
      final mockWeekHistoryProvider = MockWeekHistoryProvider();
      final myAppState = MyAppState();
      final mockAchievementProgressProvider = MockAchievementsProgressProvider();

      await mockUserStatsProvider.fetchUserStats();
      await mockUserDailyGoalProvider.fetchDailyGoals();
      await mockAchievementProgressProvider.fetchAchievementProgress();
      await mockWeekHistoryProvider.fetchWeekHistory();

      await tester.pumpWidget(
          MediaQuery( //setting up test phone dims
            data: MediaQueryData(
              size: Size(320, 640),
              devicePixelRatio: 2.00,
            ) ,
            child:
            MultiProvider( //pumping all providers to widget
              providers: [
                ChangeNotifierProvider<UserDailyGoalProvider>.value(value: mockUserDailyGoalProvider),
                ChangeNotifierProvider<UserStatsProvider>.value(value: mockUserStatsProvider),
                ChangeNotifierProvider<WeekHistoryProvider>.value(value: mockWeekHistoryProvider),
                ChangeNotifierProvider<AchievementsProgressProvider>.value(value: mockAchievementProgressProvider),
                ChangeNotifierProvider<MyAppState>.value(value: myAppState),
              ],
              child: MaterialApp(
                home: ShowCaseWidget(
                  builder: (context) => StorePage(),
                ),
              ),
            ),
          )
      );
      await tester.pumpAndSettle();

      // Simulate button tap
      final button = find.byType(ElevatedButton).first;
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Verify SingleChildScrollView is present
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });



  });
}



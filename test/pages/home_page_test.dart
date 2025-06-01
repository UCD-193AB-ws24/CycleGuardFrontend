import 'package:cycle_guard_app/data/achievements_progress_provider.dart';
import 'package:cycle_guard_app/data/user_daily_goal_provider.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:cycle_guard_app/data/week_history_provider.dart';
import 'package:cycle_guard_app/main.dart';
import 'package:cycle_guard_app/pages/home_page.dart';
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
    testWidgets('Navigation bar displays correct items on Pixel 9 screen', (WidgetTester tester) async {
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
                    builder: (context) => MyHomePage(),
                  ),
                ),
              ),
        )
      );

      await tester.pumpAndSettle();

      // Optionally re-enable the UI checks

      expect(find.byIcon(Icons.pedal_bike), findsAny);
      expect(find.byIcon(Icons.home), findsAny);
      expect(find.byIcon(Icons.person_outline), findsAny);


    });

    testWidgets('Achievement progress displays correctly', (WidgetTester tester) async {
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
            MediaQuery(
              data: MediaQueryData(
                size: Size(320, 640),
                devicePixelRatio: 2.00,
              ),
              child: MultiProvider(
                providers: [
                  ChangeNotifierProvider<UserDailyGoalProvider>.value(value: mockUserDailyGoalProvider),
                  ChangeNotifierProvider<UserStatsProvider>.value(value: mockUserStatsProvider),
                  ChangeNotifierProvider<WeekHistoryProvider>.value(value: mockWeekHistoryProvider),
                  ChangeNotifierProvider<AchievementsProgressProvider>.value(value: mockAchievementProgressProvider),
                  ChangeNotifierProvider<MyAppState>.value(value: myAppState),
                ],
                child: MaterialApp(
                  home: ShowCaseWidget(
                    builder: (context) => MyHomePage(),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(find.text('Almost There!'), 200);

          expect(find.text('Almost There!'), findsAny);
          expect(find.text('Achievements in progress'),findsAny);
          expect(find.byType(LinearProgressIndicator), findsWidgets);
        });

    testWidgets('Tutorial starts correctly when active', (WidgetTester tester) async {
      final mockUserStatsProvider = MockUserStatsProvider();
      final mockUserDailyGoalProvider = MockUserDailyGoalProvider();
      final mockWeekHistoryProvider = MockWeekHistoryProvider();
      final myAppState = MyAppState()..isHomeTutorialActive = true;
      final mockAchievementProgressProvider = MockAchievementsProgressProvider();

      await mockUserStatsProvider.fetchUserStats();
      await mockUserDailyGoalProvider.fetchDailyGoals();
      await mockAchievementProgressProvider.fetchAchievementProgress();
      await mockWeekHistoryProvider.fetchWeekHistory();

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: Size(320, 640),
            devicePixelRatio: 2.00,
          ),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserDailyGoalProvider>.value(value: mockUserDailyGoalProvider),
              ChangeNotifierProvider<UserStatsProvider>.value(value: mockUserStatsProvider),
              ChangeNotifierProvider<WeekHistoryProvider>.value(value: mockWeekHistoryProvider),
              ChangeNotifierProvider<AchievementsProgressProvider>.value(value: mockAchievementProgressProvider),
              ChangeNotifierProvider<MyAppState>.value(value: myAppState),
            ],
            child: MaterialApp(
              home: ShowCaseWidget(
                builder: (context) => MyHomePage(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(myAppState.isHomeTutorialActive, isFalse);
      expect(myAppState.isSocialTutorialActive, isTrue);
    });

    testWidgets('Daily challenge completion displays correctly', (WidgetTester tester) async {
      final mockUserStatsProvider = MockUserStatsProvider();
      final mockUserDailyGoalProvider = MockUserDailyGoalProvider();
      final mockWeekHistoryProvider = MockWeekHistoryProvider();
      final myAppState = MyAppState();
      final mockAchievementProgressProvider = MockAchievementsProgressProvider();

      await mockUserStatsProvider.fetchUserStats();
      await mockUserDailyGoalProvider.fetchDailyGoals();
      await mockAchievementProgressProvider.fetchAchievementProgress();
      await mockWeekHistoryProvider.fetchWeekHistory();

      mockWeekHistoryProvider.dayDistances = [5.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: Size(320, 640),
            devicePixelRatio: 2.00,
          ),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserDailyGoalProvider>.value(value: mockUserDailyGoalProvider),
              ChangeNotifierProvider<UserStatsProvider>.value(value: mockUserStatsProvider),
              ChangeNotifierProvider<WeekHistoryProvider>.value(value: mockWeekHistoryProvider),
              ChangeNotifierProvider<AchievementsProgressProvider>.value(value: mockAchievementProgressProvider),
              ChangeNotifierProvider<MyAppState>.value(value: myAppState),
            ],
            child: MaterialApp(
              home: ShowCaseWidget(
                builder: (context) => MyHomePage(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Daily Challenge: Bike 5 miles'), 200);

      expect(find.text('Daily Challenge: Bike 5 miles'), findsOneWidget);
      expect(find.text('Reward: 5 CycleCoins'), findsOneWidget);
      expect(find.byIcon(Icons.directions_bike), findsAny);
    });

  });
}



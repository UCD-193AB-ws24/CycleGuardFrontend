import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:cycle_guard_app/data/week_history_provider.dart';
import 'package:provider/provider.dart';
import 'package:cycle_guard_app/pages/store_page.dart';
import 'package:cycle_guard_app/pages/history_page.dart';
import 'package:cycle_guard_app/pages/achievements_page.dart';
import 'package:cycle_guard_app/data/achievements_progress_provider.dart';
import 'package:cycle_guard_app/data/user_daily_goal_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:cycle_guard_app/data/single_trip_history.dart';
import '../auth/dim_util.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:cycle_guard_app/main.dart';
import 'package:cycle_guard_app/data/user_profile_accessor.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter/animation.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  ScrollController _controller = ScrollController();
  late AnimationController _controllerAnimation;
  late Animation<double> _animation;

  // tutorial keys
  final GlobalKey _welcomeMessageKey = GlobalKey();
  final GlobalKey _homeUIKey = GlobalKey();
  final GlobalKey _dailyChallengeKey = GlobalKey();
  final GlobalKey _rideHistoryKey = GlobalKey();
  final GlobalKey _achievementsKey = GlobalKey();
  final GlobalKey _storeKey = GlobalKey();

  @override
  void dispose() {
    _controller.dispose();
    _controllerAnimation.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _controllerAnimation = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controllerAnimation,
      curve: Curves.easeOut,
    ));

    // Trigger async providers
    Future.microtask(() {
      Provider.of<UserStatsProvider>(context, listen: false).fetchUserStats();
      Provider.of<WeekHistoryProvider>(context, listen: false)
          .fetchWeekHistory();
      Provider.of<AchievementsProgressProvider>(context, listen: false)
          .fetchAchievementProgress();
      Provider.of<UserDailyGoalProvider>(context, listen: false)
          .fetchDailyGoals();
    });

    // Wait until after first frame to check tutorial status
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = Provider.of<MyAppState>(context, listen: false);

      if (appState.isHomeTutorialActive && !appState.tutorialSkipped) {
        // Start the tutorial
        ShowCaseWidget.of(context).startShowCase([
          _welcomeMessageKey,
          _homeUIKey,
          _dailyChallengeKey,
          _rideHistoryKey,
          _achievementsKey,
          _storeKey,
        ]);

        appState.isHomeTutorialActive = false;
        appState.isSocialTutorialActive = true;
      }

      appState.addListener(_handleTutorialSkip);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controllerAnimation.forward();
    });
  }

  void _handleTutorialSkip() async {
    if (!mounted) return; // Check if widget is still mounted

    final appState = Provider.of<MyAppState>(context, listen: false);
    if (appState.tutorialSkipped) {
      // Stop any running showcase
      try {
        ShowCaseWidget.of(context).dismiss();
      } catch (e) {
        print('Error dismissing showcase: $e');
      }

      // Mark tutorial as completed (update profile and app state)
      final profile = await UserProfileAccessor.getOwnProfile();

      final updatedProfile = UserProfile(
        username: profile.username,
        displayName: profile.displayName,
        bio: profile.bio,
        profileIcon: profile.profileIcon,
        isPublic: profile.isPublic,
        isNewAccount: false,
      );

      await UserProfileAccessor.updateOwnProfile(updatedProfile);

      appState.isSocialTutorialActive = false;

      // Remove the listener after handling the skip
      appState.removeListener(_handleTutorialSkip);
    }
  }

  String formatTime(double timeInMinutes) {
    int minutes = timeInMinutes.floor();
    int seconds = ((timeInMinutes - minutes) * 60).round();

    if (seconds == 0) {
      return '$minutes min';
    } else {
      return '$minutes min $seconds sec';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStats = Provider.of<UserStatsProvider>(context);
    final weekHistory = Provider.of<WeekHistoryProvider>(context);
    final userGoals = Provider.of<UserDailyGoalProvider>(context);
    Color selectedColor = Provider.of<MyAppState>(context).selectedColor;
    final colorScheme = Theme.of(context).colorScheme;

    final todayUtcTimestamp = DateTime.utc(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          0,
          0,
          0,
          0,
          0,
        ).millisecondsSinceEpoch ~/
        1000;

    final todayInfo = weekHistory.dayHistoryMap[todayUtcTimestamp] ??
        const SingleTripInfo(
            distance: 0.0,
            calories: 0.0,
            time: 0.0,
            averageAltitude: 0,
            climb: 0);

    double todayDistance = todayInfo.distance;
    double todayCalories = todayInfo.calories;
    double todayTime = todayInfo.time;

    List<double> distancesForWeek = List.filled(7, 0.0);
    for (int i = 0; i < weekHistory.days.length; i++) {
      int day = weekHistory.days[i];
      double dayDistance = weekHistory.dayDistances[i];

      // Convert the day to the correct index (0-6, Monday-Sunday)
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(day * 1000);
      int dayIndex = dateTime.weekday - 1;

      // Assign the distance for that day
      distancesForWeek[dayIndex] = dayDistance;
    }

    List<double> rotatedDistances =
        getRotatedArray(distancesForWeek, DateTime.now().weekday - 1);
    bool isDailyChallengeComplete = rotatedDistances[6] >= 5;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 20,
                    color: isDarkMode ? Colors.white70 : Colors.black87),
                children: [
                  TextSpan(text: 'Hi, '),
                  TextSpan(
                    text: userStats.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'here is your progress',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black,
              ),
            ),
          ],
        ),
        backgroundColor: isDarkMode
            ? Theme.of(context).colorScheme.onSecondaryFixedVariant
            : Theme.of(context).colorScheme.surfaceContainer,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 32.0),
            child: Showcase(
              key: _welcomeMessageKey,
              title: 'Welcome to CycleGuard!',
              description:
                  "Tap on the screen or 'next' to continue or tap 'skip' to end the tutorial early.",
              child: SvgPicture.asset(
                'assets/cg_logomark.svg',
                height: 30,
                width: 30,
                colorFilter: ColorFilter.mode(
                  isDarkMode ? Colors.white70 : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
          )
        ],
      ),
      body: ScrollConfiguration(
        behavior: ScrollBehavior().copyWith(overscroll: false),
        child: DraggableScrollbar.arrows(
          controller: _controller,
          alwaysVisibleScrollThumb: true,
          backgroundColor: isDarkMode
              ? colorScheme.surfaceContainerLow
              : colorScheme.onSecondaryFixedVariant,
          child: ListView(
            controller: _controller,
            padding: const EdgeInsets.all(8.0),
            children: [
              Showcase(
                key: _homeUIKey,
                title: 'Home Page',
                description:
                    'See various statistics and goal progress on the home page. Set goals in profile!',
                child: Column(
                  children: [
                    Column(
                      children: [
                        Center(
                          child: Text(
                            'Past Week of Biking',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: DimUtil.safeHeight(context) * 1 / 40),
                        SizedBox(
                          height: DimUtil.safeHeight(context) * 1 / 4,
                          child: AnimatedBuilder(
                              animation: _animation,
                              builder: (context, child) {
                                return BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: 1 *
                                        rotatedDistances.reduce((a, b) => a > b
                                            ? a
                                            : b), // 1.2 * the max value in rotatedDistances
                                    barGroups: [
                                      BarChartGroupData(x: 0, barRods: [
                                        BarChartRodData(
                                            fromY: 0,
                                            toY: rotatedDistances[0] *
                                                _animation.value,
                                            color: selectedColor,
                                            width: 30.0)
                                      ]),
                                      BarChartGroupData(x: 1, barRods: [
                                        BarChartRodData(
                                            fromY: 0,
                                            toY: rotatedDistances[1] *
                                                _animation.value,
                                            color: selectedColor,
                                            width: 30.0)
                                      ]),
                                      BarChartGroupData(x: 2, barRods: [
                                        BarChartRodData(
                                            fromY: 0,
                                            toY: rotatedDistances[2] *
                                                _animation.value,
                                            color: selectedColor,
                                            width: 30.0)
                                      ]),
                                      BarChartGroupData(x: 3, barRods: [
                                        BarChartRodData(
                                            fromY: 0,
                                            toY: rotatedDistances[3] *
                                                _animation.value,
                                            color: selectedColor,
                                            width: 30.0)
                                      ]),
                                      BarChartGroupData(x: 4, barRods: [
                                        BarChartRodData(
                                            fromY: 0,
                                            toY: rotatedDistances[4] *
                                                _animation.value,
                                            color: selectedColor,
                                            width: 30.0)
                                      ]),
                                      BarChartGroupData(x: 5, barRods: [
                                        BarChartRodData(
                                            fromY: 0,
                                            toY: rotatedDistances[5] *
                                                _animation.value,
                                            color: selectedColor,
                                            width: 30.0)
                                      ]),
                                      BarChartGroupData(x: 6, barRods: [
                                        BarChartRodData(
                                            fromY: 0,
                                            toY: rotatedDistances[6] *
                                                _animation.value,
                                            color: selectedColor,
                                            width: 30.0)
                                      ]),
                                    ],
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        axisNameWidget: Text('Miles',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 20,
                                          getTitlesWidget:
                                              (double value, TitleMeta meta) {
                                            return Text(
                                                value.toInt().toString(),
                                                style: TextStyle(fontSize: 12));
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget:
                                              (double value, TitleMeta meta) {
                                            const days = [
                                              'M',
                                              'T',
                                              'W',
                                              'R',
                                              'F',
                                              'Sa',
                                              'Su'
                                            ];
                                            List<String> rotatedDays =
                                                getRotatedArray(days,
                                                    DateTime.now().weekday);
                                            return Text(
                                                rotatedDays[value.toInt()],
                                                style: TextStyle(fontSize: 12));
                                          },
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    gridData: FlGridData(
                                      drawHorizontalLine: false,
                                      drawVerticalLine: false,
                                    ),
                                    barTouchData: BarTouchData(
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (group) => isDarkMode
                                            ? colorScheme.secondary
                                            : colorScheme.secondaryFixed,
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                          return BarTooltipItem(
                                            '${rod.toY.toStringAsFixed(1)}',
                                            TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : selectedColor,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                  ),
                                );
                              }),
                        ),
                        SizedBox(height: DimUtil.safeHeight(context) * 1 / 40),
                        buildStreakDisplay(context, userStats.rideStreak),
                      ],
                    ),
                    SizedBox(height: DimUtil.safeHeight(context) * 1 / 20),
                    Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Center(
                              child: Text(
                                "Today's Goal Progress",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              top: 2,
                              child: IconButton(
                                icon: Icon(Icons.help_outline,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: isDarkMode
                                          ? colorScheme.secondary
                                          : null,
                                      title: Text(
                                        'Daily Goals',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.black,
                                        ),
                                      ),
                                      content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            userGoals.dailyDistanceGoal == 0 &&
                                                    userGoals.dailyTimeGoal ==
                                                        0 &&
                                                    userGoals
                                                            .dailyCaloriesGoal ==
                                                        0
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Your goals are currently unset.',
                                                        style: TextStyle(
                                                          color: isDarkMode
                                                              ? Colors.white70
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Your goals are currently : ',
                                                        style: TextStyle(
                                                          color: isDarkMode
                                                              ? Colors.white70
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                      Text(
                                                        ' • ${userGoals.dailyTimeGoal} minutes',
                                                        style: TextStyle(
                                                          color: isDarkMode
                                                              ? Colors.white70
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                      Text(
                                                        ' • ${userGoals.dailyDistanceGoal} miles',
                                                        style: TextStyle(
                                                          color: isDarkMode
                                                              ? Colors.white70
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                      Text(
                                                        ' • ${userGoals.dailyCaloriesGoal} calories',
                                                        style: TextStyle(
                                                          color: isDarkMode
                                                              ? Colors.white70
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            SizedBox(height: 8),
                                            Text(
                                              'You can update daily goals in your profile.',
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white70
                                                    : Colors.black,
                                              ),
                                            ),
                                          ]),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text(
                                            'OK',
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: DimUtil.safeHeight(context) * 1 / 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _AnimatedCircularStat(
                              title: formatTime(todayTime),
                              icon: Icons.access_time,
                              percent: userGoals.dailyTimeGoal == 0
                                  ? 0
                                  : todayTime / userGoals.dailyTimeGoal,
                              color: Colors.blueAccent,
                            ),
                            _AnimatedCircularStat(
                              title: '$todayDistance mi',
                              icon: Icons.directions_bike,
                              percent: userGoals.dailyDistanceGoal == 0
                                  ? 0
                                  : todayDistance / userGoals.dailyDistanceGoal,
                              color: Colors.orangeAccent,
                            ),
                            _AnimatedCircularStat(
                              title: '$todayCalories cal',
                              icon: Icons.local_fire_department,
                              percent: userGoals.dailyCaloriesGoal == 0
                                  ? 0
                                  : todayCalories / userGoals.dailyCaloriesGoal,
                              color: Colors.redAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: DimUtil.safeHeight(context) * 1 / 20),
                    Column(
                      children: [
                        Center(
                          child: Text(
                            'Average Ride this Week',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: DimUtil.safeHeight(context) * 1 / 40),
                        Row(
                          children: [
                            Flexible(
                              child: _buildStatCard(
                                  Icons.timer,
                                  'Time',
                                  '${weekHistory.averageTime.round()} min',
                                  Colors.blueAccent),
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: _buildStatCard(
                                  Icons.directions_bike,
                                  'Distance',
                                  '${weekHistory.averageDistance.round()} mi',
                                  Colors.orangeAccent),
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: _buildStatCard(
                                  Icons.local_fire_department,
                                  'Calories',
                                  '${weekHistory.averageCalories.round()} cal',
                                  Colors.redAccent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: DimUtil.safeHeight(context) * 1 / 20),
              Showcase(
                key: _dailyChallengeKey,
                title: 'Daily Challenge',
                description:
                    'Ride five miles a day to receive 5 CycleCoins for purchasing items in the store!',
                child: _buildDailyChallenge(context, isDailyChallengeComplete),
              ),
              SizedBox(height: DimUtil.safeHeight(context) * 1 / 20),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    child: Showcase(
                      key: _rideHistoryKey,
                      title: 'Ride History',
                      description:
                          'Takes you to a page with your all time ride history.',
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 6,
                          backgroundColor: isDarkMode
                              ? colorScheme.onPrimaryFixedVariant
                              : colorScheme.onInverseSurface,
                          foregroundColor:
                              isDarkMode ? Colors.white : colorScheme.primary,
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          textStyle: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HistoryPage()),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Your Ride History'),
                            SizedBox(
                                width: DimUtil.safeWidth(context) * 1 / 20),
                            Icon(Icons.calendar_month_outlined,
                                color: isDarkMode
                                    ? Colors.white
                                    : colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: DimUtil.safeHeight(context) * 1 / 20),
              Column(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Almost There!',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Achievements in progress',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: DimUtil.safeHeight(context) * 1 / 40),
                  _buildAchievementProgress(context, isDarkMode),
                ],
              ),
              SizedBox(height: DimUtil.safeHeight(context) * 1 / 40),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    child: Showcase(
                      key: _achievementsKey,
                      title: 'Achievements Page',
                      description:
                          'Takes you to where you can see all your achievements.',
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 6,
                          backgroundColor: isDarkMode
                              ? colorScheme.onPrimaryFixedVariant
                              : colorScheme.onInverseSurface,
                          foregroundColor:
                              isDarkMode ? Colors.white : colorScheme.primary,
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          textStyle: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AchievementsPage()),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Your Achievements'),
                            SizedBox(
                                width: DimUtil.safeWidth(context) * 1 / 80),
                            Icon(Icons.emoji_events,
                                color: isDarkMode
                                    ? Colors.white
                                    : colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Showcase(
        key: _storeKey,
        title: 'Open Store',
        description: 'Tap here to check out items in the store!'
            '\nWhen you are ready, go to the Social tab (person icon on the navigation bar at the bottom of the screen) '
            'to continue the tutorial!',
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    StorePage(),
                transitionDuration: Duration(milliseconds: 300),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  var offsetAnimation = Tween<Offset>(
                    begin: Offset(-1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ));

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.store,
              ),
              Text(
                'Store',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<T> getRotatedArray<T>(List<T> originalList, int x) {
    int n = originalList.length;
    x = x % n;
    List<T> firstXElements = originalList.sublist(0, x);
    List<T> remainingElements = originalList.sublist(x);
    List<T> result = []
      ..addAll(remainingElements)
      ..addAll(firstXElements);
    return result;
  }

  Widget buildStreakDisplay(BuildContext context, int rideStreak) {
    if (rideStreak > 1) {
      return Center(
        child: Text(
          '🔥 $rideStreak day streak',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return Center(
        child: Text(
          'Get out and ride — start a streak!',
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  Widget _buildStatCard(
      IconData icon, String label, String value, Color color) {
    return Card(
      color: color.withAlpha(30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 10.0),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(value,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChallenge(
      BuildContext context, bool isDailyChallengeComplete) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4)),
        ],
        border: isDailyChallengeComplete
            ? Border.all(color: Colors.amber, width: 3)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            isDailyChallengeComplete
                ? Icons.check_circle
                : Icons.directions_bike,
            color: isDailyChallengeComplete ? Colors.amber : Colors.white,
            size: 40,
          ), // Bike Icon
          SizedBox(width: DimUtil.safeWidth(context) * 1 / 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Challenge: Bike 5 miles',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: DimUtil.safeHeight(context) * 1 / 80),
                Text(
                  'Reward: 5 CycleCoins',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementProgress(BuildContext context, bool isDarkMode) {
    final achievementsProgress =
        Provider.of<AchievementsProgressProvider>(context);
    List<bool> achievementsProgressList =
        achievementsProgress.achievementsCompleted;
    List<int> priorityOrder = [ 0, 6, 3, 9, 12, 1, 4, 7, 10, 13, 14, 15, 5, 8, 11, 2];

    var result = findFirstTwoFalse(achievementsProgressList, priorityOrder);
    var selectedAchievements =
        getSelectedAchievements(result.first, result.second);

    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color:
            isDarkMode ? Theme.of(context).colorScheme.secondary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: isDarkMode ? Colors.black12 : Colors.black26,
              blurRadius: 4,
              spreadRadius: 6,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildAchievement(
            selectedAchievements[0]['title'],
            selectedAchievements[0]['description'],
            selectedAchievements[0]['progress'].toInt(),
            selectedAchievements[0]['goalValue'],
            selectedAchievements[0]['icon'],
            context,
            isDarkMode,
          ),
          SizedBox(height: DimUtil.safeHeight(context) * 1 / 40),
          _buildAchievement(
            selectedAchievements[1]['title'],
            selectedAchievements[1]['description'],
            selectedAchievements[1]['progress'].toInt(),
            selectedAchievements[1]['goalValue'],
            selectedAchievements[1]['icon'],
            context,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievement(String title, String description, int currentValue,
      int goalValue, IconData icon, BuildContext context, bool isDarkMode) {
    double progressPercentage = (currentValue / goalValue).clamp(0.0, 1.0);
    final colorScheme = Theme.of(context).colorScheme;
    Color selectedColor = Provider.of<MyAppState>(context).selectedColor;

    return Row(
      children: [
        Icon(icon, color: isDarkMode ? Colors.white : selectedColor, size: 40),
        SizedBox(width: DimUtil.safeWidth(context) * 1 / 40),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : selectedColor),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: DimUtil.safeHeight(context) * 1 / 80),
              LinearProgressIndicator(
                value: progressPercentage,
                color: isDarkMode
                    ? colorScheme.onSecondaryFixedVariant
                    : selectedColor,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              SizedBox(height: 4),
              Text(
                '${((progressPercentage) * 100).toStringAsFixed(1)}%  -----  $currentValue / $goalValue',
                style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ({int first, int second}) findFirstTwoFalse(
      List<bool> achievementsProgress, List<int> priorityOrder) {
    Map<int, int> groupMapping = {
      0: 0, 1: 0, 2: 0, // Group 1 (0-2)
      3: 1, 4: 1, 5: 1, // Group 2 (3-5)
      6: 2, 7: 2, 8: 2, // Group 3 (6-8)
      9: 3, 10: 3, 11: 3, // Group 4 (9-11)
      12: 4, 13: 4, 14: 4, 15: 4 // Group 5 (12-15)
    };

    Set<int> selectedGroups = {};
    List<int> falseIndices = [];

    if (achievementsProgress.isEmpty) {
      return (first: 0, second: 6);
    }

    for (int index in priorityOrder) {
      if (!achievementsProgress[index]) {
        int group = groupMapping[index]!;

        if (!selectedGroups.contains(group)) {
          falseIndices.add(index);
          selectedGroups.add(group);
        }

        if (falseIndices.length == 2) {
          return (first: falseIndices[0], second: falseIndices[1]);
        }
      }
    }

    for (int index in priorityOrder) {
      if (!achievementsProgress[index] && !falseIndices.contains(index)) {
        falseIndices.add(index);
        if (falseIndices.length == 2) {
          break;
        }
      }
    }

    return (
      first: falseIndices[0],
      second: falseIndices.length > 1 ? falseIndices[1] : -1
    );
  }

  Map<String, dynamic> getAchievementByIndex(int index) {
    Map<String, dynamic> achievement;
    final achievementsProgress =
        Provider.of<AchievementsProgressProvider>(context);
    final userStats = Provider.of<UserStatsProvider>(context);
    if (index < 2) {
      achievement = achievementsProgress.uniqueAchievements[index]; // 0-2
      achievement['progress'] = 0;
    } else if (index < 6) {
      achievement = achievementsProgress.distanceAchievements[index - 3]; // 3-5
      achievement['progress'] = userStats.totalDistance;
    } else if (index < 9) {
      achievement = achievementsProgress.timeAchievements[index - 6]; // 6-8
      achievement['progress'] = userStats.totalTime / 60;
    } else if (index < 12) {
      achievement =
          achievementsProgress.consistencyAchievements[index - 9]; // 9-11
      achievement['progress'] = userStats.rideStreak;
    } else {
      achievement = achievementsProgress.packsAchievements[index - 12]; // 12-15
      achievement['progress'] = 0;
    }

    return achievement;
  }

  List<Map<String, dynamic>> getSelectedAchievements(
      int firstIndex, int secondIndex) {
    return [
      getAchievementByIndex(firstIndex),
      getAchievementByIndex(secondIndex)
    ];
  }
}

class _AnimatedCircularStat extends StatefulWidget {
  final String title;
  final IconData icon;
  final double percent;
  final Color color;

  const _AnimatedCircularStat({
    required this.title,
    required this.icon,
    required this.percent,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  State<_AnimatedCircularStat> createState() => _AnimatedCircularStatState();
}

class _AnimatedCircularStatState extends State<_AnimatedCircularStat>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconSizeAnimation;
  late AnimationController _percentController;

  double _targetPercent = 0.0;
  double _animatedPercent = 0.0;

  @override
  void initState() {
    super.initState();
     debugPrint('AnimatedCircularStat initState called');

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _iconSizeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 64, end: 72), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 72, end: 64), weight: 50),
    ]).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeOut));

    _percentController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _percentController.addListener(() {
      setState(() {
        _animatedPercent = _percentController.value * _targetPercent;
      });
    });

    // Trigger animation on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _iconController.forward(from: 0);
      _animatePercent(widget.percent);
    });
  }

  void _animatePercent(double percent) {
    _targetPercent = percent.clamp(0.0, 1.0);
    _percentController.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _AnimatedCircularStat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      _animatePercent(widget.percent);
    }
  }

  /*void _handleTap() {
    _iconController.forward(from: 0);
    _animatePercent(widget.percent);
  }*/

  void _handleTap() {
    _iconController.forward(from: 0);

    if (widget.percent > 0) {
      _animatePercent(widget.percent);
    } else {
      // Optionally: show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No activity recorded yet today!')),
      );
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularPercentIndicator(
            radius: 60.0,
            lineWidth: 8.0,
            percent: _animatedPercent,
            center: AnimatedBuilder(
              animation: _iconController,
              builder: (context, child) {
                return Icon(
                  widget.icon,
                  size: _iconSizeAnimation.value,
                  color: widget.color,
                );
              },
            ),
            progressColor: widget.color,
            backgroundColor: Colors.grey.shade300,
            circularStrokeCap: CircularStrokeCap.round,
            animation: false,
          ),
          const SizedBox(height: 8),
          Text(
            widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

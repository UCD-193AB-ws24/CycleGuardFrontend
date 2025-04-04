import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:cycle_guard_app/data/week_history_provider.dart';
import 'package:provider/provider.dart';
import 'package:cycle_guard_app/pages/store_page.dart';
import 'package:cycle_guard_app/pages/history_page.dart';
import 'package:cycle_guard_app/pages/achievements_page.dart';
import 'package:cycle_guard_app/data/achievements_progress_provider.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<UserStatsProvider>(context, listen: false).fetchUserStats());
    Future.microtask(() => Provider.of<WeekHistoryProvider>(context, listen: false).fetchWeekHistory());
    Future.microtask(() => Provider.of<AchievementsProgressProvider>(context, listen: false).fetchAchievementProgress());
  }

  @override
  Widget build(BuildContext context) {
    final userStats = Provider.of<UserStatsProvider>(context);
    final weekHistory = Provider.of<WeekHistoryProvider>(context);
    //final achievementsProgress = Provider.of<AchievementsProgressProvider>(context);
    //print(achievementsProgress.achievementsCompleted);

    List<double> distancesForWeek = List.filled(7, 0.0);
    for (int i = 0; i < weekHistory.days.length; i++) {
      int day = weekHistory.days[i];
      double dayDistance = weekHistory.dayDistances[i];

      // Convert the day to the correct index (0-6, Monday-Sunday)
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(day * 1000);
      int dayIndex = dateTime.weekday;  // Adjust for Monday=0 to Sunday=6

      // Assign the distance for that day
      distancesForWeek[dayIndex] = dayDistance;
    }

    List<double>rotatedDistances = getRotatedArray(distancesForWeek, DateTime.now().weekday);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 20, color: isDarkMode ? Colors.white : Colors.black54),
                children: [
                  TextSpan(text: 'Hi, '),
                  TextSpan(
                    text: userStats.username,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Text(
              'here is your progress',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
        backgroundColor: isDarkMode ? Colors.black12 : null, 
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Past Week of Biking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1.2 * rotatedDistances.reduce((a, b) => a > b ? a : b), // 1.2 * the max value in rotatedDistances
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(fromY: 0, toY: rotatedDistances[0], color: selectedColor, width: 30.0)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(fromY: 0, toY: rotatedDistances[1], color: selectedColor, width: 30.0)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(fromY: 0, toY: rotatedDistances[2], color: selectedColor, width: 30.0)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(fromY: 0, toY: rotatedDistances[3], color: selectedColor, width: 30.0)]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(fromY: 0, toY: rotatedDistances[4], color: selectedColor, width: 30.0)]),
                    BarChartGroupData(x: 5, barRods: [BarChartRodData(fromY: 0, toY: rotatedDistances[5], color: selectedColor, width: 30.0)]),
                    BarChartGroupData(x: 6, barRods: [BarChartRodData(fromY: 0, toY: rotatedDistances[6], color: selectedColor, width: 30.0)]),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Text('Miles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(value.toInt().toString(), style: TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const days = ['M', 'T', 'W', 'R', 'F', 'Sa', 'Su'];
                          List<String> rotatedDays = getRotatedArray(days, DateTime.now().weekday); 
                          return Text(rotatedDays[value.toInt()], style: TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    drawHorizontalLine: false,
                    drawVerticalLine: false,
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => isDarkMode
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.secondaryFixed,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(1)}', 
                          TextStyle(color: isDarkMode
                            ? Colors.white
                            : selectedColor,
                          ), 
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildStatistic('Current Streak', '${userStats.rideStreak} days'),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Daily Averages',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Column(
              children: [
                _buildStatistic('Time Biking', '${weekHistory.averageTime.round()} minutes'),
                _buildStatistic('Distance Biked', '${weekHistory.averageDistance.round()} miles'),
                _buildStatistic('Calories Burned', '${weekHistory.averageCalories.round()} calories'),
              ],
            ),
            SizedBox(height: 8),
            _buildDailyChallenge(context),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 6,
                      backgroundColor: isDarkMode
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.onInverseSurface,
                      foregroundColor: isDarkMode
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HistoryPage()),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Your Trip History'),
                        SizedBox(width: 16),
                        Icon(Icons.calendar_month_outlined, color: isDarkMode
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Almost There!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Achievements in progress',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            _buildAchievementProgress(context, isDarkMode),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 6,
                      backgroundColor: isDarkMode
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.onInverseSurface,
                      foregroundColor: isDarkMode
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AchievementsPage()),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Your Achievements'),
                        SizedBox(width: 16),
                        Icon(Icons.emoji_events, color: isDarkMode
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StorePage()),
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
    );
  }

  List<T> getRotatedArray<T>(List<T> originalList, int x) {
    int n = originalList.length;
    x = x % n;
    List<T> firstXElements = originalList.sublist(0, x);
    List<T> remainingElements = originalList.sublist(x);
    List<T> result = []..addAll(remainingElements)..addAll(firstXElements);
    return result;
  }

  Widget _buildStatistic(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDailyChallenge(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.directions_bike, color: Colors.white, size: 40), // Bike Icon
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Challenge: Bike 5 miles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8),
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
    final achievementsProgress = Provider.of<AchievementsProgressProvider>(context);
    List<bool> achievementsProgressList = achievementsProgress.achievementsCompleted;
    List<int> priorityOrder = [0, 3, 6, 9, 1, 4, 7, 10, 5, 8, 11, 2];

    var result = findFirstTwoFalse(achievementsProgressList, priorityOrder);
    var selectedAchievements = getSelectedAchievements(result.first, result.second);

    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Theme.of(context).colorScheme.secondary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: isDarkMode ? Colors.black12 : Colors.black26, blurRadius: 4, spreadRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildAchievement(
            selectedAchievements[0]['title'],
            selectedAchievements[0]['progress'].toInt(),
            selectedAchievements[0]['goalValue'], 
            selectedAchievements[0]['icon'],
            context,
            isDarkMode,
          ),
          SizedBox(height: 16),
          _buildAchievement(
            selectedAchievements[1]['title'],
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

  Widget _buildAchievement(String title, int currentValue, int goalValue, IconData icon, BuildContext context, bool isDarkMode) {
    double progressPercentage = (currentValue / goalValue).clamp(0.0, 1.0);

    return Row(
      children: [
        Icon(icon, color: isDarkMode ? Colors.white : Theme.of(context).colorScheme.primary, size: 40), 
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Theme.of(context).colorScheme.primary),
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: progressPercentage,
                color: isDarkMode ? Theme.of(context).colorScheme.onSecondaryFixedVariant : Theme.of(context).colorScheme.primary,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              SizedBox(height: 4),
              Text(
                '${((progressPercentage) * 100).toStringAsFixed(1)}%  -----  $currentValue / $goalValue',
                style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ({int first, int second}) findFirstTwoFalse(List<bool> achievementsProgress, List<int> priorityOrder) {
    Map<int, int> groupMapping = {
      0: 0, 1: 0, 2: 0,  // Group 1 (0-2)
      3: 1, 4: 1, 5: 1, // Group 2 (3-5)
      6: 2, 7: 2, 8: 2, // Group 3 (6-8)
      9: 3, 10: 3, 11: 3 // Group 4 (9-11)
    };

    Set<int> selectedGroups = {};
    List<int> falseIndices = [];

    if (achievementsProgress.isEmpty) {
      return (first: 0, second: 3); 
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

    return (first: falseIndices[0], second: falseIndices.length > 1 ? falseIndices[1] : -1);
  }

  Map<String, dynamic> getAchievementByIndex(int index) {
    Map<String, dynamic> achievement;
    final achievementsProgress = Provider.of<AchievementsProgressProvider>(context);
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
    } else {
      achievement = achievementsProgress.consistencyAchievements[index - 9]; // 9-11
      achievement['progress'] = userStats.rideStreak;
    }

    return achievement;
  }

  List<Map<String, dynamic>> getSelectedAchievements(int firstIndex, int secondIndex) {
    return [getAchievementByIndex(firstIndex), getAchievementByIndex(secondIndex)];
  }
}
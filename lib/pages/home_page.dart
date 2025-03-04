import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:cycle_guard_app/data/week_history_provider.dart';
import 'package:provider/provider.dart';


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
  }

  @override
  Widget build(BuildContext context) {
    final userStats = Provider.of<UserStatsProvider>(context);
    final weekHistory = Provider.of<WeekHistoryProvider>(context);

    List<double> distancesForWeek = List.filled(7, 0.0);
    for (int i = 0; i < weekHistory.days.length; i++) {
      int day = weekHistory.days[i];
      double dayDistance = weekHistory.dayDistances[i];

      // Convert the day to the correct index (0-6, Monday-Sunday)
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(day * 1000);
      int dayIndex = dateTime.weekday - 1;  // Adjust for Monday=0 to Sunday=6

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
                  maxY: 1.05 * rotatedDistances.reduce((a, b) => a > b ? a : b), // 1.05 * the max value in rotatedDistances
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(fromY: 0, toY: rotatedDistances[0], color: selectedColor)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(fromY: 0, toY: rotatedDistances[1], color: selectedColor)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(fromY: 0, toY: rotatedDistances[2], color: selectedColor)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(fromY: 0, toY: rotatedDistances[3], color: selectedColor)]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(fromY: 0, toY: rotatedDistances[4], color: selectedColor)]),
                    BarChartGroupData(x: 5, barRods: [BarChartRodData(fromY: 0, toY: rotatedDistances[5], color: selectedColor)]),
                    BarChartGroupData(x: 6, barRods: [BarChartRodData(fromY: 0, toY: rotatedDistances[6], color: selectedColor)]),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Text('Miles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
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
                          List<String> rotatedDays = getRotatedArray(days, DateTime.now().weekday);  // Rotate days array
                          return Text(rotatedDays[value.toInt()], style: TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
            SizedBox(height: 16),
            _buildDailyChallenge(context),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Almost There! Achievements in Progress',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            _buildAchievementProgress(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  List<T> getRotatedArray<T>(List<T> originalList, int x) {
    int n = originalList.length;

    // If x is greater than the length of the array
    x = x % n;

    // Get the first x elements
    List<T> firstXElements = originalList.sublist(0, x);

    // Get the remaining elements
    List<T> remainingElements = originalList.sublist(x);

    // Create the desired array by combining the remaining elements and first x elements
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
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Theme.of(context).colorScheme.secondary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Achievement 1: Hill Conqueror
          _buildAchievement('Hill Conqueror', '7000 / 10000 meters', Icons.terrain, context, isDarkMode),
          SizedBox(height: 16),
          // Achievement 2: Tour de City
          _buildAchievement('Tour de City', '3 / 5 cities', Icons.location_city, context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildAchievement(String title, String progress, IconData icon, BuildContext context, bool isDarkMode) {
    return Row(
      children: [
        Icon(icon, color: isDarkMode ? Colors.white : Theme.of(context).colorScheme.primary, size: 40), // Achievement Icon
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
              Text(
                'Progress: $progress',
                style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
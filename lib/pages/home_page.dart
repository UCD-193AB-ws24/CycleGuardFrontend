import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                    text: 'User',
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
        backgroundColor: isDarkMode ? Colors.black12 : Colors.white,
      ),
      body: SingleChildScrollView( // Wrap the content in a SingleChildScrollView
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'This Week',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 20,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(fromY: 0, toY: 12, color: selectedColor)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(fromY: 0, toY: 8, color: selectedColor)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(fromY: 0, toY: 15, color: selectedColor)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(fromY: 0, toY: 10, color: selectedColor)]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(fromY: 0, toY: 18, color: selectedColor)]),
                    BarChartGroupData(x: 5, barRods: [BarChartRodData(fromY: 0, toY: 5, color: selectedColor)]),
                    BarChartGroupData(x: 6, barRods: [BarChartRodData(fromY: 0, toY: 14, color: selectedColor)]),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Text('Miles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
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
                          return Text(days[value.toInt()], style: TextStyle(fontSize: 12));
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
            // Move the Current Streak to its own line here
            _buildStatistic('Current Streak', '103 days'),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Weekly Statistics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Column(
              children: [
                _buildStatistic('Average Time Biking', '1 hour'),
                _buildStatistic('Average Miles Biked', '12 miles'),
                _buildStatistic('Elevation Climbed', '350 meters'),
              ],
            ),
            SizedBox(height: 16),
            // Add Daily Challenge Section
            _buildDailyChallenge(context),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Almost There! Achievements in Progress',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            // Add Achievement Progress Section
            _buildAchievementProgress(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistic(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

import 'package:flutter/material.dart';
import '../main.dart';
import 'package:cycle_guard_app/data/user_stats_accessor.dart';
import 'package:provider/provider.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';

class AchievementsPage extends StatefulWidget {
  @override
  _AchievementsPageState createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  /*double totalDistance = 0; 
  double totalTime = 0;
  int rideStreak = 0;
  int bestStreak = 0;*/

  final List<Map<String, dynamic>> uniqueAchievements = [
    {'title': 'First Ride', 'description': 'Complete your first ride', 'icon': Icons.directions_bike},
    {'title': 'Achievement Hunter', 'description': 'Complete all achievements', 'icon': Icons.emoji_events},
  ];

  final List<Map<String, dynamic>> distanceAchievements = [
    {'title': 'Challenger', 'description': 'Bike 100 miles', 'icon': Icons.flag},
    {'title': 'Champion', 'description': 'Bike 1000 miles', 'icon': Icons.flag},
    {'title': 'Conqueror', 'description': 'Bike 10000 miles', 'icon': Icons.flag},
  ];

  final List<Map<String, dynamic>> timeAchievements = [
    {'title': 'Pedal Pusher', 'description': 'Ride for 10 hours', 'icon': Icons.timer},
    {'title': 'Endurance Rider', 'description': 'Ride for 100 hours', 'icon': Icons.timer},
    {'title': 'Iron Cyclist', 'description': 'Ride for 1000 hours', 'icon': Icons.timer},
  ];

  final List<Map<String, dynamic>> consistencyAchievements = [
    {'title': 'Daily Rider', 'description': 'Ride every day for a week', 'icon': Icons.calendar_today},
    {'title': 'Month of Miles', 'description': 'Ride every day for a month', 'icon': Icons.calendar_today},
    {'title': 'Year-Round Rider', 'description': 'Ride every day for a year', 'icon': Icons.calendar_today},
  ];

  final List<bool> achievementsCompleted = [
    true, false, true, false, false, true, true, false, true, false, false
  ];

  int achievementIndex = 0; 

  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<UserStatsProvider>(context, listen: false).fetchUserStats());
    //_getUserStats();
  }

    /*void _getUserStats() async {
    final userStats = await UserStatsAccessor.getUserStats();
    if (mounted) {
      setState(() {
        totalDistance = userStats.totalDistance;
        totalTime = userStats.totalTime;
        rideStreak = userStats.rideStreak;
        bestStreak = userStats.bestStreak;
      });
    }
  }*/

  @override
  Widget build(BuildContext context) {
    //_getUserStats(); 
    final userStats = Provider.of<UserStatsProvider>(context);

    final selectedColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    achievementIndex = 0; 

    return Scaffold(
      appBar: createAppBar(context, 'Achievements'),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildSection('Unique', '', uniqueAchievements, selectedColor, isDarkMode),
          _buildSection('Distance', 'Total Miles Traveled : ${userStats.totalDistance} miles', distanceAchievements, selectedColor, isDarkMode),
          _buildSection('Time', 'Total Time Spent Riding : ${userStats.totalTime} minutes', timeAchievements, selectedColor, isDarkMode),
          _buildSection('Consistency', 'Current Days in a Row : ${userStats.rideStreak} \nBest : ${userStats.bestStreak}', consistencyAchievements, selectedColor, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, List<Map<String, dynamic>> achievements, Color selectedColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                subtitle,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
          ...achievements.map((achievement) {
            final index = achievementIndex++; // Assign and increment the global index
            return AchievementCard(
              title: achievement['title']!,
              description: achievement['description']!,
              icon: achievement['icon'],
              selectedColor: selectedColor,
              isDarkMode: isDarkMode,
              isCompleted: achievementsCompleted[index],
            );
          }),
        ],
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color selectedColor;
  final bool isDarkMode;
  final bool isCompleted;

  const AchievementCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selectedColor,
    required this.isDarkMode,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted ? Colors.amber : Colors.transparent,
          width: 2,
        ),
      ),
      elevation: 4,
      color: isDarkMode ? Theme.of(context).colorScheme.onSecondaryFixedVariant : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: isCompleted ? Colors.amber : Theme.of(context).colorScheme.onPrimaryFixed,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            if (isCompleted)
              Icon(
                Icons.check_circle,
                color: Colors.amber,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

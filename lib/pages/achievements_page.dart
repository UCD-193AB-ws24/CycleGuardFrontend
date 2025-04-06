import 'package:flutter/material.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import 'package:cycle_guard_app/data/user_stats_provider.dart';
import 'package:cycle_guard_app/data/achievements_progress_provider.dart';
import 'package:cycle_guard_app/pages/leader_page.dart';

class AchievementsPage extends StatefulWidget {
  @override
  _AchievementsPageState createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  int achievementIndex = 0; 

  @override
  void initState() {
    super.initState();
    Provider.of<UserStatsProvider>(context, listen: false).fetchUserStats();
    Provider.of<AchievementsProgressProvider>(context, listen: false).fetchAchievementProgress();
  }

  @override
  Widget build(BuildContext context) { 
    final achievementsProgress = Provider.of<AchievementsProgressProvider>(context);
    final userStats = Provider.of<UserStatsProvider>(context);
    final selectedColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    achievementIndex = 0; 

    return Scaffold(
      appBar: createAppBar(context, 'Achievements'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 4,
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
                      MaterialPageRoute(builder: (context) => LeaderPage()),
                    );
                  },
                  child: Text('View Leaderboard'),
                ),
              ),
            ),

            // The achievements sections follow
            _buildSection('Unique', '', achievementsProgress.uniqueAchievements, selectedColor, isDarkMode),
            _buildSection('Distance', 'Total Miles Traveled : \n\t${userStats.totalDistance} miles', achievementsProgress.distanceAchievements, selectedColor, isDarkMode),
            _buildSection('Time', 'Total Time Spent Riding : \n\t${userStats.totalTime ~/ 60} hours\n\t${userStats.totalTime % 60} minutes', achievementsProgress.timeAchievements, selectedColor, isDarkMode),
            _buildSection('Consistency', 'Current Days in a Row : ${userStats.rideStreak} \nBest : ${userStats.bestStreak}', achievementsProgress.consistencyAchievements, selectedColor, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, List<Map<String, dynamic>> achievements, Color selectedColor, bool isDarkMode) {
    final achievementsProgress = Provider.of<AchievementsProgressProvider>(context);
    List<bool> achievementsProgressList = achievementsProgress.achievementsCompleted;

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
                style: TextStyle(
                  fontSize: 16, 
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
              ),
            ),
          ...achievements.map((achievement) {
            final index = achievementIndex++; 
            return AchievementCard(
              title: achievement['title']!,
              description: achievement['description']!,
              icon: achievement['icon'],
              selectedColor: selectedColor,
              isDarkMode: isDarkMode,
              isCompleted: achievementsProgressList.isEmpty ? false : achievementsProgress.achievementsCompleted[index],
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
                    style: TextStyle(
                      fontSize: 12, 
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
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

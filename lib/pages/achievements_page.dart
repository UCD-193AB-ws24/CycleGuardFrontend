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
  int? selectedCardIndex;

  @override
  void initState() {
    super.initState();
    Provider.of<UserStatsProvider>(context, listen: false).fetchUserStats();
    Provider.of<AchievementsProgressProvider>(context, listen: false)
        .fetchAchievementProgress();
  }

  @override
  Widget build(BuildContext context) {
    final achievementsProgress =
        Provider.of<AchievementsProgressProvider>(context);
    final userStats = Provider.of<UserStatsProvider>(context);
    final selectedColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

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
                        ? colorScheme.onPrimaryFixedVariant
                        : colorScheme.onInverseSurface,
                    foregroundColor:
                        isDarkMode ? Colors.white : colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    textStyle:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            _buildSection('Unique', '', achievementsProgress.uniqueAchievements,
                selectedColor, isDarkMode),
            _buildSection(
                'Distance',
                'Total Miles Traveled : \n\t${userStats.totalDistance} miles',
                achievementsProgress.distanceAchievements,
                selectedColor,
                isDarkMode),
            _buildSection(
                'Time',
                'Total Time Spent Riding : \n\t${userStats.totalTime ~/ 60} hours\n\t${userStats.totalTime % 60} minutes',
                achievementsProgress.timeAchievements,
                selectedColor,
                isDarkMode),
            _buildSection(
                'Consistency',
                'Current Days in a Row : ${userStats.rideStreak} \nBest : ${userStats.bestStreak}',
                achievementsProgress.consistencyAchievements,
                selectedColor,
                isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      String title,
      String subtitle,
      List<Map<String, dynamic>> achievements,
      Color selectedColor,
      bool isDarkMode) {
    final achievementsProgress =
        Provider.of<AchievementsProgressProvider>(context);
    List<bool> achievementsProgressList =
        achievementsProgress.achievementsCompleted;

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
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedCardIndex = selectedCardIndex == index ? null : index;
                });
              },
              child: AchievementCard(
                title: achievement['title']!,
                description: achievement['description']!,
                icon: achievement['icon'],
                selectedColor: selectedColor,
                isDarkMode: isDarkMode,
                isCompleted: achievementsProgressList.isEmpty
                    ? false
                    : achievementsProgress.achievementsCompleted[index],
                isSelected: selectedCardIndex == index,
              ),
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
  final bool isSelected;

  const AchievementCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selectedColor,
    required this.isDarkMode,
    required this.isCompleted,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    double baseHeight = 80;
    double baseFontSize = 16;
    double baseDescriptionSize = 12;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isSelected ? baseHeight * 1.5 : baseHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Theme.of(context).colorScheme.onSecondaryFixedVariant
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.amber : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 40,
            color: isCompleted
                ? Colors.amber
                : Theme.of(context).colorScheme.onPrimaryFixed,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSelected ? baseFontSize * 1.5 : baseFontSize,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isSelected
                        ? baseDescriptionSize * 1.5
                        : baseDescriptionSize,
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
    );
  }
}

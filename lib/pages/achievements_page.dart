import 'package:flutter/material.dart';
import '../main.dart';

class AchievementsPage extends StatelessWidget {
  final List<Map<String, dynamic>> achievements = [
    {'title': 'First Ride', 'description': 'Complete your first ride', 'icon': Icons.directions_bike},
    {'title': 'Hill Climber', 'description': 'Climb 100 meters in elevation', 'icon': Icons.terrain},
    {'title': 'Hill Champion', 'description': 'Climb 1000 meters in elevation', 'icon': Icons.terrain},
    {'title': 'Hill Conqueror', 'description': 'Climb 10000 meters in elevation', 'icon': Icons.terrain},
    {'title': 'Tour de City', 'description': 'Ride in 5 different cities/towns', 'icon': Icons.location_city},
    {'title': 'Speedy Boy', 'description': 'Reach a speed of 15 mph', 'icon': Icons.speed},
    {'title': 'Speed Demon', 'description': 'Reach a speed of 30 mph', 'icon': Icons.speed},
    {'title': 'Speed-aholic', 'description': 'Reach a speed of 50 mph', 'icon': Icons.speed},
    {'title': 'Endurance Master', 'description': 'Ride for 3 hours nonstop', 'icon': Icons.timer},
    {'title': 'Daily Rider', 'description': 'Ride everyday for a week', 'icon': Icons.calendar_today},
    {'title': 'Month of Miles', 'description': 'Ride everyday for a month', 'icon': Icons.calendar_today},
    {'title': 'Year-Round Rider', 'description': 'Ride everyday for a year', 'icon': Icons.calendar_today},
  ];

  // Manually set which achievements are complete (True means complete)
  final List<bool> achievementsCompleted = [
    true, // First Ride
    true, // Hill Climber
    true, // Hill Champion
    false, // Hill Conqueror
    false, // Tour de City
    true, // Speedy Boy
    true, // Speed Demon
    false, // Speed-aholic
    true, // Endurance Master
    true, // Daily Rider
    true, // Month of Miles
    false, // Year-Round Rider
  ];

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: createAppBar(context, 'Achievements'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int columns = (constraints.maxWidth / 150).floor().clamp(1, 4);
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                bool isCompleted = achievementsCompleted[index];
                return AchievementCard(
                  title: achievements[index]['title']!,
                  description: achievements[index]['description']!,
                  icon: achievements[index]['icon'], 
                  selectedColor: selectedColor,
                  isDarkMode: isDarkMode,
                  isCompleted: isCompleted, 
                );
              },
            ),
          );
        },
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
      color: isDarkMode ? Theme.of(context).colorScheme.onSecondaryFixedVariant : Colors.white, // Card color
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: isCompleted ? Colors.amber : Theme.of(context).colorScheme.onPrimaryFixed, // Icon color
                ),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted) 
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.amber,
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cycle_guard_app/data/global_leaderboards_accessor.dart';
import 'package:cycle_guard_app/pages/leader.dart'; // Import Leader model'
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';

/// Function to get an appropriate user icon based on rank
IconData getUserIcon(int rank) {
  switch (rank) {
    case 1:
      return Icons.emoji_events; // 🏆 Trophy for the 1st place leader
    case 2:
      return Icons.shield_sharp;  // Shield for 2nd
    case 3:
      return Icons.anchor_sharp; // Anchor for 3rd
    default:
      return Icons.person; // 👤 Generic person icon for top 10
  }
}

Color _getIconColor(int rank) {
  switch(rank) {
    case 1:
      return Colors.orange.shade600;
    case 2:
      return Colors.grey.shade700;
    case 3:
      return const Color.fromARGB(255, 205, 76, 203);
    default:
      return Colors.blue;
  }
}

/// API call to fetch leader rankings from the backend.
Future<List<Leader>> fetchLeaders(bool isDistanceMode) async {
  final Leaderboards leaderboardData = isDistanceMode
      ? await GlobalLeaderboardsAccessor.getDistanceLeaderboards()
      : await GlobalLeaderboardsAccessor.getTimeLeaderboards();

  return Leader.fromLeaderboardEntries(leaderboardData.entries);
}

/// Leader page with two tabs: "Distance Leaders" and "Time Leaders"
class LeaderPage extends StatefulWidget {
  @override
  _LeaderPageState createState() => _LeaderPageState();
}

class _LeaderPageState extends State<LeaderPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Leader>> _futureDistanceLeaders;
  late Future<List<Leader>> _futureTimeLeaders;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _futureDistanceLeaders = fetchLeaders(true);
    _futureTimeLeaders = fetchLeaders(false);
  }

  /// Refresh leaderboard based on the active tab
  Future<void> _refreshLeaders() async {
    setState(() {
      if (_tabController.index == 0) {
        _futureDistanceLeaders = fetchLeaders(true);
      } else {
        _futureTimeLeaders = fetchLeaders(false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: isDarkMode ? Colors.white70 : null
          ),
          title: Text(
            'Leader Dashboard',
            style: TextStyle (
              color: isDarkMode ? Colors.white70 : Colors.black,
            ),
          ),
          backgroundColor: isDarkMode  ? Colors.black12 : null, 
          bottom: TabBar(
            controller: _tabController,
            unselectedLabelColor: isDarkMode ? Colors.white70 : null,
            tabs: const [
              Tab(text: "Distance"),
              Tab(text: "Time"),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 32.0),
              child: SvgPicture.asset(
                'assets/cg_logomark.svg',
                height: 30,
                width: 30,
                colorFilter: ColorFilter.mode( 
                  isDarkMode ? Colors.white70 : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            )
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLeaderboard(_futureDistanceLeaders, true),
            _buildLeaderboard(_futureTimeLeaders, false),
          ],
        ),
      ),
    );
  }

  /// Builds the leaderboard list
  Widget _buildLeaderboard(Future<List<Leader>> futureLeaders, bool isDistanceMode) {
    return RefreshIndicator(
      onRefresh: _refreshLeaders,
      child: FutureBuilder<List<Leader>>(
        future: futureLeaders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading leaderboard'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No leaderboard data found.'));
          } else {
            final leaders = snapshot.data!;
            return ListView.builder(
              itemCount: leaders.length,
              itemBuilder: (context, index) {
                final leader = leaders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 24, // Adjust size if needed
                      backgroundColor: Color.fromRGBO(33, 150, 243, 0.2), // BlueAccent with 20% opacity
                      child: Icon(
                        getUserIcon(leader.rank),
                        size: 30, // Increase icon size
                        color: _getIconColor(leader.rank), // Set a visible icon color
                      ),
                    ),
                    title: Text(leader.username),
                    subtitle: Text(
                      isDistanceMode
                          ? 'Distance: ${leader.distance.toStringAsFixed(2)} miles'
                          : 'Time: ${leader.distance.toStringAsFixed(2)} hrs',
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

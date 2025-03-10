import 'package:cycle_guard_app/data/global_leaderboards_accessor.dart';

class Leader {
  final int rank;
  final String username;
  final double distance;

  Leader({
    required this.rank,
    required this.username,
    required this.distance,
  });

  /// Converts LeaderboardEntry list into List<Leader> with assigned ranks
  static List<Leader> fromLeaderboardEntries(List<LeaderboardEntry> entries) {
    return List.generate(entries.length, (index) {
      return Leader(
        rank: index + 1, // Assign rank based on list position
        username: entries[index].username,
        distance: entries[index].value,
      );
    });
  }
}

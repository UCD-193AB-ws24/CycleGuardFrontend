import 'package:cycle_guard_app/auth/auth_util.dart';
import 'package:cycle_guard_app/data/achievements_accessor.dart';
import 'package:cycle_guard_app/data/coordinates_accessor.dart';
import 'package:cycle_guard_app/data/friend_requests_accessor.dart';
import 'package:cycle_guard_app/data/friends_list_accessor.dart';
import 'package:cycle_guard_app/data/global_leaderboards_accessor.dart';
import 'package:cycle_guard_app/data/health_info_accessor.dart';
import 'package:cycle_guard_app/data/packs_accessor.dart';
import 'package:cycle_guard_app/data/single_trip_history.dart';
import 'package:cycle_guard_app/data/submit_ride_service.dart';
import 'package:cycle_guard_app/data/trip_history_accessor.dart';
import 'package:cycle_guard_app/data/user_daily_goal_accessor.dart';
import 'package:cycle_guard_app/data/user_profile_accessor.dart';
import 'package:cycle_guard_app/data/user_settings_accessor.dart';
import 'package:cycle_guard_app/data/user_stats_accessor.dart';
import 'package:cycle_guard_app/data/week_history_accessor.dart';
import 'package:cycle_guard_app/pages/start_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './ble.dart';

import '../main.dart';

class TestingPage extends StatelessWidget {
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final ageController = TextEditingController();
  final distanceController = TextEditingController();
  final caloriesController = TextEditingController();
  final timeController = TextEditingController();

  Widget _numberField(TextEditingController controller, String hint) => TextField(
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      border: OutlineInputBorder(),
    ),
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
    textInputAction: TextInputAction.done,
  );
  
  void _closeMenu(BuildContext context) {
    Navigator.pop(context);
  }

  Future<void> _updateHealthData(BuildContext context) async {
    final height = heightController.text;
    final weight = weightController.text;
    final age = ageController.text;

    await HealthInfoAccessor.setHealthInfo(height, weight, age);
    _closeMenu(context);
  }

  Future<void> _getHealthData() async {
    final healthData = await HealthInfoAccessor.getHealthInfo();
    final height = healthData.heightInches;
    final weight = healthData.weightPounds;
    final age = healthData.ageYears;
    heightController.text = "$height";
    weightController.text = "$weight";
    ageController.text = "$age";
  }

  Future<void> _getTripHistory() async {
    final tripHistory = await TripHistoryAccessor.getTripHistory();
    print(tripHistory);
  }

  Future<void> _getCoordinates(int timestamp) async {
    final coordinates = await CoordinatesAccessor.getCoordinates(timestamp);
    print(coordinates);
  }

  void _showEnterHealthInfoMenu(BuildContext context, MyAppState appState) async {
    await _getHealthData();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              "Change fitness info",
              style: TextStyle(
                  color: Colors.black
              )
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numberField(heightController, "Height (inches)"),
              const SizedBox(height:24),
              _numberField(weightController, "Weight (pounds)"),
              const SizedBox(height:24),
              _numberField(ageController, "Age (years)"),
              const SizedBox(height:24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                ),
                onPressed: () => _updateHealthData(context),
                child: Text("Update health info"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                ),
                onPressed: () => _closeMenu(context),
                child: Text("Exit without saving"),
              ),
            ]
          )
        );
      },
    );
  }

  Future<int> _addRideInfo(double distance, double calories, double time) async {
    final timestamp = await SubmitRideService.addRideRaw(distance, calories, time, [1, 2.5, 4, 5.5], [2, 3.5, 5, 6.5]);
    print("Successfully added ride info! Timestamp: $timestamp");
    return timestamp;
  }

  Future<void> _getAchievementInfo() async {
    final achievementInfo = await AchievementInfoAccessor.getAchievementInfo();
    print(achievementInfo.getCompletedAchievements());
    print(achievementInfo);
    print("Successfully retrieved achievement info!");
  }

  Future<void> _getUserStats() async {
    final userStats = await UserStatsAccessor.getUserStats();
    print(userStats);
    print("Successfully retrieved user stats!");
  }

  Future<void> _getAllUsers() async {
    final users = await UserProfileAccessor.fetchAllUsernames();
    print(users);
    print("Successfully retrieved user list!");
  }

  Future<void> _testUserProfile() async {
    // print("Previous profile: ${await UserProfileAccessor.getOwnProfile()}");
    await UserProfileAccessor.updateOwnProfile(UserProfile(username: "", displayName: "", bio: "God of Java", isPublic: true, isNewAccount: false));
    print(await UserProfileAccessor.getOwnProfile());
    print(await UserProfileAccessor.getPublicProfile("javagod123"));
  }

  Future<void> _testUserSettings() async {
    print("Previous settings: ${await UserSettingsAccessor.getUserSettings()}");
    await UserSettingsAccessor.updateUserSettings(UserSettings(darkModeEnabled: true, currentTheme: "blue"));
    print("New settings: ${await UserSettingsAccessor.getUserSettings()}");
  }

  Future<void> _testDistanceTimeLeaderboards() async {
    print("Note: leaderboards only update when a new ride is uploaded. If your account isn't on the leaderboard, try to submit a new ride");
    print("Distance: ${await GlobalLeaderboardsAccessor.getDistanceLeaderboards()}");
    print("Time: ${await GlobalLeaderboardsAccessor.getTimeLeaderboards()}");
  }

  Future<void> _testFriendsList() async {
    print("Note: other user must login to send friend request");
    print("Current friend list: ${await FriendsListAccessor.getFriendsList()}");
    await FriendRequestsListAccessor.sendFriendRequest("javagod123");
    print("Current friend requests: ${await FriendRequestsListAccessor.getFriendRequestList()}");


    // FriendsListAccessor.removeFriend("javagod123")
    // FriendRequestsListAccessor.acceptFriendRequest("javagod123");
    // FriendRequestsListAccessor.rejectFriendRequest("javagod123");
    // FriendRequestsListAccessor.cancelFriendRequest("javagod123");
  }

  Future<void> _testAllUsers() async {
    print("Testing user/all");
    final res = await UserProfileAccessor.getAllUsers();
    print(res);
  }

  Future<void> _testDailyGoals() async {
    print("Testing daily goals");
    print("Starting goals: ${await UserDailyGoalAccessor.getUserDailyGoal()}");
    await UserDailyGoalAccessor.updateUserDailyGoal(UserDailyGoal(distance: 5, time: 30, calories: 100));
    print("Updated goals: ${await UserDailyGoalAccessor.getUserDailyGoal()}");
    await UserDailyGoalAccessor.deleteUserDailyGoal();
    print("Deleted goals: ${await UserDailyGoalAccessor.getUserDailyGoal()}");
  }

  Future<void> _testPacks() async {
    print("Testing packsgoals");
    print("Initially in pack: ${await PacksAccessor.getPackData()}");
    String packName = "${(await UserProfileAccessor.getOwnProfile()).username}'s Pack";


    await PacksAccessor.createPack(packName, "123456");
    print("Now in pack: ${await PacksAccessor.getPackData()}");

    // One day for the pack to bike 1 mile in total (no decimals allowed)
    await PacksAccessor.setPackGoal(86400, PacksAccessor.GOAL_DISTANCE, 1);
    print("Setting new goal: ${await PacksAccessor.getPackData()}");

    await SubmitRideService.addRideRaw(2, 20, 25, [123], [456]);
    print("Completing new goal: ${await PacksAccessor.getPackData()}");

    await PacksAccessor.cancelPackGoal();
    print("Cancelled goal: ${await PacksAccessor.getPackData()}");

    // Leave Pack as Owner needs to set a new owner before leaving.
    // NO_NEW_OWNER is only usable if the owner is the only remaining account in the pack.
    await PacksAccessor.leavePackAsOwner(PacksAccessor.NO_NEW_OWNER);
    print("Left pack: ${await PacksAccessor.getPackData()}");

    // Standard non-owner members of a pack must use:
    // PacksAccessor.leavePack();
  }

  Future<void> _clearPersistentToken(BuildContext context) async {
    await AuthUtil.clearPersistentToken();
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => StartPage()));
  }

  Future<void> _getWeekHistory() async {
    final weekHistory = await WeekHistoryAccessor.getWeekHistory();

    // Extract individual days
    final Map<int, SingleTripInfo> dayHistoryMap = weekHistory.dayHistoryMap;

    // Variables to hold sum of values
    double totalDistance = 0.0, totalCalories = 0.0, totalTime = 0.0;
    int numberOfDays = dayHistoryMap.length;
    List<double> dayDistances = [];
    List<int> days = [];
      
    // Iterate through each day's history
    dayHistoryMap.forEach((day, history) {
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(day * 1000);
      print("Day: $day");
      print("Day: ${["M", "T", "W", "R", "F", "Sa", "Su"][dateTime.weekday - 1]}");
      print("Distance: ${history.distance}");
      print("Calories: ${history.calories}");
      print("Time: ${history.time}\n");

      totalDistance += history.distance;
      totalCalories += history.calories;
      totalTime += history.time;
      dayDistances.add(history.distance);
      days.add(day);
    });

    // Compute averages
    double avgDistance = numberOfDays > 0 ? totalDistance / numberOfDays : 0.0;
    double avgCalories = numberOfDays > 0 ? totalCalories / numberOfDays : 0.0;
    double avgTime = numberOfDays > 0 ? totalTime / numberOfDays : 0.0;

    print("Average Distance: $avgDistance");
    print("Average Calories: $avgCalories");
    print("Average Time: $avgTime");
    print("DayDistances : $dayDistances");
    print("days: $days");
  }

  void _showRideInputPage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Ride Information"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numberField(distanceController, "Distance (miles)"),
              const SizedBox(height: 12),
              _numberField(caloriesController, "Calories burned"),
              const SizedBox(height: 12),
              _numberField(timeController, "Time (minutes)"),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final distance = double.tryParse(distanceController.text) ?? 0.0;
                  final calories = double.tryParse(caloriesController.text) ?? 0.0;
                  final time = double.tryParse(timeController.text) ?? 0.0;

                  _addRideInfo(distance, calories, time);
                  Navigator.pop(context);
                },
                child: Text("Submit Ride Info"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<MyAppState>(context);
    return Scaffold(
      appBar: createAppBar(context, 'Accessor Function Testing'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _showEnterHealthInfoMenu(context, appState),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("Set fitness info"),
                ),
                ElevatedButton(
                  onPressed: () => _showRideInputPage(context),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("Add Ride Info"),
                ),
                // ElevatedButton(
                //   onPressed: () => _getAchievementInfo(),
                //   style: ElevatedButton.styleFrom(
                //     elevation: 5,
                //     padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                //   ),
                //   child: Text("Get Achievement Info"),
                // ),
                // ElevatedButton(
                //   onPressed: () => _getWeekHistory(),
                //   style: ElevatedButton.styleFrom(
                //     elevation: 5,
                //     padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                //   ),
                //   child: Text("Get Week History"),
                // ),
                ElevatedButton(
                  onPressed: () => _getAllUsers(),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("Get All Users"),
                ),
                ElevatedButton(
                  onPressed: () => _getUserStats(),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("Get User Stats"),
                ),
                // ElevatedButton(
                //   onPressed: () => _getTripHistory(),
                //   style: ElevatedButton.styleFrom(
                //     elevation: 5,
                //     padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                //   ),
                //   child: Text("Get All Trip History"),
                // ),
                ElevatedButton(
                  onPressed: () => _getCoordinates(1741060234),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("Get Timestamp (edit value in code)"),
                ),
                ElevatedButton(
                  onPressed: () => _testUserProfile(),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("User Profile tests"),
                ),
                ElevatedButton(
                  onPressed: () => _testUserSettings(),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("User Settings tests"),
                ),
                ElevatedButton(
                  onPressed: () => _testDistanceTimeLeaderboards(),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("Leaderboards tests"),
                ),
                ElevatedButton(
                  onPressed: () => _testFriendsList(),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("Friend List tests"),
                ),
                ElevatedButton(
                  onPressed: () => _testAllUsers(),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("user/all"),
                ),
                ElevatedButton(
                  onPressed: () => showCustomDialog(context),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("BLUETOOTH"),
                ),
                ElevatedButton(
                  onPressed: () => _testPacks(),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("Test Packs"),
                ),
                ElevatedButton(
                  onPressed: () => _clearPersistentToken(context),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text("Clear token from persistent storage"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:cycle_guard_app/data/user_stats_accessor.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cycle_guard_app/pages/leader.dart'; // Import Leader model
import 'package:http/http.dart' as http;
import 'package:cycle_guard_app/data/user_profile_accessor.dart';
import 'package:cycle_guard_app/data/user_daily_goal_provider.dart';
import 'package:cycle_guard_app/data/user_daily_goal_accessor.dart';
import 'package:cycle_guard_app/data/friends_list_accessor.dart';
import 'package:cycle_guard_app/data/friend_requests_accessor.dart';
import 'package:cycle_guard_app/data/health_info_accessor.dart';
import 'package:cycle_guard_app/pages/settings_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:showcaseview/showcaseview.dart';

// for local notifications
import 'dart:developer';
/*import 'package:cycle_guard_app/pages/local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_guard_app/data/notifications_accessor.dart';*/
import 'package:cycle_guard_app/widgets/notification_scheduler.dart';

class SocialPage extends StatefulWidget {
  @override
  _SocialPageState createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int numOfTabs = 3;
  bool isPublic = true; // Move isPublic to the state class
  bool _hasFetchedIcons = false;
  late TextEditingController nameController;
  late TextEditingController bioController;
  late Future<UserProfile> _profileFuture;
  UserProfile? _profile;
  bool _isLoading = true;
  bool _hasError = false;

  bool _hasLocalProfileChanges = false;
  String _currentIconSelection = '';

  // tutorial keys
  final GlobalKey _tabsKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _iconKey = GlobalKey();
  final GlobalKey _bioKey = GlobalKey();
  final GlobalKey _updateKey = GlobalKey();
  final GlobalKey _healthInfoKey = GlobalKey();
  final GlobalKey _dailyGoalsKey = GlobalKey();
  final GlobalKey _notificationsKey = GlobalKey();
  final GlobalKey _finalMessageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: numOfTabs, vsync: this);
    _profileFuture = UserProfileAccessor.getOwnProfile();
    Future.microtask(() => Provider.of<UserDailyGoalProvider>(context, listen: false).fetchDailyGoals());
    nameController = TextEditingController();
    bioController = TextEditingController();
    _loadProfile();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = Provider.of<MyAppState>(context, listen: false);

      if (appState.isSocialTutorialActive) {
        // Start the tutorial
        ShowCaseWidget.of(context).startShowCase([
          _tabsKey,
          _settingsKey,
          _iconKey,
          _bioKey,
          _updateKey,
          _healthInfoKey,
          _dailyGoalsKey,
          _notificationsKey,
          _finalMessageKey,
        ]);

        // Mark tutorial as completed (update profile and app state)
        final profile = await UserProfileAccessor.getOwnProfile();

        final updatedProfile = UserProfile(
          username: profile.username,
          displayName: profile.displayName,
          bio: profile.bio,
          profileIcon: profile.profileIcon,
          isPublic: profile.isPublic,
          isNewAccount: false,
        );

        await UserProfileAccessor.updateOwnProfile(updatedProfile);

        appState.isSocialTutorialActive = false;
      }
    });
  }


  Future<void> _loadProfile() async {
    try {
      final profile = await UserProfileAccessor.getOwnProfile();
      final appState = Provider.of<MyAppState>(context, listen: false);

      // Update controllers after profile is fetched
      if (mounted) {
        nameController.text = profile.displayName;
        bioController.text = profile.bio;
        _currentIconSelection = profile.profileIcon;
      }

      // Post-frame icon fetching logic
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasFetchedIcons && appState.ownedIcons.isEmpty) {
          _hasFetchedIcons = true;
          appState.fetchOwnedIcons();
        }

        if (profile.profileIcon.isNotEmpty && appState.selectedIcon != profile.profileIcon) {
          if (mounted) {
            appState.selectedIcon = profile.profileIcon;
          }
        }
      });

      if (mounted) {
        setState(() {
          _profile = profile;
          isPublic = profile.isPublic;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    _tabController.dispose();
    super.dispose();
  }

    /// **Fetch all users & friend list separately**
  Future<Map<String, dynamic>> _fetchUsersAndFriends() async {
    try {
      // Fetch all users
      final UsersList allUsersList = await UserProfileAccessor.getAllUsers();
      final List<String> allUsers = allUsersList.getUsernames(); // Get all usernames

      // Fetch friend list separately
      final FriendsList friendsList = await FriendsListAccessor.getFriendsList();
      List<String> friends = friendsList.friends; // List of friends

      return {
        'users': allUsers,  // All users in the system
        'friends': friends  // Friends of the logged-in user
      };
    } catch (e) {
      print("Error fetching users & friends: $e");
      return {
        'users': [],
        'friends': []
      };
    }
  }

  /// **Send Friend Request to a User**
  Future<void> _sendFriendRequest(String username) async {
    try {
      await FriendRequestsListAccessor.sendFriendRequest(username);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Friend request sent to $username")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send request: $e")),
      );
    }
  }

  /// **Fetch pending friend requests from the backend**
  Future<List<String>> _fetchFriendRequests() async {
    try {
      final FriendRequestList friendRequestsList =
          await FriendRequestsListAccessor.getFriendRequestList();
      return friendRequestsList.pendingFriendRequests; // List of usernames who sent friend requests
    } catch (e) {
      print("Error fetching friend requests: $e");
      return [];
    }
  }

  /// **Accept a Friend Request**
  Future<void> _acceptFriendRequest(String username) async {
    try {
      await FriendRequestsListAccessor.acceptFriendRequest(username);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You are now friends with $username!")),
      );

      // Refresh friend request list
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error while accepting friend request: $e")),
      );
    }
  }

  /// **Reject a Friend Request**
  Future<void> _rejectFriendRequest(String username) async {
    try {
      await FriendRequestsListAccessor.rejectFriendRequest(username);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Friend request from $username rejected.")),
      );

      // Refresh friend request list
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to reject friend request: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (_hasError || _profile == null) {
      return Center(child: Text("Error loading profile"));
    }

    // Only build the full scaffold when we have data
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Social',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black12 : null,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Showcase(
              key: _tabsKey,
              title: 'Navigation Tabs',
              description: 'Use these tabs to switch between your profile, find bikers, or check requests.',
              child: TabBar(
                controller: _tabController,
                unselectedLabelColor: isDarkMode ? Colors.white70 : null,
                tabs: const [
                  Tab(icon: Icon(Icons.person), text: "Profile"),
                  Tab(icon: Icon(Icons.search), text: "Bikers"),
                  Tab(icon: Icon(Icons.people), text: "Requests"),
                ],
              ),
            ),
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
          SingleChildScrollView(
            child: _buildProfileTab(),
          ),
          _buildSearchTab(),
          RequestsTab(),
        ],
      ),
    );
  }

  /// **1️⃣ Profile Tab - View & Edit Profile**
  Widget _buildProfileTab() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<UserProfile>(
      future: _profileFuture,//UserProfileAccessor.getOwnProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error loading profile"));
        } else if (!snapshot.hasData) {
          return Center(child: Text("No profile data found."));
        }

        UserProfile profile = snapshot.data!;
        nameController.text = profile.displayName;
        bioController.text = profile.bio;


        final appState = Provider.of<MyAppState>(context);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Stack(
                clipBehavior: Clip.none, 
                children: [
                  Consumer<MyAppState>(
                    builder: (context, appState, child) {
                      String displayIcon = _hasLocalProfileChanges ? _currentIconSelection : appState.selectedIcon;
                      return Container(
                        width: 125,
                        height: 125,
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primaryContainer,
                        ),
                        child: SvgPicture.asset(
                          'assets/$displayIcon.svg',
                        ),
                      );
                    }
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Showcase(
                      key: _settingsKey ,
                      title: 'Settings',
                      description: 'Tap here to manage your account settings.',
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SettingsPage()),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.settings,
                              size: 40,
                              color: isDarkMode
                                ? Theme.of(context).colorScheme.secondaryFixedDim
                                : Theme.of(context).colorScheme.secondary,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                  ? Theme.of(context).colorScheme.secondaryFixedDim
                                  : Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Showcase(
                key: _iconKey ,
                title: 'Profile Icon',
                description: 'More icons can be purchased in the store!',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text("Select Profile Icon", style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),

                    Consumer<MyAppState>(
                      builder: (context, appState, child) {
                        final allIcons = [...{...appState.availableIcons, ...appState.ownedIcons}];
                        String displayedIcon = _hasLocalProfileChanges ? _currentIconSelection : appState.selectedIcon;
                        return DropdownButton<String>(
                          value: allIcons.contains(displayedIcon) ? displayedIcon : 
                            (allIcons.isNotEmpty ? allIcons.first : null),
                          items: allIcons.map((iconName) {
                            return DropdownMenuItem<String>(
                              value: iconName,
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/$iconName.svg',
                                    height: 30,
                                    width: 30,
                                    colorFilter: ColorFilter.mode(
                                      isDarkMode ? Colors.white70 : Colors.black,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(iconName),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newIcon) {
                            if (newIcon != null) {
                              setState(() {
                                appState.selectedIcon = newIcon;
                                _currentIconSelection = newIcon;
                                _hasLocalProfileChanges = true; 
                              });
                            
                              UserProfile updatedProfile = UserProfile(
                                username: profile.username,  
                                displayName: profile.displayName,
                                bio: profile.bio,
                                isPublic: isPublic,
                                isNewAccount: false,
                                profileIcon: newIcon,
                              );
                              
                              UserProfileAccessor.updateOwnProfile(updatedProfile).catchError((error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Failed to update profile icon: $error")),
                                );
                              });
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Showcase(
                key: _bioKey,
                title: 'Bio Information',
                description: "Update your name, bio, and visibility status.",
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: "Name"),
                    ),
                    TextField(
                      controller: bioController,
                      decoration: InputDecoration(labelText: "Bio"),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: isPublic,
                          onChanged: (bool? newValue) {
                            setState(() {
                              isPublic = newValue ?? true;
                            });
                          },
                        ),
                        Text("Public Profile"),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Showcase(
                    key: _updateKey ,
                    title: 'Update Profile',
                    description: 'Click this to confirm changes to your name and/or bio.',
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          UserProfile updatedProfile = UserProfile(
                            username: "", // The backend handles this, but I'll find a way on the frontend too
                            displayName: nameController.text.trim(),
                            bio: bioController.text.trim(),
                            isPublic: isPublic, 
                            isNewAccount: false,
                            profileIcon: appState.selectedIcon,
                          );

                          print("---------");
                          print(updatedProfile);

                          await UserProfileAccessor.updateOwnProfile(updatedProfile);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Profile updated successfully!")),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Failed to update profile: $e")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.onInverseSurface,
                      ),
                      child: Text(
                        "Update Profile",
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : null,
                        ),
                      ),
                    ),
                  ),
                  Showcase(
                    key: _healthInfoKey,
                    title: 'Update Health Info',
                    description: 'Health info will always be private and is used to estimate calories burned.',
                    child: ElevatedButton(
                      onPressed: () async {
                        final healthInfo = await HealthInfoAccessor.getHealthInfo();
                        final heightController = TextEditingController(text: healthInfo.heightInches.toString());
                        final weightController = TextEditingController(text: healthInfo.weightPounds.toString());
                        final ageController = TextEditingController(text: healthInfo.ageYears.toString());

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Set Health Information",
                                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Health information is kept private and will be used to estimate how many calories are burned on a ride.",
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: heightController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                    decoration: InputDecoration(
                                      labelText: "Height (inches)",
                                      labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black),
                                    ),
                                  ),
                                  TextField(
                                    controller: weightController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                    decoration: InputDecoration(
                                      labelText: "Weight (pounds)",
                                      labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black),
                                    ),
                                  ),
                                  TextField(
                                    controller: ageController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                    decoration: InputDecoration(
                                      labelText: "Age (years)",
                                      labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("Cancel", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black)),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await HealthInfoAccessor.setHealthInfoInts(
                                        int.parse(heightController.text.trim()),
                                        int.parse(weightController.text.trim()),
                                        int.parse(ageController.text.trim()),
                                      );

                                      Navigator.pop(context);

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Health info updated successfully!')),
                                      );
                                    } catch (e) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to update health info: $e')),
                                      );
                                    }
                                  },
                                  child: Text("Submit", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.onInverseSurface,
                      ),
                      child: Text(
                        "Set Health Information",
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              Column(
                children: [
                  Showcase(
                    key: _dailyGoalsKey,
                    title: 'Daily Goals',
                    description: 'Set daily goals can be seen on the home page.',
                    child: UserDailyGoalsSection(),
                  ),
                  Divider(),
                  Showcase(
                    key: _notificationsKey ,
                    title: 'Notification Manager',
                    description: 'Manage daily reminders here. Add notifications with a title, body, and time. Existing reminders will be shown here.',
                    child: NotificationScheduler(),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Showcase(
                      key: _finalMessageKey,
                      title: 'Great job!',
                      description:
                          'You can restart the tutorial in settings, enjoy CycleGuard!',
                      child: SizedBox(width: 1, height: 1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// **2️⃣ Bikers Tab - Fetch All Users & Friend Status**
  Widget _buildSearchTab() {
    TextEditingController searchController = TextEditingController();
    List<String> _friends = []; // Stores the user's friends
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark; 

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: "Search bikers...",
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  setState(() {}); // Trigger UI update for search filtering
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchUsersAndFriends(), // Fetch users & friend list
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator()); // Show loading indicator
              } else if (snapshot.hasError) {
                return Center(child: Text("Error loading users"));
              } else if (!snapshot.hasData || snapshot.data!['users'].isEmpty) {
                return Center(child: Text("No bikers found."));
              } else {
                final List<String> users = snapshot.data!['users'];
                _friends = snapshot.data!['friends']; // Update friend list

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    String user = users[index];
                    bool isFriend = _friends.contains(user); // Check if user is a friend

                    // Search filtering logic
                    if (searchController.text.isNotEmpty &&
                        !user.toLowerCase().contains(searchController.text.toLowerCase())) {
                      return SizedBox.shrink(); // Hide users who don't match the search query
                    }

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: isDarkMode ? Theme.of(context).colorScheme.onSecondaryFixedVariant : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(child: Text(user[0].toUpperCase())),
                        title: Text(
                          user,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : null,
                          ),
                        ),
                        subtitle: isFriend ? Text("Friend", style: TextStyle(color: Colors.green)) : null,
                        trailing: isFriend
                            ? null // Don't show add friend button for existing friends
                            : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.onInverseSurface,
                                foregroundColor: isDarkMode
                                    ? Colors.white70
                                    : Theme.of(context).colorScheme.primary,
                              ),
                                onPressed: () => _sendFriendRequest(user),
                                child: Text("Add Friend"),
                              ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class UserDailyGoalsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserDailyGoalProvider>(
      builder: (context, userGoals, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(height: 40),
            Text(
              "Daily Goals",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(" • Time: ${userGoals.dailyTimeGoal} min"),
            Text(" • Distance: ${userGoals.dailyDistanceGoal} mi"),
            Text(" • Calories: ${userGoals.dailyCaloriesGoal} cal"),
            SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _showChangeGoalsDialog(context, userGoals),
              child: Text("Change Goals"),
            ),
            SizedBox(height: 20),
          ],
        );
      },
    );
  }

  void _showChangeGoalsDialog(BuildContext context, UserDailyGoalProvider userGoals) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final distanceController = TextEditingController(text: userGoals.dailyDistanceGoal.toString());
    final timeController = TextEditingController(text: userGoals.dailyTimeGoal.toString());
    final caloriesController = TextEditingController(text: userGoals.dailyCaloriesGoal.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          title: Text(
            "Set New Daily Goals",
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Time (mins)",
                  labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black),
                ),
              ),
              TextField(
                controller: distanceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Distance (mi)",
                  labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black),
                ),
              ),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Calories",
                  labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final newDistance = double.tryParse(distanceController.text.trim()) ?? 0;
                  final newTime = double.tryParse(timeController.text.trim()) ?? 0;
                  final newCalories = double.tryParse(caloriesController.text.trim()) ?? 0;

                  await userGoals.updateUserGoals(newDistance, newTime, newCalories);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Goals updated!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update goals: $e")),
                  );
                }
              },
              child: Text("Submit", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black)),
            ),
          ],
        );
      },
    );
  }
}

class RequestsTab extends StatefulWidget {
  @override
  _RequestsTabState createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  List<String> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendRequests(); // Fetch friend requests on init
  }

  /// **Fetch pending friend requests from backend**
  Future<void> _loadFriendRequests() async {
    try {
      final FriendRequestList friendRequestList =
          await FriendRequestsListAccessor.getFriendRequestList();
      setState(() {
        _requests = friendRequestList.receivedFriendRequests; // Only show received requests
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading friend requests: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// **Accept a friend request and remove from UI**
  Future<void> _acceptFriendRequest(String username) async {
    try {
      await FriendRequestsListAccessor.acceptFriendRequest(username);
      setState(() {
        _requests.remove(username); // Remove from UI without re-fetching
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$username is now your friend!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to accept: $e")),
      );
    }
  }

  /// **Reject a friend request and remove from UI**
  Future<void> _rejectFriendRequest(String username) async {
    try {
      await FriendRequestsListAccessor.rejectFriendRequest(username);
      setState(() {
        _requests.remove(username); // Remove from UI without re-fetching
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Friend request from $username rejected.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to reject: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (_requests.isEmpty) {
      return Center(child: Text("No pending friend requests."));
    }

    return ListView.builder(
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        String requester = _requests[index];

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: isDarkMode ? Theme.of(context).colorScheme.onSecondaryFixedVariant : Colors.white,
          child: ListTile(
            leading: CircleAvatar(child: Text(requester[0].toUpperCase())),
            title: Text(
              requester,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : null,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "Sent you a friend request",
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : null,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check, color: Colors.green),
                  onPressed: () => _acceptFriendRequest(requester),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectFriendRequest(requester),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
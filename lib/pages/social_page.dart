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
import 'package:cycle_guard_app/data/global_leaderboards_accessor.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:cycle_guard_app/pages/packs_page.dart';

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

class _SocialPageState extends State<SocialPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int numOfTabs = 5;
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
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _dailyGoalsKey = GlobalKey();
  final GlobalKey _notificationsKey = GlobalKey();
  final GlobalKey _finalMessageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: numOfTabs, vsync: this);
    _profileFuture = UserProfileAccessor.getOwnProfile();
    Future.microtask(() =>
        Provider.of<UserDailyGoalProvider>(context, listen: false)
            .fetchDailyGoals());
    nameController = TextEditingController();
    bioController = TextEditingController();
    _loadProfile();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = Provider.of<MyAppState>(context, listen: false);

      if (appState.isSocialTutorialActive && !appState.tutorialSkipped) {
        // Start the tutorial
        ShowCaseWidget.of(context).startShowCase([
          _tabsKey,
          _profileKey,
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

      appState.addListener(_handleTutorialSkip);
    });
  }

  void _handleTutorialSkip() async {
    if (!mounted) return; // Check if widget is still mounted

    final appState = Provider.of<MyAppState>(context, listen: false);
    if (appState.tutorialSkipped) {
      // Stop any running showcase
      try {
        ShowCaseWidget.of(context).dismiss();
      } catch (e) {
        print('Error dismissing showcase: $e');
      }

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

      // Remove the listener after handling the skip
      appState.removeListener(_handleTutorialSkip);
    }
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

        if (profile.profileIcon.isNotEmpty &&
            appState.selectedIcon != profile.profileIcon) {
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
      final List<String> allUsers =
          allUsersList.getUsernames(); // Get all usernames

      // Fetch friend list separately
      final FriendsList friendsList =
          await FriendsListAccessor.getFriendsList();
      List<String> friends = friendsList.friends; // List of friends

      return {
        'users': allUsers, // All users in the system
        'friends': friends // Friends of the logged-in user
      };
    } catch (e) {
      print("Error fetching users & friends: $e");
      return {'users': [], 'friends': []};
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
      return friendRequestsList
          .pendingFriendRequests; // List of usernames who sent friend requests
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

  /// Fetches and displays a friend’s position on the distance leaderboard.
  Future<void> _showFriendRanking(BuildContext context, String username) async {
    // 1. Show a loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Fetch the distance leaderboard
      final leaderboards =
          await GlobalLeaderboardsAccessor.getDistanceLeaderboards();

      // 3. Find this friend’s entry
      final entry = leaderboards.entries.firstWhere(
        (e) => e.username == username,
        orElse: () => throw Exception('No ranking found for $username'),
      );

      // 4. Dismiss the loading dialog
      Navigator.pop(context);

      // 5. Show the results in an AlertDialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('$username’s Ranking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏅 Rank: ${leaderboards.entries.indexOf(entry) + 1}'),
              SizedBox(height: 8),
              Text('🚴 Total Distance: ${entry.value.toStringAsFixed(2)} km'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Ensure we dismiss the loading spinner
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching ranking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color selectedColor = Provider.of<MyAppState>(context).selectedColor;

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
            description:
                'Use these tabs to switch between your profile, friends, and packs.',
            child: TabBar(
              controller: _tabController,
              unselectedLabelColor: isDarkMode ? Colors.white70 : null,
              labelColor: isDarkMode ? null : selectedColor,
              indicatorColor: isDarkMode ? null : selectedColor,
              tabs: const [
                Tab(icon: Icon(Icons.person), text: "Profile"),
                Tab(icon: Icon(Icons.groups_3), text: "Friends"),
                Tab(icon: Icon(Icons.search), text: "Bikers"),
                Tab(icon: Icon(Icons.handshake_outlined), text: "Requests"),
                Tab(icon: Icon(Icons.bike_scooter_rounded), text: "Packs"),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 32.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        MyHomePage(),
                    transitionDuration: Duration(milliseconds: 500),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      var offsetAnimation = Tween<Offset>(
                        begin: Offset(0.0, -1.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ));

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Showcase(
                key: _finalMessageKey,
                title: 'Great job!',
                description:
                    'You can restart the tutorial in settings, enjoy CycleGuard!',
                child: SvgPicture.asset(
                  'assets/cg_logomark.svg',
                  height: 30,
                  width: 30,
                  colorFilter: ColorFilter.mode(
                    isDarkMode ? Colors.white70 : Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
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
          _buildFriendsTab(),
          _buildSearchTab(),
          RequestsTab(),
          PacksPage()
        ],
      ),
    );
  }

  /// **1️⃣ Profile Tab - View & Edit Profile**
  Widget _buildProfileTab() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<UserProfile>(
      future: _profileFuture, //UserProfileAccessor.getOwnProfile(),
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
                  Consumer<MyAppState>(builder: (context, appState, child) {
                    String displayIcon = _hasLocalProfileChanges
                        ? _currentIconSelection
                        : appState.selectedIcon;
                    return Container(
                      width: 125,
                      height: 125,
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDarkMode
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.primaryContainer,
                      ),
                      child: SvgPicture.asset(
                        'assets/$displayIcon.svg',
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    SettingsPage(),
                            transitionDuration: Duration(milliseconds: 300),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              var offsetAnimation = Tween<Offset>(
                                begin: Offset(-1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              ));

                              return SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.settings,
                            size: 40,
                            color: isDarkMode
                                ? Theme.of(context)
                                    .colorScheme
                                    .secondaryFixedDim
                                : Theme.of(context).colorScheme.secondary,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Theme.of(context)
                                      .colorScheme
                                      .secondaryFixedDim
                                  : Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Showcase(
                key: _profileKey,
                title: 'Profile Management',
                description:
                    'Update your icon, profile, status, and health information.',
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text("Select Profile Icon",
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Consumer<MyAppState>(
                          builder: (context, appState, child) {
                            final allIcons = [
                              ...{
                                ...appState.availableIcons,
                                ...appState.ownedIcons
                              }
                            ];
                            String displayedIcon = _hasLocalProfileChanges
                                ? _currentIconSelection
                                : appState.selectedIcon;
                            return Align(
                              // <-- Ensures DropdownButton aligns left
                              alignment: Alignment.centerLeft,
                              child: DropdownButton<String>(
                                value: allIcons.contains(displayedIcon)
                                    ? displayedIcon
                                    : (allIcons.isNotEmpty
                                        ? allIcons.first
                                        : null),
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
                                            isDarkMode
                                                ? Colors.white70
                                                : Colors.black,
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

                                    UserProfileAccessor.updateOwnProfile(
                                            updatedProfile)
                                        .catchError((error) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Failed to update profile icon: $error")),
                                      );
                                    });
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Column(
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
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              UserProfile updatedProfile = UserProfile(
                                username:
                                    "", // The backend handles this, but I'll find a way on the frontend too
                                displayName: nameController.text.trim(),
                                bio: bioController.text.trim(),
                                isPublic: isPublic,
                                isNewAccount: false,
                                profileIcon: appState.selectedIcon,
                              );

                              await UserProfileAccessor.updateOwnProfile(
                                  updatedProfile);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("Profile updated successfully!")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("Failed to update profile: $e")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context)
                                    .colorScheme
                                    .onInverseSurface,
                          ),
                          child: Text(
                            "Update Profile",
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : null,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final healthInfo =
                                await HealthInfoAccessor.getHealthInfo();
                            final heightController = TextEditingController(
                                text: healthInfo.heightInches.toString());
                            final weightController = TextEditingController(
                                text: healthInfo.weightPounds.toString());
                            final ageController = TextEditingController(
                                text: healthInfo.ageYears.toString());

                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: isDarkMode
                                      ? Colors.grey[900]
                                      : Colors.white,
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Set Health Information",
                                        style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Health information is kept private and will be used to estimate how many calories are burned on a ride.",
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.black87,
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
                                        style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black),
                                        decoration: InputDecoration(
                                          labelText: "Height (inches)",
                                          labelStyle: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black),
                                        ),
                                      ),
                                      TextField(
                                        controller: weightController,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black),
                                        decoration: InputDecoration(
                                          labelText: "Weight (pounds)",
                                          labelStyle: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black),
                                        ),
                                      ),
                                      TextField(
                                        controller: ageController,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black),
                                        decoration: InputDecoration(
                                          labelText: "Age (years)",
                                          labelStyle: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("Cancel",
                                          style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black)),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        try {
                                          await HealthInfoAccessor
                                              .setHealthInfoInts(
                                            int.parse(
                                                heightController.text.trim()),
                                            int.parse(
                                                weightController.text.trim()),
                                            int.parse(
                                                ageController.text.trim()),
                                          );

                                          Navigator.pop(context);

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Health info updated successfully!')),
                                          );
                                        } catch (e) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Failed to update health info: $e')),
                                          );
                                        }
                                      },
                                      child: Text("Submit",
                                          style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context)
                                    .colorScheme
                                    .onInverseSurface,
                          ),
                          child: Text(
                            "Set Health Information",
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              Column(
                children: [
                  Showcase(
                    key: _dailyGoalsKey,
                    title: 'Daily Goals',
                    description:
                        'Set daily goals can be seen on the home page.',
                    child: UserDailyGoalsSection(),
                  ),
                  Divider(),
                  Showcase(
                    key: _notificationsKey,
                    title: 'Notification Manager',
                    description:
                        'Manage daily reminders here. Add notifications with a title, body, and time. Existing reminders will be shown here.',
                    child: NotificationScheduler(),
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
                return Center(
                    child:
                        CircularProgressIndicator()); // Show loading indicator
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
                    bool isFriend =
                        _friends.contains(user); // Check if user is a friend

                    // Search filtering logic
                    if (searchController.text.isNotEmpty &&
                        !user
                            .toLowerCase()
                            .contains(searchController.text.toLowerCase())) {
                      return SizedBox
                          .shrink(); // Hide users who don't match the search query
                    }

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: isDarkMode
                          ? Theme.of(context)
                              .colorScheme
                              .onSecondaryFixedVariant
                          : Colors.white,
                      child: ListTile(
                        leading:
                            CircleAvatar(child: Text(user[0].toUpperCase())),
                        title: Text(
                          user,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : null,
                          ),
                        ),
                        subtitle: isFriend
                            ? Text("Friend",
                                style: TextStyle(color: Colors.green))
                            : null,
                        trailing: isFriend
                            ? null // Don't show add friend button for existing friends
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onInverseSurface,
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

  Widget _buildFriendsTab() {
    return FutureBuilder<FriendsList>(
      future: FriendsListAccessor.getFriendsList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Failed to load friends'));
        } else if (!snapshot.hasData || snapshot.data!.friends.isEmpty) {
          return Center(child: Text('You have no friends yet 😞'));
        } else {
          final List<String> friends = snapshot.data!.friends;
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(child: Text(friend[0].toUpperCase())),
                  title: Text(friend),
                  subtitle: Text('Cycling buddy 🚴'),
                  trailing: IconButton(
                    icon: Icon(Icons.emoji_events,
                        color: Theme.of(context).colorScheme.primary),
                    tooltip: 'Show Leaderboard Position',
                    onPressed: () => _showFriendRanking(context, friend),
                  ),
                ),
              );
            },
          );
        }
      },
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

  void _showChangeGoalsDialog(
      BuildContext context, UserDailyGoalProvider userGoals) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final distanceController =
        TextEditingController(text: userGoals.dailyDistanceGoal.toString());
    final timeController =
        TextEditingController(text: userGoals.dailyTimeGoal.toString());
    final caloriesController =
        TextEditingController(text: userGoals.dailyCaloriesGoal.toString());

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
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Time (mins)",
                  labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black),
                ),
              ),
              TextField(
                controller: distanceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Distance (mi)",
                  labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black),
                ),
              ),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Calories",
                  labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel",
                  style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final newDistance =
                      double.tryParse(distanceController.text.trim()) ?? 0;
                  final newTime =
                      double.tryParse(timeController.text.trim()) ?? 0;
                  final newCalories =
                      double.tryParse(caloriesController.text.trim()) ?? 0;

                  await userGoals.updateUserGoals(
                      newDistance, newTime, newCalories);

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
              child: Text("Submit",
                  style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black)),
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
        _requests = friendRequestList
            .receivedFriendRequests; // Only show received requests
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
          color: isDarkMode
              ? Theme.of(context).colorScheme.onSecondaryFixedVariant
              : Colors.white,
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

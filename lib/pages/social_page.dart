import 'package:flutter/material.dart';
import 'package:cycle_guard_app/data/user_profile_accessor.dart';
import 'package:cycle_guard_app/data/user_daily_goal_provider.dart';
import 'package:cycle_guard_app/data/friends_list_accessor.dart';
import 'package:cycle_guard_app/data/friend_requests_accessor.dart';
import 'package:cycle_guard_app/data/health_info_accessor.dart';
import 'package:cycle_guard_app/pages/settings_page.dart';
import 'package:cycle_guard_app/data/global_leaderboards_accessor.dart';
import 'package:cycle_guard_app/utils/ui_theme_helpers.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../auth/auth_util.dart';
import '../data/week_history_provider.dart';
import '../main.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:cycle_guard_app/pages/packs_page.dart';

import 'package:cycle_guard_app/widgets/notification_scheduler.dart';

class SocialPage extends StatefulWidget {
  @override
  _SocialPageState createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> with SingleTickerProviderStateMixin {
  String? _myUsername;
  Map<String, UserProfile> _userProfiles = {};
  late TabController _tabController;
  late TextEditingController _searchController;
  late final ScrollController _searchScrollController;

  late Future<Map<String, dynamic>> _usersAndFriendsFuture;

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
  HealthInfo? _currentHealth;
  UserProfile? _currentProfile;

//  final GlobalKey _socialPageKey = GlobalKey();

  @override
  void initState() {
    UserProfileAccessor.getOwnProfile().then((profile) {
      print("My username is ${profile.username}");
      setState(() {
        _myUsername = profile.username;
      });
    });
    super.initState();

    print("Social: initState()");
    _tabController = TabController(length: numOfTabs, vsync: this);
    _loadUserProfile();
    _loadHealthInfo();
    _profileFuture = UserProfileAccessor.getOwnProfile();
    Future.microtask(() =>
        Provider.of<UserDailyGoalProvider>(context, listen: false)
            .fetchDailyGoals());
    nameController = TextEditingController();
    bioController = TextEditingController();
    _searchController = TextEditingController();
    _searchScrollController = ScrollController();
    // _usersAndFriendsFuture = _fetchUsersAndFriends();
    _searchController.addListener(() => setState(() {}));
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

  void _loadHealthInfo() async {
    final health = await HealthInfoAccessor.getHealthInfo();
    if (mounted) {
      setState(() {
        _currentHealth = health;
      });
    }
  }
  
  void _loadUserProfile() async {
    try {
      final profile = await UserProfileAccessor.getOwnProfile();
      if (mounted) {
        setState(() {
          _currentProfile = profile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
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
    _searchController.dispose();
    _searchScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<String> allUsers = [], friends = [];

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

  // ignore: use_build_context_synchronously
  Future<void> _showFriendRanking(BuildContext context, String username) async {
    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final leaderboards = await GlobalLeaderboardsAccessor.getDistanceLeaderboards();
      if (!mounted) return;

      final entryIndex = leaderboards.entries.indexWhere(
            (e) => e.username.trim().toLowerCase() == username.trim().toLowerCase(),
      );

      // Fetch profile data (for bio, pack, profileIcon)
      final profile = await UserProfileAccessor.getPublicProfile(username);

      Navigator.pop(context); // dismiss loading

      if (!mounted) return;

      if (entryIndex != -1 && profile != null) {
        final entry = leaderboards.entries[entryIndex];
        final icon = profile.profileIcon;
        final bio = profile.bio.trim().isEmpty ? "No bio available" : profile.bio;
        final pack = profile.pack?.trim().isNotEmpty == true ? profile.pack : null;

        // Check if profileIcon is emoji or asset
        final isEmoji = RegExp(r'^[\u{1F300}-\u{1FAFF}]+$', unicode: true).hasMatch(icon);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            title: Row(
              children: [
                if (isEmoji)
                  Text(icon, style: const TextStyle(fontSize: 28))
                else if (icon.isNotEmpty)
                  Image.asset(
                    'assets/icons/$icon.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "$username’s Ranking",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(
                    '🏅 Rank: ${entryIndex + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🚴 Total Distance: ${entry.value.toStringAsFixed(2)} mi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (pack != null)
                    Text(
                      '📦 Pack: $pack',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '📝 Bio: $bio',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('$username’s Ranking'),
            content: const Text('No ranking found for this user.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching ranking: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = inDarkMode(context);
    Color selectedColor = Provider.of<MyAppState>(context).selectedColor;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (_hasError || _profile == null) {
      return Center(child: Text("Error loading profile"));
    }

    // Only build the full scaffold when we have data
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.settings,
            color: isDarkMode
                ? Colors.white70
                : Colors.black, // or any contrasting color
          ),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
          },
        ),  
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
              labelPadding: EdgeInsets.symmetric(horizontal: 5.0),
              tabs: const [
                Tab(icon: Icon(Icons.person), text: "Profile"),
                Tab(icon: Icon(Icons.groups_3), text: "Friends"),
                Tab(icon: Icon(Icons.handshake_outlined), text: "Requests"),
                Tab(icon: Icon(Icons.bike_scooter_rounded), text: "Packs"),
                Tab(icon: Icon(Icons.search), text: "Bikers"),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 32.0),
            child: GestureDetector(
              onTap: () {
                selectedIndexGlobal.value = 1;
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => MyHomePage(),
                    transitionDuration: Duration(milliseconds: 500),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
                      (_) => false,
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
          RequestsTab(),
          PacksPage(),
          _buildSearchTab()
        ],
      ),
    );
  }

  void _showIconSelectionModal(BuildContext context, MyAppState appState, UserProfile profile) {
    bool isDarkMode = inDarkMode(context);
    final allIcons = {...appState.availableIcons, ...appState.ownedIcons}.toList();

    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        height: 300,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: allIcons.length,
          itemBuilder: (context, index) {
            final iconName = allIcons[index];
            return GestureDetector(
              onTap: () async {
                setState(() {
                  _currentIconSelection = iconName;
                  _hasLocalProfileChanges = true;
                  appState.selectedIcon = iconName;
                });

                final updatedProfile = UserProfile(
                  username: profile.username,
                  displayName: profile.displayName,
                  bio: profile.bio,
                  isPublic: isPublic,
                  isNewAccount: false,
                  profileIcon: iconName,
                );

                try {
                  await UserProfileAccessor.updateOwnProfile(updatedProfile);
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update profile icon: $error")),
                  );
                }

                Navigator.pop(context); // Close the modal
              },
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/$iconName.svg',
                    height: 50,
                    width: 50,
                    colorFilter: (isDarkMode && !['pig', 'panda', 'tiger', 'bear', 'cow'].contains(iconName))
                        ? const ColorFilter.mode(Colors.white70, BlendMode.srcIn)
                        : null,
                  ),
                  SizedBox(height: 4),
                  Text(iconName, style: TextStyle(fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// **1️⃣ Profile Tab - View & Edit Profile**
Widget _buildProfileTab() {
  bool isDarkMode = inDarkMode(context);

  return FutureBuilder<UserProfile>(
    future: _profileFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text("Error loading profile"));
      } else if (!snapshot.hasData) {
        return Center(child: Text("No profile data found."));
      }

      UserProfile profile = snapshot.data!;
      final appState = Provider.of<MyAppState>(context);

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Showcase(
              key: _profileKey,
              title: 'Profile Management',
              description:
                  'Update your icon, profile, status, and health information.',
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<MyAppState>(builder: (context, appState, child) {
                        String displayIcon = _hasLocalProfileChanges
                            ? _currentIconSelection
                            : appState.selectedIcon;
                        return GestureDetector(
                          onTap: () => _showIconSelectionModal(context, appState, profile),
                          child: Container(
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
                          ),
                        );
                      }),
                      const SizedBox(width: 24), // ← Added spacing between icon and info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameController.text.isEmpty
                                  ? "(No display name set)"
                                  : nameController.text,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white70 : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bioController.text.isEmpty
                                  ? "(No bio provided)"
                                  : bioController.text,
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: isDarkMode ? Colors.white60 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isPublic ? "🌐 Public" : "🔒 Private",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.blue[200] : Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: Icon(
                                  Icons.edit_note_sharp,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                tooltip: "Edit Profile",
                                onPressed: () async {
                                  final refreshedProfile = await UserProfileAccessor.getOwnProfile();
                                  if (mounted) {
                                    _showEditProfileDialog(refreshedProfile);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Column(
              children: [
                Showcase(
                  key: _dailyGoalsKey,
                  title: 'Daily Goals',
                  description: 'Set daily goals can be seen on the home page.',
                  child: UserDailyGoalsSection(),
                ),
                const Divider(),
                Showcase(
                  key: _notificationsKey,
                  title: 'Notification Manager',
                  description:
                      'Manage daily reminders here. Add notifications with a title, body, and time. Existing reminders will be shown here.',
                  child: NotificationScheduler(),
                ),
                const Divider(),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed: () => AuthUtil.logout(context),
                    style: themedButtonStyle(context),
                    child: Text(
                      "Logout",
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : null,
                      ),
                    ),
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

  Future<List> _searchTabFuture = Future.wait([
    UserProfileAccessor.fetchAllUsernames(),
    FriendsListAccessor.getFriendsList(),
    FriendRequestsListAccessor.getFriendRequestList(),
    UserProfileAccessor.getAllUsers(),
  ]);

  Widget _buildStatCard(
      IconData icon, String label, String value, Color color) {
    return Card(
      color: color.withAlpha(30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10.0),
        child: Column(
          children : [
            Icon(icon, color: color),
            SizedBox(width: 15),
            Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(label,
                  style:
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black)),
              SizedBox(width: 5),
              Text(value,
                  style:
                  TextStyle(fontSize: 12, fontWeight: FontWeight.bold,color: Colors.black)),
            ],
          ),
      ],
        ),

      ),
    );
  }
  /// **2️⃣ Bikers Tab — show all bikers and filter by the search field**
  Widget _buildSearchTab() {
    bool isDarkMode = inDarkMode(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: "Search bikers...",
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {}); // Refresh search
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _searchTabFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error loading users"));
              }

              final usersRaw = snapshot.data![0] as List<String>;
              final friendsList = snapshot.data![1] as FriendsList;
              final requestList = snapshot.data![2] as FriendRequestList;
              final usersListWrapper = snapshot.data![3] as UsersList;
              final profilesList = usersListWrapper.users;
              _userProfiles = { for (var p in profilesList) p.username: p };
              //_userProfiles = userProfiles;

              //if (_myUsername == null) return SizedBox.shrink();
              final userNames = _myUsername == null
                ? usersRaw
                : usersRaw.where((u) => u != _myUsername).toList();
              //final userNames = usersRaw;
              final friends = friendsList.friends;
              final pendingSent = requestList.pendingFriendRequests;

              final query = _searchController.text.trim().toLowerCase();

              if (query.isEmpty) {
                return Center(child: Text("Start typing to search bikers."));
              }

              final filtered = userNames
                  .where((u) => u.toLowerCase().contains(query))
                  .toList();

              if (filtered.isEmpty) {
                return Center(child: Text("No bikers found."));
              }

              return Scrollbar(
                controller: _searchScrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _searchScrollController,
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final user = filtered[idx];
                    final isFriend = friends.contains(user);
                    final isPending = pendingSent.contains(user);
                    final isPendingMyAccept = requestList.receivedFriendRequests.contains(user);
                    final isPrivate = _isUserPrivate(user);
                    //final isDark    = inDarkMode(context);

                    Widget trailingWidget;
                    if (isFriend) {
                      trailingWidget = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(Icons.check, color: themedColor(context, Colors.green, Colors.lightGreenAccent), size: 16),
                          SizedBox(width: 4),
                          Text("Friend", style: TextStyle(color: themedColor(context, Colors.green, Colors.lightGreenAccent))),
                        ],
                      );
                    } else if (isPending) {
                      trailingWidget = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send, color: themedColor(context, Colors.deepOrangeAccent,  Colors.orange), size: 16),
                          SizedBox(width: 4),
                          Text("Request Sent", style: TextStyle(color: themedColor(context, Colors.deepOrangeAccent, Colors.orange))),
                        ],
                      );
                    } else if (isPendingMyAccept) {
                      trailingWidget = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mail, color: themedColor(context, Colors.black26, Colors.black12), size: 16),
                          SizedBox(width: 4),
                          Text("Accept Request", style: TextStyle(color: themedColor(context, Colors.blue, Colors.lightBlueAccent))),
                        ],
                      );
                    } else if (isPrivate) {
                      trailingWidget = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, color: themedColor(context, Colors.white70, Colors.grey), size: 16),
                          SizedBox(width: 4),
                          Text("Private", style: TextStyle(color: themedColor(context, Colors.black, Colors.black))),
                        ],
                      );
                    } else {
                      trailingWidget = ElevatedButton(
                        style: themedButtonStyle(context),
                        onPressed: () => _sendFriendRequest(user),
                        child: const Text("Add Friend"),
                      );
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: themedColor(
                        context,
                        Colors.white,
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(user[0].toUpperCase())),
                        title: GestureDetector(
                          onTap: () { /* your existing onTap */ },
                          child: Text(
                            user,
                            style: TextStyle(
                              color: themedColor(
                                context,
                                Colors.black,        // light mode text
                                Colors.black,      // dark mode text
                              ),
                            ),
                          ),
                        ),
                        subtitle: isFriend
                            ? Text("Friend", style: TextStyle(
                              color: themedColor(context, Colors.green, Colors.lightGreenAccent)))
                            : null,
                        trailing: trailingWidget,  // <— this makes the row appear
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditProfileDialog(UserProfile profile) {
    final isDarkMode = inDarkMode(context);
    final appState = context.read<MyAppState>();

    final nameController = TextEditingController(text: profile.displayName);
    final bioController = TextEditingController(text: profile.bio);
    final heightController = TextEditingController();
    final weightController = TextEditingController();
    final ageController = TextEditingController();

    // Preload health info
    HealthInfoAccessor.getHealthInfo().then((health) {
      if (!mounted) return;
      setState(() {
        heightController.text = health.heightInches.toString();
        weightController.text = health.weightPounds.toString();
        ageController.text = health.ageYears.toString();
      });
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              title: Text("Edit Profile", style: TextStyle(color: themedTextColor(context))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: themedTextColor(context)),
                      decoration: themedInputDecoration(context, "Display Name"),
                    ),
                    TextField(
                      controller: bioController,
                      style: TextStyle(color: themedTextColor(context)),
                      decoration: themedInputDecoration(context, "Bio"),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: isPublic,
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (value) {
                            setModalState(() {
                              isPublic = value ?? true;
                            });
                          },
                        ),
                        Text(
                          "Make My Profile Public",
                          style: TextStyle(color: themedTextColor(context)),
                        ),
                      ],
                    ),
                    const Divider(),
                    TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: themedTextColor(context)),
                      decoration: themedInputDecoration(context, "Height (in)"),
                    ),
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: themedTextColor(context)),
                      decoration: themedInputDecoration(context, "Weight (lb)"),
                    ),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: themedTextColor(context)),
                      decoration: themedInputDecoration(context, "Age"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: themedTextColor(context))),
                ),
                ElevatedButton(
                  style: themedButtonStyle(context),
                  onPressed: () async {
                    try {
                      final updatedProfile = UserProfile(
                        username: profile.username,
                        displayName: nameController.text.trim(),
                        bio: bioController.text.trim(),
                        isPublic: isPublic,
                        isNewAccount: false,
                        profileIcon: appState.selectedIcon,
                        pack: profile.pack,
                      );

                      final updatedHealth = HealthInfo(
                        heightInches: int.tryParse(heightController.text) ?? 0,
                        weightPounds: int.tryParse(weightController.text) ?? 0,
                        ageYears: int.tryParse(ageController.text) ?? 0,
                      );

                      await UserProfileAccessor.updateOwnProfile(updatedProfile);
                      await HealthInfoAccessor.setHealthInfoInts(updatedHealth.heightInches, updatedHealth.weightPounds, updatedHealth.ageYears);

                      if (mounted) {
                        // ✅ Sync local state fields with edited values
                        setState(() {
                          this.nameController.text = nameController.text;
                          this.bioController.text = bioController.text;
                          this.isPublic = isPublic;
                        });
                        _loadUserProfile();
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Profile and health info updated.")),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          }
        );
      },
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
                  //subtitle: Text('Cycling buddy 🚴'),
                  trailing: IconButton(
                    icon: Icon(Icons.emoji_events,
                        color: Theme.of(context).colorScheme.primary),
                    tooltip: 'Show Leaderboard Position',
                    onPressed: () => _showFriendRanking(context, friend),
                  ),
                  title: GestureDetector(
                    onTap: () async {
                      var userInfo =
                      await UserProfileAccessor.getPublicProfile(friend);
                      var userDisplayName =
                      userInfo.displayName.isNotEmpty
                          ? userInfo.displayName
                          : userInfo.username;
                      var userBio =
                      userInfo.bio.isNotEmpty ? userInfo.bio : "";
                      var userIcon = userInfo.profileIcon;
                      Provider.of<WeekHistoryProvider>(context,
                          listen: false)
                          .fetchUserWeekHistory(friend);
                      final weekHistory =
                      Provider.of<WeekHistoryProvider>(context,
                          listen: false);

                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            insetPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 40),
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              "$friend's Profile",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.black),
                              textAlign: TextAlign.center,
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/$userIcon.svg',
                                  height: 100,
                                  width: 100,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  userDisplayName,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                Text(
                                  "$userBio\n",
                                  style: const TextStyle(fontSize: 20,
                                      color: Colors.black),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Average Ride this Week',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Flexible(
                                      child: _buildStatCard(
                                        Icons.timer,
                                        'Time',
                                        '${weekHistory.averageTime.round()} min',
                                        Colors.blueAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: _buildStatCard(
                                        Icons.directions_bike,
                                        'Distance',
                                        '${weekHistory.averageDistance.round()} mi',
                                        Colors.orangeAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: _buildStatCard(
                                        Icons.local_fire_department,
                                        'Calories',
                                        '${weekHistory.averageCalories.round()} cal',
                                        Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Padding(
                                  padding:  EdgeInsets.only(top: 8),
                                  child: Text(
                                    "This user is your friend.",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ),
                            actions: [

                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  "Close",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text(
                      friend,
                      style: TextStyle(
                          color: Colors.black),
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  bool _isUserPrivate(String userId) {
    final userProfile = _userProfiles[userId];
    print("Checking if user $userId is private $userProfile.isPublic");
    return userProfile != null && userProfile.isPublic == false;
  }
}

class UserDailyGoalsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserDailyGoalProvider>(
      builder: (context, userGoals, child) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Divider(height: 40),
              Center(
                child: Text(
                  "Daily Goals",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Icon(Icons.access_time, size: 56, color: Colors.blue),
                      SizedBox(height: 8),
                      Text("${userGoals.dailyTimeGoal} min"),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.directions_bike, size: 56, color: Colors.amber),
                      SizedBox(height: 8),
                      Text("${userGoals.dailyDistanceGoal} mi"),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.local_fire_department, size: 56, color: Colors.red),
                      SizedBox(height: 8),
                      Text("${userGoals.dailyCaloriesGoal} cal"),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _showChangeGoalsDialog(context, userGoals),
                style: themedButtonStyle(context),
                child: Text(
                  "Change Goals",
                  style: TextStyle(
                    color: inDarkMode(context) ? Colors.white70 : null,
                  ),
                ),

              ),
              SizedBox(height: 8),
            ]
        );
      },
    );
  }

  void _showChangeGoalsDialog(
      BuildContext context, UserDailyGoalProvider userGoals) {
    final appState = Provider.of<MyAppState>(context, listen: false);
    bool isDarkMode = inDarkMode(context);
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
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Time (mins)", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black)),
                      Text("max 1440", style: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black54)),
                    ],
                  ),
                ),
              ),
              TextField(
                controller: distanceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style:
                TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Distance (mi)", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black)),
                      Text("max 999", style: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black54)),
                    ],
                  ),
                ),
              ),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style:
                TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Calories", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black)),
                      Text("max 9999", style: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black54)),
                    ],
                  ),
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
                  double newDistance = double.tryParse(distanceController.text.trim()) ?? 0;
                  double newTime = double.tryParse(timeController.text.trim()) ?? 0;
                  double newCalories = double.tryParse(caloriesController.text.trim()) ?? 0;

                  if (newTime > 1440) {
                    newTime = 1440;
                  }

                  if (newDistance > 999) {
                    newDistance = 999;
                  }

                  if (newCalories > 9999) {
                    newCalories = 9999;
                  }

                  await userGoals.updateUserGoals(newDistance, newTime, newCalories);

                  appState.updateGoalStatus();

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

  Future<void> _loadFriendRequests() async {
    try {
      final friendRequestList = await FriendRequestsListAccessor.getFriendRequestList();
      if (!mounted) return;
      setState(() {
        _requests = friendRequestList.receivedFriendRequests;
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
    bool isDarkMode = inDarkMode(context);
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
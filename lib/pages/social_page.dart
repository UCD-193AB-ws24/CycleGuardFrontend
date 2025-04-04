import 'package:cycle_guard_app/data/user_stats_accessor.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cycle_guard_app/pages/leader.dart'; // Import Leader model
import 'package:http/http.dart' as http;
import 'package:cycle_guard_app/data/user_profile_accessor.dart';
import 'package:cycle_guard_app/data/friends_list_accessor.dart';
import 'package:cycle_guard_app/data/friend_requests_accessor.dart';
import 'package:cycle_guard_app/data/health_info_accessor.dart';
import 'package:cycle_guard_app/pages/settings_page.dart';

class SocialPage extends StatefulWidget {
  @override
  _SocialPageState createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isPublic = true; // Move isPublic to the state class

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile(); // Load profile data including isPublic
  }

  /// **Load User Profile Data**
  Future<void> _loadUserProfile() async {
    try {
      UserProfile profile = await UserProfileAccessor.getOwnProfile();
      setState(() {
        isPublic = profile.isPublic;
      });
    } catch (e) {
      print("Error fetching profile: $e");
    }
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Social'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: "Profile"),
              Tab(icon: Icon(Icons.search), text: "Bikers"),
              Tab(icon: Icon(Icons.people), text: "Requests"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProfileTab(),
            _buildSearchTab(),
            RequestsTab(),
          ],
        ),
      ),
    );
  }

  /// **1️⃣ Profile Tab - View & Edit Profile**
  Widget _buildProfileTab() {
    TextEditingController nameController = TextEditingController();
    TextEditingController bioController = TextEditingController();
    String profileImageUrl = "https://via.placeholder.com/150"; // Replace with actual image URL

    return FutureBuilder<UserProfile>(
      future: UserProfileAccessor.getOwnProfile(),
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

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align checkbox to the left
            children: [
              Stack(
                clipBehavior: Clip.none, // Allow the button to overflow
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(profileImageUrl),
                  ),
                  Align(
                    alignment: Alignment.topRight, 
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
                            color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.secondaryFixedDim
                              : Theme.of(context).colorScheme.secondary, 
                          ),
                          SizedBox(height: 2), 
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.secondaryFixedDim
                                : Theme.of(context).colorScheme.secondary, 
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
                        isPublic = newValue ?? true; // Update state
                      });
                    },
                  ),
                  Text("Public Profile"),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    UserProfile updatedProfile = UserProfile(
                      username: "", // The backend handles this, but I'll find a way on the frontend too
                      displayName: nameController.text.trim(),
                      bio: bioController.text.trim(),
                      isPublic: isPublic, // Save public/private status
                    );

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
                child: Text("Update Profile"),
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
                      child: ListTile(
                        leading: CircleAvatar(child: Text(user[0].toUpperCase())),
                        title: Text(user),
                        subtitle: isFriend ? Text("Friend", style: TextStyle(color: Colors.green)) : null,
                        trailing: isFriend
                            ? null // Don't show add friend button for existing friends
                            : ElevatedButton(
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
          child: ListTile(
            leading: CircleAvatar(child: Text(requester[0].toUpperCase())),
            title: Text(requester),
            subtitle: Text("Sent you a friend request"),
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
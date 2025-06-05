import 'dart:async';
import 'package:cycle_guard_app/data/user_profile_accessor.dart';
import 'package:cycle_guard_app/data/friends_list_accessor.dart';
import 'package:cycle_guard_app/data/friend_requests_accessor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cycle_guard_app/utils/ui_theme_helpers.dart';
            // for themedColor(...)

class SocialDataProvider extends ChangeNotifier {
  List<String> _allUsers = [];
  List<String> _friends = [];
  List<String> _pendingSent = [];
  List<String> _pendingReceived = [];
  String? _myUsername;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, UserProfile> _userProfiles = {};

  List<String> get allUsers => _allUsers;
  List<String> get friends => _friends;
  List<String> get pendingSent => _pendingSent;
  List<String> get pendingReceived => _pendingReceived;

  String? get myUsername => _myUsername;
  UserProfile? _myProfile;

  UserProfile? get myProfile => _myProfile;

  Future<void> reloadAll() async {
    _isLoading = true;
    notifyListeners();

    // Update user profiles as well
    final usersListWrapper = await UserProfileAccessor.getAllUsers();
    final profilesList = usersListWrapper.users;
    _userProfiles = { for (var p in profilesList) p.username: p };

    final names = await UserProfileAccessor.fetchAllUsernames();
    final fl = await FriendsListAccessor.getFriendsList();
    final fr = await FriendRequestsListAccessor.getFriendRequestList();
    
    final me = await UserProfileAccessor.getOwnProfile();
    
    _myProfile = me;

    _myUsername = me.username;
    _allUsers = names.where((u) => u != me.username).toList();
    _friends = fl.friends;
    _pendingSent = fr.pendingFriendRequests;
    _pendingReceived = fr.receivedFriendRequests;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadFriendRequests(String username) async {
    await FriendRequestsListAccessor.rejectFriendRequest(username);
    _pendingReceived.remove(username);
    notifyListeners();
  }

  Future<void> sendFriendRequest(String username) async {
    await FriendRequestsListAccessor.sendFriendRequest(username);
    _pendingSent.add(username);
    notifyListeners();
  }

  Future<void> acceptFriendRequest(String username) async {
    print("Accepting friend request from $username");
    await FriendRequestsListAccessor.acceptFriendRequest(username);
    _pendingSent.add(username);
    notifyListeners();
  }

  Future<void> rejectFriendRequest(String username) async {
    await FriendRequestsListAccessor.rejectFriendRequest(username);
    _pendingReceived.remove(username);
    notifyListeners();
  }

  bool isUserPrivate(String userId) {
    final userProfile = _userProfiles[userId];
    if (userProfile == null) {
      print("⚠️ No profile found for $userId");
      return false; // or maybe: return null;
    }
    print("Checking if user $userId is private: isPublic=${userProfile.isPublic}");
    return userProfile.isPublic == false;
  }
  
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  bool userExists(String userId) {
    final userProfile = _userProfiles[userId];
    if (userProfile == null) {
      print("⚠️ User not found $userId");
      return false; // or maybe: return null;
    }
    print("Found user $userId");
    return true;
  }

  /// ------------------------------------------------------------------
  /// A helper that draws a circular background (adapting to light/dark)
  /// and places the SVG icon (tinted) in its center.
  ///
  /// • [iconName]: filename without “.svg” (e.g. "panda")
  /// • [diameter]: total width/height of the circle.
  Widget buildCircularIconAvatar(
    BuildContext context, {
    required String iconName,
    double diameter = 40.0,
  }) {
    final fgColor = themedColor(context, Colors.black, Colors.white70);
    final bgColor = themedColor(context, Colors.grey.shade200, Colors.grey.shade800);

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: SvgPicture.asset(
          'assets/$iconName.svg',
          fit: BoxFit.contain,
          //colorFilter: ColorFilter.mode(fgColor, BlendMode.srcIn),
        ),
      ),
    );
  }

  /// ------------------------------------------------------------------
  /// (A) Build a CircleAvatar from an already‐loaded UserProfile.
  /// If `profile.profileIcon` is non‐empty, show that SVG (tinted for light/dark);
  /// otherwise fall back to the first two initials.
  ///
  /// Use this when you already have a UserProfile object in memory
  /// (e.g. provider.myProfile for the logged‐in user).
  Widget buildAvatarFromProfile(
    BuildContext context,
    UserProfile profile, {
    double avatarDiameter = 40.0,
  }) {
    final username = profile.username;
    final iconName = profile.profileIcon.trim();

    // Foreground tint (SVG or initials text): black in light mode, white70 in dark mode
    final Color fgColor = themedColor(context, Colors.black, Colors.white70);

    // Background for initials (light grey in light mode, dark grey in dark mode)
    final Color bgColor = themedColor(
      context,
      Colors.grey.shade700,
      Colors.grey.shade300,
    );

    if (iconName.isNotEmpty) {
      // Show the SVG avatar, tinted to fgColor
      print("Building avatar for $username with icon: $iconName");
            // Use the new circular background + tinted SVG helper:
      return buildCircularIconAvatar(
        context,
        iconName: iconName,
        diameter: avatarDiameter,
      );
    }

    // Fallback → two‐letter initials
    final initials = (username.length >= 2)
        ? username.substring(0, 2).toUpperCase()
        : username[0].toUpperCase();
    return CircleAvatar(
      radius: avatarDiameter / 2,
      backgroundColor: bgColor,
      child: Text(
        initials,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// ------------------------------------------------------------------
  /// (B) Build a CircleAvatar for any username whose profile is already in `_userProfiles`.
  ///   • If `_userProfiles` does not contain that username yet, return null so the caller
  ///     can decide to show a spinner or placeholder until reloadAll() finishes.
  ///   • If found and `profileIcon` is non‐empty, show the SVG; otherwise show initials.
  ///
  /// Use this for “friend” avatars, since `reloadAll()` already populated `_userProfiles`.
    /// ------------------------------------------------------------------
  /// Synchronously build a CircleAvatar for a username. Since _userProfiles
  /// is already populated by reloadAll(), we never “wait” here—if the
  /// profile isn’t found in the map, we just show initials immediately.
  ///
  Widget buildAvatarFromCache(
    BuildContext context,
    String username, {
    double avatarDiameter = 40.0,
  }) {
    // Foreground color for text or SVG tint:
    final Color fgColor = themedColor(context, Colors.black, Colors.white70);

    // Background for initials (light grey in light mode, dark grey in dark mode):
    final Color bgColor = themedColor(
      context,
      Colors.grey.shade300,
      Colors.grey.shade700,
    );

    // Try to grab the cached UserProfile (if any):
    final UserProfile? profile = _userProfiles[username];

    // If there’s a profile AND it has a non‐empty profileIcon, show SVG:
    if (profile != null && profile.profileIcon.trim().isNotEmpty) {
      final iconName = profile.profileIcon.trim();
      return buildCircularIconAvatar(
        context,
        iconName: iconName,
        diameter: avatarDiameter,
      );
    }

    // Otherwise, fallback to initials immediately:
    final initials = (username.length >= 2)
        ? username.substring(0, 2).toUpperCase()
        : username[0].toUpperCase();
    return CircleAvatar(
      radius: avatarDiameter / 2,
      backgroundColor: bgColor,
      child: Text(
        initials,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
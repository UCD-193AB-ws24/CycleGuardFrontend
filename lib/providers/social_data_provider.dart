import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cycle_guard_app/data/user_profile_accessor.dart';
import 'package:cycle_guard_app/data/friends_list_accessor.dart';
import 'package:cycle_guard_app/data/friend_requests_accessor.dart';

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
}
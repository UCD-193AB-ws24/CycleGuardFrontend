import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
import 'package:cycle_guard_app/data/friends_list_accessor.dart';

class UserProfileAccessor {
  UserProfileAccessor._();

  static Future<UserProfile> getOwnProfile() async {
    final response = await RequestsUtil.getWithToken("/profile/getProfile");

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get user stats');
    }
  }

  static Future<UserProfile> getPublicProfile(String username) async {
    final response = await RequestsUtil.getWithToken("/profile/getPublicProfile/$username");

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get user stats');
    }
  }

  static Future<void> updateOwnProfile(UserProfile profile) async {
    final body = profile.toJson();
    final response = await RequestsUtil.postWithToken("/profile/updateProfile", body);

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to add ride');
    }
  }

  static Future<List<String>> fetchAllUsernames() async {
    final UsersList allUsers = await UserProfileAccessor.getAllUsers();
    print(allUsers);
    return [];
    // return allUsers.users; // Directly return the List<String>
  }

  /// **Fetches all users from the system**
  static Future<UsersList> getAllUsers() async {
    final response = await RequestsUtil.getWithToken("/user/all");
    print(response.body);

    if (response.statusCode == 200) {
      return UsersList.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get Users list');
    }
  }
}

class UserProfile {
  final String username, displayName, bio, profileIcon;
  final bool isPublic, isNewAccount;

  const UserProfile({
    required this.username,
    required this.displayName,
    required this.bio,
    required this.profileIcon,
    required this.isPublic,
    required this.isNewAccount
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "username": String username,
        "displayName": String displayName,
        "bio": String bio,
        "isPublic": bool isPublic,
        "isNewAccount": bool isNewAccount,
        "profileIcon": String profileIcon
      } => UserProfile(
          username: username,
          displayName: displayName,
          bio: bio,
          profileIcon: profileIcon,
          isPublic: isPublic,
          isNewAccount: isNewAccount
      ),
      _ => throw const FormatException("failed to load UserProfile"),
    };
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'displayName': displayName,
    'bio': bio,
    'isPublic': isPublic,
    'isNewAccount': isNewAccount,
    'profileIcon': profileIcon
  };

  /// **Converts a List of JSON user entries into a List<UserProfile>**
  static List<UserProfile> fromUsersListEntries(List<Map<String, dynamic>> users) {
    return users.map((user) => UserProfile.fromJson(user)).toList();
  }

  /// **Extracts usernames from a list of UserProfiles**
  static List<String> getUsernames(List<UserProfile> profiles) {
    return profiles.map((profile) => profile.displayName).toList();
  }

  @override
  String toString() {
    return 'UserProfile{displayName: $displayName, bio: $bio, isPublic: $isPublic, profileIcon: $profileIcon, isPublic: $isPublic, isNewAccount: $isNewAccount}';
  }
}

class UsersList {
  final String username;
  final List<UserProfile> users;

  const UsersList({required this.username, required this.users});

  static List<UserProfile> _parseUsersList(List<dynamic> list) {
    print(list);
    return list.map((user) => UserProfile.fromJson(user)).toList();
  }

  factory UsersList.fromJson(Map<String, dynamic> jsonInit) {
    return switch (jsonInit) {
      {
      "username": String username,
      "users": List<dynamic> users,
      } => UsersList(
        // username: username,
        username: username,
        users: _parseUsersList(users)
      ),
      _ => throw const FormatException("failed to load UsersList"),
    };
  }

  @override
  String toString() {
    return 'UsersList{username: $username, users: $users}';
  }

  List<String> getUsernames() {
    return this.users.map((user) => user.username).toList();
  }

  List<String> getDisplayNames() {
    return this.users.map((user) => user.displayName).toList();
  }
}
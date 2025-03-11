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
    return allUsers.users; // Directly return the List<String>
  }

  /// **Fetches all users from the system**
  static Future<UsersList> getAllUsers() async {
    final response = await RequestsUtil.getWithToken("/user/all");

    if (response.statusCode == 200) {
      return UsersList.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get Users list');
    }
  }
}

class UserProfile {
  final String displayName, bio;
  final bool isPublic;

  const UserProfile({
    required this.displayName,
    required this.bio,
    required this.isPublic,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      "displayName": String displayName,
      "bio": String bio,
      "isPublic": bool isPublic
      } => UserProfile(
          displayName: displayName,
          bio: bio,
          isPublic: isPublic
      ),
      _ => throw const FormatException("failed to load UserProfile"),
    };
  }

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'bio': bio,
    'isPublic': isPublic
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
    return 'UserProfile{displayName: $displayName, bio: $bio, isPublic: $isPublic}';
  }
}

class UsersList {
  final String username;
  final List<String> users;

  const UsersList({required this.username, required this.users});

  static List<String> _parseUsernameList(List<dynamic> list) {
    return List<String>.from(list);
  }

  factory UsersList.fromJson(Map<String, dynamic> jsonInit) {
    return switch (jsonInit) {
      {
      "username": String username,
      "users": List<dynamic> users,
      } => UsersList(
        // username: username,
        username: username,
        users: _parseUsernameList(users)
      ),
      _ => throw const FormatException("failed to load UsersList"),
    };
  }

  @override
  String toString() {
    return 'UsersList{username: $username, users: $users}';
  }
}
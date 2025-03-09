import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';

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

  @override
  String toString() {
    return 'UserProfile{displayName: $displayName, bio: $bio, isPublic: $isPublic}';
  }
}
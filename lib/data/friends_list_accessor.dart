import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
class FriendsListAccessor {
  FriendsListAccessor._();

  static Future<FriendsList> getFriendsList() async {
    final response = await RequestsUtil.getWithToken("/friends/getFriendsList");

    if (response.statusCode == 200) {
      return FriendsList.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get friends list: error code ${response.statusCode}');
    }
  }

  static Future<void> removeFriend(String username) async {
    final body = {"username": username};
    final response = await RequestsUtil.postWithToken("/friends/removeFriend", body);

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to remove friend: error message ${response.body}');
    }
  }
}

class FriendsList {
  final String username;
  final List<String> friends;

  const FriendsList({required this.username, required this.friends});

  static List<String> _parseUsernameList(List<dynamic> list) {
    return List<String>.from(list);
  }

  factory FriendsList.fromJson(Map<String, dynamic> jsonInit) {
    return switch (jsonInit) {
      {
      "username": String username,
      "friends": List<dynamic> friends,
      } => FriendsList(
        // username: username,
        username: username,
        friends: _parseUsernameList(friends)
      ),
      _ => throw const FormatException("failed to load FriendsList"),
    };
  }

  @override
  String toString() {
    return 'FriendsList{username: $username, friends: $friends}';
  }
}
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

  /// Use username = null to reset best friend.
  static Future<void> setBestFriend(String? username) async {
    final Map<String, dynamic> body = {};
    if (username != null) body["username"] = username;
    final response = await RequestsUtil.postWithToken("/friends/setBestFriend", body);

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to set best friend: error message ${response.body}');
    }
  }
}

class FriendsList {
  final String username;
  final List<String> friends;
  final String? bestFriend;

  const FriendsList({required this.username, required this.friends, this.bestFriend});

  factory FriendsList.fromJson(Map<String, dynamic> jsonInit) {
    final username = jsonInit['username'] as String;
    final raw = jsonInit['friends'] as List<dynamic>;
    final friends = raw.map((e) => e as String).toList();
    if (jsonInit["bestFriend"] != null) {
      final bestFriend = jsonInit['bestFriend'] as String;
      return FriendsList(username: username, friends: friends, bestFriend: bestFriend);
    }

    return FriendsList(username: username, friends: friends);
  }

  @override
  String toString() {
    return 'FriendsList{username: $username, friends: $friends}';
  }
}
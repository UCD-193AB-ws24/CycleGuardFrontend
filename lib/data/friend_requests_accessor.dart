import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
class FriendRequestsListAccessor {
  FriendRequestsListAccessor._();

  static Future<FriendRequestList> getFriendRequestList() async {
    final response = await RequestsUtil.getWithToken("/friends/getFriendRequestList");

    if (response.statusCode == 200) {
      return FriendRequestList.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get friends list');
    }
  }

  static Future<void> sendFriendRequest(String username) async {
    final body = {"username": username};
    final response = await RequestsUtil.postWithToken("/friends/sendFriendRequest", body);

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to send friend request: error message ${response.body}');
    }
  }

  static Future<void> cancelFriendRequest(String username) async {
    final body = {"username": username};
    final response = await RequestsUtil.postWithToken("/friends/cancelFriendRequest", body);

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to cancel friend request: error message ${response.body}');
    }
  }

  static Future<void> acceptFriendRequest(String username) async {
    final body = {"username": username};
    final response = await RequestsUtil.postWithToken("/friends/acceptFriendRequest", body);

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to accept friend request: error message ${response.body}');
    }
  }

  static Future<void> rejectFriendRequest(String username) async {
    final body = {"username": username};
    final response = await RequestsUtil.postWithToken("/friends/rejectFriendRequest", body);

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to reject friend request: error message ${response.body}');
    }
  }
}

class FriendRequestList {
  final String username;
  final List<String> receivedFriendRequests, pendingFriendRequests;

  const FriendRequestList({required this.username, required this.receivedFriendRequests, required this.pendingFriendRequests});

  static List<String> _parseUsernameList(List<dynamic> list) {
    return List<String>.from(list);
  }

  factory FriendRequestList.fromJson(Map<String, dynamic> jsonInit) {
    return switch (jsonInit) {
      {
      "username": String username,
      "receivedFriendRequests": List<dynamic> receivedFriendRequests,
      "pendingFriendRequests": List<dynamic> pendingFriendRequests,
      } => FriendRequestList(
        // username: username,
        username: username,
        receivedFriendRequests: _parseUsernameList(receivedFriendRequests),
        pendingFriendRequests: _parseUsernameList(pendingFriendRequests),
      ),
      _ => throw const FormatException("failed to load FriendRequestList"),
    };
  }

  @override
  String toString() {
    return 'FriendRequestList{username: $username, receivedFriendRequests: $receivedFriendRequests, pendingFriendRequests: $pendingFriendRequests}';
  }
}
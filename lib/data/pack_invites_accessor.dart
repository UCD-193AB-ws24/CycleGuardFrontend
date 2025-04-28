import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
class PackInvitesAccessor {
  PackInvitesAccessor._();

  // Returns a PackInvites object, which contains a list of packs you've been invited to
  // The list contains the names of the packs you've been invited to
  static Future<PackInvites> getInvites() async {
    final response = await RequestsUtil.getWithToken("/packs/getInvites");

    if (response.statusCode == 200) {
      return PackInvites.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get pack invites: response code ${response.statusCode}');
    }
  }

  // Send an invite to join your current pack to another user
  // If the other user doesn't exist or you're not in a pack, it errors
  static Future<bool> sendInvite(String userToInvite) async {
    final body = {
      "username":userToInvite
    };

    final response = await RequestsUtil.postWithToken("/packs/sendInvite", body);
    if (response.statusCode != 200) {
      throw "Error in sendInvite: response code ${response.statusCode}";
    }
    return response.statusCode==200;
  }

  // Cancels a previously-sent invite to that user to join your current pack
  // Once this is sent, that user no longer is invited to join the pack
  // That user is still able to join normally if they know the password
  static Future<bool> cancelInvite(String userToCancel) async {
    final body = {
      "username":userToCancel
    };

    final response = await RequestsUtil.postWithToken("/packs/cancelInvite", body);
    if (response.statusCode != 200) {
      throw "Error in cancelInvite: response code ${response.statusCode}";
    }
    return response.statusCode==200;
  }

  // Accept an invite to join a pack
  // packToJoin must be present within the user's PackInvites.invites list
  // Errors if user is already in a pack
  static Future<bool> acceptInvite(String packToJoin) async {
    final body = {
      "packName":packToJoin
    };

    final response = await RequestsUtil.postWithToken("/packs/acceptInvite", body);
    if (response.statusCode != 200) {
      throw "Error in acceptInvite: response code ${response.statusCode}";
    }
    return response.statusCode==200;
  }

  // Decline an invite to join a pack
  // packToDecline must be present within the user's PackInvites.invites list
  static Future<bool> declineInvite(String packToDecline) async {
    final body = {
      "packName":packToDecline
    };

    final response = await RequestsUtil.postWithToken("/packs/declineInvite", body);
    if (response.statusCode != 200) {
      throw "Error in declineInvite: response code ${response.statusCode}";
    }
    return response.statusCode==200;
  }
}

class PackInvites {
  final String username;
  final List<String> invites;

  PackInvites({
    required this.username,
    required this.invites
  });

  static List<String> _parsePacksList(List<dynamic> list) {
    return list.map((name) => name.toString()).toList();
  }

  factory PackInvites.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      "username": String username,
      "invites": List<dynamic> invites
      } => PackInvites(
        username: username,
        invites: _parsePacksList(invites)
      ),
      _ => throw const FormatException("failed to load PackInvites"),
    };
  }

  @override
  String toString() {
    return 'PackInvites{username: $username, invites: $invites}';
  }
}
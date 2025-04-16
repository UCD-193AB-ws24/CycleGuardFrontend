import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
class PacksAccessor {
  static final String GOAL_DISTANCE = "distance", GOAL_TIME = "time";
  static final String NO_NEW_OWNER = "";
  PacksAccessor._();

  static Future<PackData?> getPackData() async {
    final response = await RequestsUtil.getWithToken("/packs/getPack");

    // No pack found
    if (response.statusCode == 404) return null;

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return null;
      return PackData.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get pack data: response code ${response.statusCode}');
    }
  }

  static Future<bool> createPack(String packName, String password) async {
    final body = {
      "packName":packName,
      "password":password
    };

    print(body);

    final response = await RequestsUtil.postWithToken("/packs/createPack", body);
    if (response.statusCode != 200) {
      throw "Error in createPack: response code ${response.statusCode}";
    }
    return response.statusCode==200;
  }

  static Future<bool> joinPack(String packName, String password) async {
    final body = {
      "packName":packName,
      "password":password
    };

    final response = await RequestsUtil.postWithToken("/packs/joinPack", body);
    if (response.statusCode != 200) {
      throw "Error in joinPack: response code ${response.statusCode}";
    }
    return response.statusCode==200;
  }

  static Future<bool> leavePack() async {
    final response = await RequestsUtil.postWithToken("/packs/leavePack", RequestsUtil.noParams);
    if (response.statusCode != 200) {
      throw "Error in leavePack: response code ${response.statusCode}";
    }
    return response.statusCode==200;
  }

  static Future<bool> leavePackAsOwner(String newOwner) async {
    final body = {
      "newOwner": newOwner
    };
    final response = await RequestsUtil.postWithToken("/packs/leavePackAsOwner", body);
    if (response.statusCode != 200) {
      throw "Error in leavePackAsOwner: response code ${response.statusCode}";
    }
    return response.statusCode==200;
  }

  static Future<bool> setPackGoal(int durationSeconds, String goalField, int goalAmount) async {
    final body = {
      "durationSeconds": durationSeconds,
      "goalField": goalField,
      "goalAmount": goalAmount,
    };
    final response = await RequestsUtil.postWithToken("/packs/setPackGoal", body);
    if (response.statusCode != 200) {
      throw "Error in setPackGoal: response code ${response.statusCode}";
    }
    return response.statusCode==200;
  }

  static Future<bool> cancelPackGoal() async {
    final response = await RequestsUtil.postWithToken("/packs/cancelGoal", RequestsUtil.noParams);
    if (response.statusCode != 200) {
      throw "Error in cancelPackGoal: response code ${response.statusCode}";
    }
    return response.statusCode==200;
  }
}

class PackData {
  final String name, owner;
  final List<String> memberList;
  final int memberCount;
  final PackGoal packGoal;

  PackData({
    required this.name,
    required this.owner,
    required this.memberList,
    required this.memberCount,
    required this.packGoal
  });

  static List<String> _parseMemberList(List<dynamic> list) {
    return list.map((name) => name.toString()).toList();
  }

  factory PackData.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      "name": String name,
      "owner": String owner,
      "memberList": List<dynamic> memberList,
      "packGoal": Map<String, dynamic> packGoal,
      "memberCount": int memberCount
      } => PackData(
        name: name,
        owner: owner,
        memberList: _parseMemberList(memberList),
        packGoal: PackGoal.fromJson(packGoal),
        memberCount: memberCount
      ),
      _ => throw const FormatException("failed to load PackData"),
    };
  }

  @override
  String toString() {
    return 'PackData{name: $name, owner: $owner, memberList: $memberList, memberCount: $memberCount, packGoal: $packGoal}';
  }
}

class PackGoal {
  final Map<String, double> contributionMap;
  final bool active;
  final String goalField;
  final int startTime, endTime, goalAmount;
  final double totalContribution;

  PackGoal({
    required this.contributionMap,
    required this.active,
    required this.goalField,
    required this.startTime,
    required this.endTime,
    required this.goalAmount,
    required this.totalContribution
  });

  factory PackGoal.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      "contributionMap": Map<String, dynamic> contributionMap,
      "active": bool active,
      "goalField": String goalField,
      "startTime": int startTime,
      "endTime": int endTime,
      "goalAmount": int goalAmount,
      "totalContribution": double totalContribution
      } => PackGoal(
          contributionMap: _parseContributionMap(contributionMap),
        active: active,
        goalField: goalField,
        startTime: startTime,
        endTime: endTime,
        goalAmount: goalAmount,
        totalContribution: totalContribution
      ),
      _ => throw const FormatException("failed to load PackGoal"),
    };
  }


  static MapEntry<String, double> _convert(String username, dynamic value) {
    return MapEntry(username, double.parse(value));
  }

  static Map<String, double> _parseContributionMap(Map<String, dynamic> map) {
    return map.map(_convert);
  }

  @override
  String toString() {
    return 'PackGoal{contributionMap: $contributionMap, active: $active, goalField: $goalField, startTime: $startTime, endTime: $endTime, goalAmount: $goalAmount, totalContribution: $totalContribution}';
  }
}
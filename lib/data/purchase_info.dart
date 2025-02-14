import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
class PurchaseInfo {
  PurchaseInfo._();

  static Future<int> getCycleCoins() async {
    final response = await RequestsUtil.getWithToken("/purchaseInfo/getCycleCoins");

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('Failed to load purchase info');
    }
  }

  static Future<int> addCycleCoins() async {
    final response = await RequestsUtil.postWithToken("/purchaseInfo/addCycleCoins", {"coins": "10"});

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('Failed to load purchase info');
    }
  }


  // Note: for now, getPurchaseInfo and PurchaseInfoEntry and unused
  static Future<PurchaseInfoEntry> _getPurchaseInfo() async {
    final response = await RequestsUtil.getWithToken("/purchaseInfo/get");

    if (response.statusCode == 200) {
      return PurchaseInfoEntry.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load purchase info');
    }
  }
}

class PurchaseInfoEntry {
  final int cycleCoins;
  final List<String> themesOwned;

  const PurchaseInfoEntry({required this.cycleCoins, required this.themesOwned});

  factory PurchaseInfoEntry.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'cycleCoins': int cycleCoins, 'itemsOwned': List<String> themesOwned} => PurchaseInfoEntry(
        cycleCoins: cycleCoins,
        themesOwned: themesOwned,
      ),
      _ => throw const FormatException('Failed to load purchase info.'),
    };
  }
}
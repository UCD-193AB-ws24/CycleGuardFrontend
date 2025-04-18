import 'dart:convert';

import 'package:cycle_guard_app/auth/requests_util.dart';
class CycleCoinInfo {
  CycleCoinInfo._();

  static Future<int> getCycleCoins() async {
    final response = await RequestsUtil.getWithToken("/purchaseInfo/getCycleCoins");

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('Failed to get CycleCoins');
    }
  }

  static Future<int> addCycleCoins(int coins) async {
    final response = await RequestsUtil.postWithToken("/purchaseInfo/addCycleCoins", {"coins": "$coins"});

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('Failed to update CycleCoins');
    }
  }
}

class PurchaseInfo {
  final List<String> themesOwned, miscOwned, iconsOwned;

  const PurchaseInfo({
    required this.themesOwned,
    required this.miscOwned,
    required this.iconsOwned
  });

  static List<String> _parseStringList(List<dynamic> list) {
    return List<String>.from(List<String>.from(list).map((e) => e.toString()));
  }

  factory PurchaseInfo.fromJson(Map<String, dynamic> jsonInit) {
    return switch (jsonInit) {
      {
      "themesOwned": List<dynamic> themesOwned,
      "miscOwned": List<dynamic> miscOwned,
      "iconsOwned": List<dynamic> iconsOwned,
      } => PurchaseInfo(
        // username: username,
          themesOwned: _parseStringList(themesOwned),
          miscOwned: _parseStringList(miscOwned),
          iconsOwned: _parseStringList(iconsOwned)
      ),
      _ => throw const FormatException("failed to load Coordinates"),
    };
  }

  @override
  String toString() {
    return 'PurchaseInfo{themesOwned: $themesOwned, miscOwned: $miscOwned, iconsOwned: $iconsOwned}';
  }
}

enum BuyResponse {
  success,
  unauthorized,
  alreadyOwned,
  notEnoughCoins,
  serverError
}



class PurchaseInfoAccessor {
  static Future<PurchaseInfo> getPurchaseInfo() async {
    final response = await RequestsUtil.getWithToken("/purchaseInfo/getPurchaseInfo");

    if (response.statusCode == 200) {
      return PurchaseInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get purchase info');
    }
  }

  static Future<BuyResponse> buyTheme(String theme) async {
    final response = await RequestsUtil.postWithToken("/purchaseInfo/buyTheme", {"item": theme});

    switch (response.statusCode) {
      case 200: return BuyResponse.success;
      case 401: return BuyResponse.unauthorized;
      case 409: return BuyResponse.notEnoughCoins;
      default: return BuyResponse.serverError;
    }
  }

  static Future<BuyResponse> buyMisc(String misc) async {
    final response = await RequestsUtil.postWithToken("/purchaseInfo/buyMisc", {"item": misc});

    switch (response.statusCode) {
      case 200: return BuyResponse.success;
      case 401: return BuyResponse.unauthorized;
      case 409: return BuyResponse.notEnoughCoins;
      default: return BuyResponse.serverError;
    }
  }

  static Future<BuyResponse> buyIcon(String icon) async {
    final response = await RequestsUtil.postWithToken("/purchaseInfo/buyIcon", {"item": icon});

    switch (response.statusCode) {
      case 200: return BuyResponse.success;
      case 401: return BuyResponse.unauthorized;
      case 409: return BuyResponse.notEnoughCoins;
      default: return BuyResponse.serverError;
    }
  }
}
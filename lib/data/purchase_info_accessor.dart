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
  PurchaseInfo._();

  static Future<List<String>> getOwnedItems() async {
    final response = await RequestsUtil.getWithToken("/purchaseInfo/ownedItems");

    if (response.statusCode == 200) {
      // print(json.decode(response.body));
      return List<String>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to get owned items');
    }
  }

  static Future<BuyResponse> buyItem(String item) async {
    final response = await RequestsUtil.postWithToken("/purchaseInfo/buy", {"item": item});

    switch (response.statusCode) {
      case 200: return BuyResponse.success;
      case 401: return BuyResponse.unauthorized;
      case 409: 
        if (response.body == "ALREADY OWNED") {
          return item == "Rocket Boost" ? BuyResponse.success : BuyResponse.alreadyOwned;
        }
        return BuyResponse.notEnoughCoins;
        //return response.body == "ALREADY OWNED"?BuyResponse.alreadyOwned : BuyResponse.notEnoughCoins;
      default: return BuyResponse.serverError;
    }
  }
}

enum BuyResponse {
  success,
  unauthorized,
  alreadyOwned,
  notEnoughCoins,
  serverError
}
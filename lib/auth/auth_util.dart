import 'dart:convert';
import 'package:cycle_guard_app/auth/requests_util.dart';
import 'package:http/http.dart' as http;

enum CreateAccountStatus {
  duplicateUsername,
  negativeHeight,
  negativeWeight,
  negativeAge,
  serverError,
  success
}

class AuthUtil {
  AuthUtil._();

  static String _token = "";
  static String _username = "";

  static get username {
    return _username;
  }

  static get token {
    return _token;
  }

  static bool isLoggedIn() {
    return _token.isNotEmpty;
  }

  static Future<CreateAccountStatus> login(String username, String password) async {
    print("In AuthUtil.login");
    print(username);
    print(password);
    if (isLoggedIn()) {
      throw "Already logged in!";
    }
    
    final body = {
      "username": username,
      "password": password
    };

    final response = await RequestsUtil.postWithoutToken("/account/login", body);

    final newToken = response.body;
    print("Got response from server: $newToken");

    if (newToken.length != 16) {
      if (newToken == "DUPLICATE") return CreateAccountStatus.duplicateUsername;
      print("Login failed!");
      return CreateAccountStatus.serverError;
    }

    _token = newToken;
    _username = username;

    return CreateAccountStatus.success;
  }

  static Future<bool> createAccount(String username, String password) async {
    print("In AuthUtil.createAccount");
    print(username);
    print(password);
    if (isLoggedIn()) {
      throw "Already logged in!";
    }

    final body = {
      "username": username,
      "password": password
    };

    final response = await RequestsUtil.postWithoutToken("/account/create", body);

    final newToken = response.body;
    print("Got response from server: $newToken");

    if (newToken.length != 16) {
      print("Create account failed!");
      return false;
    }

    _token = newToken;
    _username = username;

    return true;
  }

  static void logout() {

  }
}
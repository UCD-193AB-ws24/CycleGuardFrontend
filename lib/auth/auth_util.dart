import 'dart:convert';
import 'package:cycle_guard_app/auth/requests_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

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

  static Future<bool?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('authToken') && prefs.containsKey('username')) {
      _token = prefs.getString('authToken')!;
      _username = prefs.getString('username')!;
      return true;
    }
    return false;
  }

  static Future<void> _setToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', _token);
    await prefs.setString('username', _username);
  }

  static String _token = "";
  static String _username = "";

  static get username {
    return _username;
  }

  static get token {
    return _token;
  }

  static bool isLoggedIn() {
    return _token.isNotEmpty && _username.isNotEmpty;
  }

  static Future<CreateAccountStatus> login(String username, String password) async {
    print("In AuthUtil.login");
    print(username);
    print(password);
    // if (isLoggedIn()) {
    //   throw "Already logged in!";
    // }
    
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

    await _setToken();

    return CreateAccountStatus.success;
  }

  static Future<bool> createAccount(String username, String password) async {
    print("In AuthUtil.createAccount");
    print(username);
    print(password);
    // if (isLoggedIn()) {
    //   throw "Already logged in!";
    // }

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

  static Future<void> _clearPersistentToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('username');
  }

  static Future<void> logout(BuildContext context) async {
    await _clearPersistentToken();
    _token="";
    _username="";

    selectedIndexGlobal.value=1;

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => OnBoardStart()), (route) => false);
    } else {
      print("Failed to logout");
    }
  }
}
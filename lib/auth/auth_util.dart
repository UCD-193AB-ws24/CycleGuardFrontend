import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthUtil {
  AuthUtil._();

  static String _token = "";
  static String _username = "";

  static get username {
    return _username;
  }

  static bool isLoggedIn() {
    return _token.isNotEmpty;
  }

  static Future<bool> login(String username, String password) async {
    print("In AuthUtil.login");
    print(username);
    print(password);
    if (isLoggedIn()) {
      throw "Already logged in!";
    }
    
    final requestBody = {
      "username": username,
      "password": password
    };
    
    print(requestBody);
    print(jsonEncode(requestBody));

    final uri = Uri(
      scheme: "https",
      host: "cycleguardbackend-638241752910.us-central1.run.app",
      path: "/login",
    );

    print(uri);
    final response = await http.post(uri, body: jsonEncode(requestBody), headers: {'Content-Type':'application/json'});

    final newToken = response.body;
    print("Got response from server: $newToken");

    if (newToken.length != 16) {
      print("Login failed!");
      return false;
    }

    _token = newToken;
    _username = username;

    return true;
  }

  static Future<bool> createAccount(String username, String password) async {
    print("In AuthUtil.createAccount");
    print(username);
    print(password);
    if (isLoggedIn()) {
      throw "Already logged in!";
    }

    final requestBody = {
      "username": username,
      "password": password
    };

    print(requestBody);
    print(jsonEncode(requestBody));

    final uri = Uri(
      scheme: "https",
      host: "cycleguardbackend-638241752910.us-central1.run.app",
      path: "/account/create",
    );

    print(uri);
    final response = await http.post(uri, body: jsonEncode(requestBody), headers: {'Content-Type':'application/json'});

    final newToken = response.body;
    print("Got response from server: $newToken");

    if (newToken.length != 16) {
      print("Login failed!");
      return false;
    }

    _token = newToken;
    _username = username;

    return true;
  }

  static void logout() {

  }
}
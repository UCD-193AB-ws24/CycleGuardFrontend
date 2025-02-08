import 'dart:convert';
import 'dart:ffi';
import 'package:http/http.dart' as http;

class AuthUtil {
  AuthUtil._();

  static String _token = "";

  static bool isLoggedIn() {
    return _token.isNotEmpty;
  }

  static Future<bool> login(String username, String password) async {
    print("In AuthUtil.login");
    print(username);
    print(password);
    if (isLoggedIn()) {
      print("Already logged in!");
      // TODO throw error if already logged in
    }
    
    final requestBody = {
      "username": username,
      "password": password
    };
    
    print(requestBody);
    print(jsonEncode(requestBody));

    final uri = Uri(
      scheme: "https",
      host: "immortal-hot-cat.ngrok-free.app",
      path: "/login",
    );

    print(uri);
    final future = http.post(uri, body: jsonEncode(requestBody), headers: {'Content-Type':'application/json'});
    // String response;
    future.then((res) {
      String response = res.body;
      print(response);
    });

    return true;
  }
}
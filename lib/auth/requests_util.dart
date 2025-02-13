import 'dart:convert';
import 'package:cycle_guard_app/auth/auth_util.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class RequestsUtil {
  RequestsUtil._();

  static final _host = "cycleguardbackend-638241752910.us-central1.run.app";
  static final _scheme = "https";

  static Future<Object> postWithToken(String endpoint, Map<String, String> body, String token) async {
    return await _post(endpoint, body, true, token);
  }

  static Future<Object> postWithoutToken(String endpoint, Map<String, String> body) async {
    return await _post(endpoint, body, false, "");
  }

  static Future<Object> getWithToken(String endpoint, String token) async {
    return await _get(endpoint, true, token);
  }

  static Future<Object> getWithoutToken(String endpoint) async {
    return await _get(endpoint, false, "");
  }

  

  static Uri _getUri(String endpoint) {
    return Uri(
      scheme: _scheme,
      host: _host,
      path: endpoint,
    );
  }

  static Map<String, String> _getHeaders(bool useToken, String token) {
    Map<String, String> headers = {'Content-Type':'application/json'};
    if (useToken) headers.addIf(useToken, "Authorization", token);

    return headers;
  }

  static Future<Object> _post(String endpoint, Map<String, String> body, bool useToken, String token) async {
    return await http.post(_getUri(endpoint), body: jsonEncode(body), headers: _getHeaders(useToken, token));
  }

  static Future<Object> _get(String endpoint, bool useToken, String token) async {
    return await http.get(_getUri(endpoint), headers: _getHeaders(useToken, token));
  }
}
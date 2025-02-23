import 'dart:convert';
import 'package:cycle_guard_app/auth/auth_util.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class RequestsUtil {
  RequestsUtil._();

  // static final _host = "cycleguardbackend-638241752910.us-central1.run.app";
  static final _host = "immortal-hot-cat.ngrok-free.app";
  static final _scheme = "https";

  static Future<http.Response> postWithToken(String endpoint, Map<String, String> body) async {
    return await _post(endpoint, body, true);
  }

  static Future<http.Response> postWithoutToken(String endpoint, Map<String, String> body) async {
    return await _post(endpoint, body, false);
  }

  static Future<http.Response> getWithToken(String endpoint) async {
    return await _get(endpoint, true);
  }

  static Future<http.Response> getWithoutToken(String endpoint) async {
    return await _get(endpoint, false);
  }



  static Uri _getUri(String endpoint) {
    return Uri(
      scheme: _scheme,
      host: _host,
      path: endpoint,
    );
  }

  static Map<String, String> _getHeaders(bool useToken) {
    Map<String, String> headers = {'Content-Type':'application/json'};
    if (useToken) headers.addIf(useToken, "Token", AuthUtil.token);

    return headers;
  }

  static Future<http.Response> _post(String endpoint, Map<String, String> body, bool useToken) async {
    return await http.post(_getUri(endpoint), body: jsonEncode(body), headers: _getHeaders(useToken));
  }

  static Future<http.Response> _get(String endpoint, bool useToken) async {
    return await http.get(_getUri(endpoint), headers: _getHeaders(useToken));
  }
}
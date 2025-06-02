import 'package:mockito/mockito.dart';
import 'package:cycle_guard_app/auth/requests_util.dart';
import 'package:http/http.dart' as http;

// Create a mock class for RequestsUtil
class MockRequestsUtil extends Mock implements RequestsUtil {
  Future<http.Response> postWithToken(String endpoint, Map<String, dynamic> body) {
    return super.noSuchMethod(
      Invocation.method(#postWithToken, [endpoint, body]),
      returnValue: Future.value(http.Response('', 200)),
      returnValueForMissingStub: Future.value(http.Response('', 200)),
    );
  }
  @override
  Future<http.Response> getWithToken(String endpoint) {
    return super.noSuchMethod(
      Invocation.method(#getWithToken, [endpoint]),
      returnValue: Future.value(http.Response('', 200)),
      returnValueForMissingStub: Future.value(http.Response('', 200)),
    );
  }


}

// Create a mock class for http.Response
class MockHttpResponse extends Mock implements http.Response {}
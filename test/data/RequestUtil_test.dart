import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cycle_guard_app/auth/requests_util.dart';
import 'package:http/http.dart' as http;
import '../Mock/Mock_RequestUtil.dart';

void main() {
  group('RequestsUtil Tests', () {
    late MockRequestsUtil mockRequestsUtil;
    late MockHttpResponse mockHttpResponse;

    setUp(() {
      mockRequestsUtil = MockRequestsUtil();
      mockHttpResponse = MockHttpResponse();
    });

    test('postWithToken should call _post with correct parameters', () async {
      const endpoint = '/test-endpoint';
      final body = {'key': 'value'};
      when(mockRequestsUtil.postWithToken(endpoint, body))
          .thenAnswer((_) async => mockHttpResponse);

      final response = await mockRequestsUtil.postWithToken(endpoint, body);

      verify(mockRequestsUtil.postWithToken(endpoint, body)).called(1);
      expect(response, mockHttpResponse);
    });

    test('getWithToken should call _get with correct parameters', () async {
      const endpoint = '/test-endpoint';
      when(mockRequestsUtil.getWithToken(endpoint))
          .thenAnswer((_) async => mockHttpResponse);

      final response = await mockRequestsUtil.getWithToken(endpoint);

      verify(mockRequestsUtil.getWithToken(endpoint)).called(1);
      expect(response, mockHttpResponse);
    });
  });
}
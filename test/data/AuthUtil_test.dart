import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cycle_guard_app/auth/auth_util.dart';
import '../Mock/Mock_Auth.dart';


void main() {
  group('AuthUtil Tests', () {
    late MockAuthUtil mockAuthUtil;

    setUp(() {
      mockAuthUtil = MockAuthUtil();
    });

    test('Mock login method', () async {
      when(mockAuthUtil.login('testUser', 'testPassword'))
          .thenAnswer((_) async => CreateAccountStatus.success);

      final result = await mockAuthUtil.login('testUser', 'testPassword');

      expect(result, CreateAccountStatus.success);
      verify(mockAuthUtil.login('testUser', 'testPassword')).called(1);
    });

    test('Mock isLoggedIn method', () {
      when(mockAuthUtil.isLoggedIn()).thenReturn(true);

      final result = mockAuthUtil.isLoggedIn();

      expect(result, true);
      verify(mockAuthUtil.isLoggedIn()).called(1);
    });

    test('Mock logout method', () async {
      when(mockAuthUtil.logout()).thenAnswer((_) async => true);

      await mockAuthUtil.logout();
      verify(mockAuthUtil.logout()).called(1);
    });

  //
  });
}
import 'package:mockito/mockito.dart';
import 'package:cycle_guard_app/auth/auth_util.dart';

class MockAuthUtil extends Mock implements AuthUtil {
  @override
  Future<CreateAccountStatus> login(String username, String password) async {
    return super.noSuchMethod(Invocation.method(#login, [username, password]),
        returnValue: Future.value(CreateAccountStatus.success));
  }

  @override
  bool isLoggedIn() {
    return super.noSuchMethod(Invocation.method(#isLoggedIn, []),
        returnValue: true);
  }

  @override
  Future<void> logout() async {
    return super.noSuchMethod(Invocation.method(#logout, []),
        returnValue: true);
  }


}
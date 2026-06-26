import '../modeles/modeles_faculte.dart';
import 'service_session.dart';

abstract class AuthService {
  Future<FacultyUser> login({
    required String identifier,
    required String password,
    required UserRole role,
  });

  Future<void> logout();
}

class MockAuthService implements AuthService {
  const MockAuthService();

  @override
  Future<FacultyUser> login({
    required String identifier,
    required String password,
    required UserRole role,
  }) async {
    SessionService.connectAs(role);
    return SessionService.currentUser;
  }

  @override
  Future<void> logout() async {
    SessionService.connectAs(UserRole.administrator);
  }
}

class AuthDataSource {
  static AuthService service = const MockAuthService();
}

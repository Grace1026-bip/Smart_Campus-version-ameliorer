import '../donnees_fictives/donnees_faculte_fictives.dart';
import '../modeles/modeles_faculte.dart';

class SessionService {
  static UserRole currentRole = UserRole.administrator;
  static FacultyUser? _currentUser;

  static FacultyUser get currentUser =>
      _currentUser ??
      MockFacultyData.users[currentRole] ??
      MockFacultyData.users[UserRole.administrator]!;

  static void connectAs(UserRole role) {
    currentRole = role;
    _currentUser = MockFacultyData.users[role];
  }

  static void connectWithUser(FacultyUser user) {
    currentRole = user.role;
    _currentUser = user;
  }

  static void clear() {
    currentRole = UserRole.administrator;
    _currentUser = null;
  }
}

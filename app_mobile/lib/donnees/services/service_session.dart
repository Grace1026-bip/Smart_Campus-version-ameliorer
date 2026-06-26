import '../donnees_fictives/donnees_faculte_fictives.dart';
import '../modeles/modeles_faculte.dart';

class SessionService {
  static UserRole currentRole = UserRole.administrator;

  static FacultyUser get currentUser =>
      MockFacultyData.users[currentRole] ??
      MockFacultyData.users[UserRole.administrator]!;

  static void connectAs(UserRole role) {
    currentRole = role;
  }
}

import '../mock/mock_faculty_data.dart';
import '../models/faculty_models.dart';

class SessionService {
  static UserRole currentRole = UserRole.administrator;

  static FacultyUser get currentUser =>
      MockFacultyData.users[currentRole] ??
      MockFacultyData.users[UserRole.administrator]!;

  static void connectAs(UserRole role) {
    currentRole = role;
  }
}

import '../modeles/modeles_faculte.dart';
import 'service_api.dart';

class SessionService {
  static FacultyUser? _currentUser;

  static bool get isAuthenticated => _currentUser != null;
  static UserRole get currentRole => _currentUser?.role ?? UserRole.student;

  static FacultyUser get currentUser =>
      _currentUser ??
      FacultyUser(
        name: 'Utilisateur Smart Faculty',
        email: '',
        role: currentRole,
        department: currentRole.workspaceLabel,
        avatarText: 'SF',
        matricule: '',
        promotion: '',
        phone: '',
        location: 'Campus',
      );

  static void connectWithUser(FacultyUser user) {
    _currentUser = user;
  }

  static Future<void> clear() async {
    _currentUser = null;
    await ApiDataSource.client.viderSession();
  }
}

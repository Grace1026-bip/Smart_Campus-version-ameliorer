import '../modeles/modeles_faculte.dart';
import 'service_api.dart';

class SessionService {
  static UserRole currentRole = UserRole.administrator;
  static FacultyUser? _currentUser;

  static bool get isAuthenticated => _currentUser != null;

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

  static void connectAs(UserRole role) {
    currentRole = role;
    _currentUser = FacultyUser(
      name: role.label,
      email: '',
      role: role,
      department: role.workspaceLabel,
      avatarText: _avatar(role.label),
      matricule: '',
      promotion: '',
      phone: '',
      location: 'Campus',
    );
  }

  static void connectWithUser(FacultyUser user) {
    currentRole = user.role;
    _currentUser = user;
  }

  static void clear() {
    currentRole = UserRole.administrator;
    _currentUser = null;
    ApiDataSource.client.viderSession();
  }

  static String _avatar(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'SF';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

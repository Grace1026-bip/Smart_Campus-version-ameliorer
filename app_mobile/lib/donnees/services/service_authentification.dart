import '../modeles/modeles_faculte.dart';
import 'service_api.dart';
import 'service_session.dart';

abstract class AuthService {
  Future<FacultyUser> login({
    required String identifier,
    required String password,
    required UserRole role,
  });

  Future<void> logout();
}

class ApiAuthService implements AuthService {
  const ApiAuthService();

  @override
  Future<FacultyUser> login({
    required String identifier,
    required String password,
    required UserRole role,
  }) async {
    final data = await ApiDataSource.client.post(
      '/api/connexion',
      body: {
        'email': identifier,
        'mot_de_passe': password,
        'se_souvenir_de_moi': true,
      },
    );

    final userJson = data['utilisateur'] as Map<String, dynamic>;
    final roles = (data['roles'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList();
    final resolvedRole = _roleFromApi(roles, fallback: role);
    final user = _userFromApi(userJson, resolvedRole);

    SessionService.connectWithUser(user);
    return user;
  }

  @override
  Future<void> logout() async {
    try {
      await ApiDataSource.client.post('/api/deconnexion');
    } finally {
      SessionService.clear();
    }
  }

  FacultyUser _userFromApi(Map<String, dynamic> json, UserRole role) {
    final fullName = [
      json['nom'],
      json['postnom'],
      json['prenom'],
    ]
        .where((part) => part != null && part.toString().trim().isNotEmpty)
        .join(' ');

    return FacultyUser(
      name: fullName.isEmpty ? 'Utilisateur Smart Faculty' : fullName,
      email: json['email']?.toString() ?? '',
      role: role,
      department: role == UserRole.student
          ? 'Espace etudiant'
          : role == UserRole.teacher
              ? 'Departement informatique'
              : role.workspaceLabel,
      avatarText: _avatar(fullName),
      matricule: '',
      promotion: '',
      phone: '',
      location: 'Campus',
    );
  }

  String _avatar(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'SF';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  UserRole _roleFromApi(List<String> roles, {required UserRole fallback}) {
    if (roles.contains(_apiRoleFor(fallback))) return fallback;
    if (roles.contains('administrateur')) return UserRole.administrator;
    if (roles.contains('doyen') || roles.contains('vice_doyen')) {
      return UserRole.dean;
    }
    if (roles.contains('appariteur') || roles.contains('paritaire')) {
      return UserRole.apparitor;
    }
    if (roles.contains('chef_promotion') || roles.contains('icp')) {
      return UserRole.promotionChief;
    }
    if (roles.contains('etudiant')) return UserRole.student;
    if (roles.contains('enseignant')) return UserRole.teacher;
    return fallback;
  }

  String _apiRoleFor(UserRole role) {
    switch (role) {
      case UserRole.administrator:
        return 'administrateur';
      case UserRole.apparitor:
        return 'appariteur';
      case UserRole.student:
        return 'etudiant';
      case UserRole.teacher:
        return 'enseignant';
      case UserRole.promotionChief:
        return 'chef_promotion';
      case UserRole.dean:
        return 'doyen';
    }
  }
}

class AuthDataSource {
  static AuthService service = const ApiAuthService();
}

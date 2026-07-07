import '../modeles/modeles_faculte.dart';
import 'service_api.dart';
import 'service_session.dart';

abstract class AuthService {
  Future<FacultyUser> login({
    required String identifier,
    required String password,
    required UserRole role,
  });

  Future<FacultyUser?> restoreSession();

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
      '/auth/connexion',
      body: {
        'email': identifier,
        'mot_de_passe': password,
        'role': _apiRoleFor(role),
        'appareil': 'flutter',
      },
    );

    _configurerJetons(data, role);

    final userJson = data['utilisateur'] as Map<String, dynamic>;
    final roles = _rolesFromUser(userJson);
    final roleActif = data['role_actif']?.toString();
    final resolvedRole = _roleFromApi(
      [
        if (roleActif != null) roleActif,
        ...roles,
      ],
      fallback: role,
    );
    final user = _userFromApi(userJson, resolvedRole);

    SessionService.connectWithUser(user);
    return user;
  }

  @override
  Future<FacultyUser?> restoreSession() async {
    if (!ApiDataSource.client.estConnecte) {
      SessionService.clear();
      return null;
    }

    try {
      final data = await ApiDataSource.client.get('/auth/moi');
      final roles = _rolesFromUser(data);
      final resolvedRole = _roleFromApi(
        [
          if (data['role_actif'] != null) data['role_actif'].toString(),
          ...roles,
        ],
        fallback: _defaultRoleFromApi(roles),
      );
      final user = _userFromApi(data, resolvedRole);

      SessionService.connectWithUser(user);
      return user;
    } catch (_) {
      SessionService.clear();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = ApiDataSource.client.refreshToken;
    try {
      if (refreshToken != null) {
        await ApiDataSource.client.post(
          '/auth/deconnexion',
          body: {'refresh_token': refreshToken},
        );
      }
    } finally {
      SessionService.clear();
    }
  }

  void _configurerJetons(Map<String, dynamic> data, UserRole fallbackRole) {
    final accessToken = data['access_token']?.toString();
    final refreshToken = data['refresh_token']?.toString();
    final roleActif =
        data['role_actif']?.toString() ?? _apiRoleFor(fallbackRole);

    if (accessToken == null || refreshToken == null) {
      throw ApiException('Jetons de connexion absents dans la reponse API.');
    }

    ApiDataSource.client.configurerSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      roleActif: roleActif,
    );
  }

  FacultyUser _userFromApi(Map<String, dynamic> json, UserRole role) {
    final fullName = [
      json['nom'],
      json['postnom'],
      json['prenom'],
    ].where((part) => part != null && part.toString().trim().isNotEmpty).join(
          ' ',
        );

    return FacultyUser(
      name: fullName.isEmpty ? 'Utilisateur Smart Faculty' : fullName,
      email: json['email']?.toString() ?? '',
      role: role,
      department: role.workspaceLabel,
      avatarText: _avatar(fullName),
      matricule: '',
      promotion: '',
      phone: json['telephone']?.toString() ?? '',
      location: 'Campus',
    );
  }

  List<String> _rolesFromUser(Map<String, dynamic> json) {
    return (json['roles'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList();
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

  UserRole _defaultRoleFromApi(List<String> roles) {
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
    if (roles.contains('enseignant')) return UserRole.teacher;
    if (roles.contains('etudiant')) return UserRole.student;
    return UserRole.administrator;
  }
}

class AuthDataSource {
  static AuthService service = const ApiAuthService();
}

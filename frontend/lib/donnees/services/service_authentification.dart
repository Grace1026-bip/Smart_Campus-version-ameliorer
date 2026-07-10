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
        'role': role.apiValue,
        'appareil': 'flutter',
      },
    );

    final userJson = data['utilisateur'] as Map<String, dynamic>;
    final roles = _rolesFromUser(userJson);
    final roleActif = data['role_actif']?.toString();
    if (roleActif == null) {
      throw ApiException('Role actif absent de la reponse API.');
    }
    final resolvedRole = userRoleFromApi(roleActif);
    if (resolvedRole == null || !roles.contains(roleActif)) {
      throw ApiException('Role actif invalide dans la reponse API.');
    }
    _configurerJetons(data, roleActif);
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
      final roleActif = data['role_actif']?.toString();
      if (roleActif == null) {
        throw ApiException('Role actif absent de la reponse API.');
      }
      final resolvedRole = userRoleFromApi(roleActif);
      if (resolvedRole == null || !roles.contains(roleActif)) {
        throw ApiException('Role actif invalide dans la reponse API.');
      }
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

  void _configurerJetons(Map<String, dynamic> data, String roleActif) {
    final accessToken = data['access_token']?.toString();
    final refreshToken = data['refresh_token']?.toString();

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
}

class AuthDataSource {
  static AuthService service = const ApiAuthService();
}

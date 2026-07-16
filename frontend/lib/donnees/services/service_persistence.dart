import 'package:shared_preferences/shared_preferences.dart';

abstract class SessionStorage {
  Future<Map<String, String>?> readSession();

  Future<void> writeSession({
    required String accessToken,
    required String refreshToken,
    required String roleActif,
  });

  Future<void> clearSession();
}

class SharedPreferencesSessionStorage implements SessionStorage {
  SharedPreferencesSessionStorage({
    Future<SharedPreferences> Function()? getPreferences,
  }) : _getPreferences = getPreferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _getPreferences;

  static const accessTokenKey = 'smart_faculty_access_token';
  static const refreshTokenKey = 'smart_faculty_refresh_token';
  static const roleActifKey = 'smart_faculty_role_actif';

  @override
  Future<Map<String, String>?> readSession() async {
    final preferences = await _getPreferences();
    final accessToken = preferences.getString(accessTokenKey);
    final refreshToken = preferences.getString(refreshTokenKey);
    final roleActif = preferences.getString(roleActifKey);

    if (accessToken == null || refreshToken == null || roleActif == null) {
      return null;
    }

    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'role_actif': roleActif,
    };
  }

  @override
  Future<void> writeSession({
    required String accessToken,
    required String refreshToken,
    required String roleActif,
  }) async {
    final preferences = await _getPreferences();
    await preferences.setString(accessTokenKey, accessToken);
    await preferences.setString(refreshTokenKey, refreshToken);
    await preferences.setString(roleActifKey, roleActif);
  }

  @override
  Future<void> clearSession() async {
    final preferences = await _getPreferences();
    await preferences.remove(accessTokenKey);
    await preferences.remove(refreshTokenKey);
    await preferences.remove(roleActifKey);
  }
}

class SessionPersistenceService {
  // Le stockage est resolu a la premiere operation pour eviter tout appel plateforme pendant l import.
  static SessionStorage _storage = SharedPreferencesSessionStorage();

  static void configureStorage(SessionStorage storage) {
    _storage = storage;
  }

  static void resetStorage() {
    _storage = SharedPreferencesSessionStorage();
  }

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String roleActif,
  }) async {
    try {
      await _storage.writeSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        roleActif: roleActif,
      );
    } catch (_) {
      // Une panne du stockage ne doit pas invalider une session API encore valide.
    }
  }

  static Future<Map<String, String>?> restoreSession() async {
    try {
      return await _storage.readSession();
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSession() async {
    try {
      await _storage.clearSession();
    } catch (_) {
      // La deconnexion efface tout de meme la session en memoire si le stockage local est indisponible.
    }
  }
}

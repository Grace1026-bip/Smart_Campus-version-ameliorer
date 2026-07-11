import 'package:shared_preferences/shared_preferences.dart';

class SessionPersistenceService {
  static const _accessTokenKey = 'smart_faculty_access_token';
  static const _refreshTokenKey = 'smart_faculty_refresh_token';
  static const _roleActifKey = 'smart_faculty_role_actif';

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String roleActif,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accessTokenKey, accessToken);
    await preferences.setString(_refreshTokenKey, refreshToken);
    await preferences.setString(_roleActifKey, roleActif);
  }

  static Future<Map<String, String>?> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final accessToken = preferences.getString(_accessTokenKey);
    final refreshToken = preferences.getString(_refreshTokenKey);
    final roleActif = preferences.getString(_roleActifKey);

    if (accessToken == null || refreshToken == null || roleActif == null) {
      return null;
    }

    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'role_actif': roleActif,
    };
  }

  static Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
    await preferences.remove(_roleActifKey);
  }
}

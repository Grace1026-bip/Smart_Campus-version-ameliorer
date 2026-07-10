import 'service_api.dart';

class NotificationsApiService {
  const NotificationsApiService();

  Future<Map<String, dynamic>> lister({
    int page = 1,
    int taille = 20,
    bool? estLue,
    String? typeNotification,
  }) async {
    return ApiDataSource.client.get(
      '/notifications',
      query: {
        'page': page,
        'taille': taille,
        if (estLue != null) 'est_lue': estLue,
        if (typeNotification != null) 'type_notification': typeNotification,
      },
    );
  }

  Future<Map<String, dynamic>> compteurNonLues() async {
    return ApiDataSource.client.get('/notifications/non-lues/compteur');
  }

  Future<Map<String, dynamic>> marquerCommeLue(int notificationId) async {
    final data =
        await ApiDataSource.client.post('/notifications/$notificationId/lire');
    return data['notification'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> toutMarquerCommeLu() async {
    return ApiDataSource.client.post('/notifications/tout-lire');
  }
}

class NotificationsDataSource {
  static const NotificationsApiService service = NotificationsApiService();
}

import 'dart:async';
import 'dart:html' as html;

import 'client_api_reponse.dart';

Future<ReponseHttp> envoyerRequeteHttp({
  required String methode,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
}) async {
  final request = html.HttpRequest();
  final resultat = Completer<ReponseHttp>();
  request
    ..open(methode, uri.toString())
    ..withCredentials = false
    ..timeout = 10000;

  headers.forEach(request.setRequestHeader);
  request.onLoad.listen((_) {
    if (resultat.isCompleted) return;
    resultat.complete(
      ReponseHttp(
        statusCode: request.status ?? 0,
        body: request.responseText ?? '',
        headers: const {},
      ),
    );
  });
  request.onTimeout.listen((_) {
    if (!resultat.isCompleted) {
      resultat.completeError(
        const ErreurTransportHttp(TypeErreurTransport.delaiDepasse),
      );
    }
  });
  request.onError.listen((_) async {
    if (resultat.isCompleted) return;
    final accessible = await _serveurAccessibleSansCors(uri);
    if (resultat.isCompleted) return;
    resultat.completeError(
      ErreurTransportHttp(
        accessible
            ? TypeErreurTransport.cors
            : TypeErreurTransport.serveurInaccessible,
      ),
    );
  });

  request.send(body);
  return resultat.future;
}

Future<bool> _serveurAccessibleSansCors(Uri uri) async {
  final racine = uri.replace(path: '/', query: null, fragment: null);
  try {
    await html.window.fetch(
      racine.toString(),
      {'mode': 'no-cors', 'cache': 'no-store'},
    ).timeout(const Duration(seconds: 3));
    return true;
  } catch (_) {
    return false;
  }
}

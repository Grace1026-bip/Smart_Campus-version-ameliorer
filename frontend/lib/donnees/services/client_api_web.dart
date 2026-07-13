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
    final accessible = await _serveurJoignableSansCors(uri);
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

Future<bool> _serveurJoignableSansCors(Uri uri) async {
  try {
    // A successful no-cors probe only proves that this API origin is reachable.
    // The browser refusal of the original XHR is the separate signal reported.
    await html.window.fetch(
      uri.toString(),
      {'mode': 'no-cors', 'cache': 'no-store'},
    ).timeout(const Duration(seconds: 3));
    return true;
  } catch (_) {
    return false;
  }
}

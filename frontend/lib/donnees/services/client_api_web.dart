import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

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

Future<ReponseOctetsHttp> envoyerRequeteOctetsHttp({
  required String methode,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
}) async {
  final request = html.HttpRequest();
  final resultat = Completer<ReponseOctetsHttp>();
  request
    ..open(methode, uri.toString())
    ..responseType = 'arraybuffer'
    ..withCredentials = false
    ..timeout = 10000;

  headers.forEach(request.setRequestHeader);
  request.onLoad.listen((_) {
    if (resultat.isCompleted) return;
    final response = request.response;
    final bytes = response is ByteBuffer
        ? Uint8List.view(response)
        : Uint8List.fromList(const []);
    resultat.complete(
      ReponseOctetsHttp(
        statusCode: request.status ?? 0,
        bytes: bytes,
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
    // Une sonde no-cors reussie prouve seulement que cette origine est joignable.
    // Le refus du XHR original par le navigateur est le signal rapporte separement.
    await html.window.fetch(
      uri.toString(),
      {'mode': 'no-cors', 'cache': 'no-store'},
    ).timeout(const Duration(seconds: 3));
    return true;
  } catch (_) {
    return false;
  }
}

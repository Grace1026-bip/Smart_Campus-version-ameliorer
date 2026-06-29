import 'client_api_io.dart' if (dart.library.html) 'client_api_web.dart'
    as implementation;
import 'client_api_reponse.dart';

Future<ReponseHttp> envoyerRequeteHttp({
  required String methode,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
}) {
  return implementation.envoyerRequeteHttp(
    methode: methode,
    uri: uri,
    headers: headers,
    body: body,
  );
}

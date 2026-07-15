import 'client_multipart_io.dart'
    if (dart.library.html) 'client_multipart_web.dart' as implementation;
import 'client_api_reponse.dart';
import 'client_multipart_reponse.dart';

Future<ReponseHttp> envoyerRequeteMultipart({
  required String methode,
  required Uri uri,
  required Map<String, String> headers,
  required Map<String, String> fields,
  required List<MultipartPart> parts,
}) {
  return implementation.envoyerRequeteMultipart(
    methode: methode,
    uri: uri,
    headers: headers,
    fields: fields,
    parts: parts,
  );
}

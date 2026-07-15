import 'client_api_reponse.dart';

class MultipartPart {
  const MultipartPart({
    required this.name,
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final String name;
  final List<int> bytes;
  final String filename;
  final String contentType;
}

typedef EnvoyeurMultipartHttp = Future<ReponseHttp> Function({
  required String methode,
  required Uri uri,
  required Map<String, String> headers,
  required Map<String, String> fields,
  required List<MultipartPart> parts,
});

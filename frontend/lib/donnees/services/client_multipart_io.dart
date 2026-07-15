import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'client_api_reponse.dart';
import 'client_multipart_reponse.dart';

Future<ReponseHttp> envoyerRequeteMultipart({
  required String methode,
  required Uri uri,
  required Map<String, String> headers,
  required Map<String, String> fields,
  required List<MultipartPart> parts,
}) async {
  final client = HttpClient();
  final boundary = 'smartfaculty-${Random().nextInt(1 << 32)}';
  try {
    final request = await client.openUrl(methode, uri).timeout(
          const Duration(seconds: 10),
        );
    headers.forEach(request.headers.set);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/form-data; boundary=$boundary',
    );
    for (final entry in fields.entries) {
      request.add(utf8.encode(
          '--$boundary\r\nContent-Disposition: form-data; name="${entry.key}"\r\n\r\n${entry.value}\r\n'));
    }
    for (final part in parts) {
      request.add(utf8.encode(
          '--$boundary\r\nContent-Disposition: form-data; name="${part.name}"; filename="${part.filename}"\r\nContent-Type: ${part.contentType}\r\n\r\n'));
      request.add(part.bytes);
      request.add(utf8.encode('\r\n'));
    }
    request.add(utf8.encode('--$boundary--\r\n'));
    final response = await request.close().timeout(const Duration(seconds: 10));
    final body = await response.transform(utf8.decoder).join();
    return ReponseHttp(
      statusCode: response.statusCode,
      body: body,
      headers: const {},
    );
  } on TimeoutException {
    throw const ErreurTransportHttp(TypeErreurTransport.delaiDepasse);
  } on SocketException {
    throw const ErreurTransportHttp(TypeErreurTransport.serveurInaccessible);
  } finally {
    client.close(force: true);
  }
}

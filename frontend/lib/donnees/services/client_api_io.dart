import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'client_api_reponse.dart';

Future<ReponseHttp> envoyerRequeteHttp({
  required String methode,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
}) async {
  final client = HttpClient();
  try {
    final request =
        await client.openUrl(methode, uri).timeout(const Duration(seconds: 10));
    headers.forEach(request.headers.set);

    if (body != null) {
      request.add(utf8.encode(body));
    }

    final response = await request.close().timeout(const Duration(seconds: 10));
    final content = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 10));
    final responseHeaders = <String, String>{};
    response.headers.forEach((name, values) {
      responseHeaders[name.toLowerCase()] = values.join(',');
    });

    return ReponseHttp(
      statusCode: response.statusCode,
      body: content,
      headers: responseHeaders,
    );
  } on TimeoutException {
    throw const ErreurTransportHttp(TypeErreurTransport.delaiDepasse);
  } on SocketException {
    throw const ErreurTransportHttp(
      TypeErreurTransport.serveurInaccessible,
    );
  } on HttpException {
    throw const ErreurTransportHttp(
      TypeErreurTransport.serveurInaccessible,
    );
  } finally {
    client.close(force: true);
  }
}

Future<ReponseOctetsHttp> envoyerRequeteOctetsHttp({
  required String methode,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
}) async {
  final client = HttpClient();
  try {
    final request =
        await client.openUrl(methode, uri).timeout(const Duration(seconds: 10));
    headers.forEach(request.headers.set);

    if (body != null) {
      request.add(utf8.encode(body));
    }

    final response = await request.close().timeout(const Duration(seconds: 10));
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
    }
    final responseHeaders = <String, String>{};
    response.headers.forEach((name, values) {
      responseHeaders[name.toLowerCase()] = values.join(',');
    });

    return ReponseOctetsHttp(
      statusCode: response.statusCode,
      bytes: bytes,
      headers: responseHeaders,
    );
  } on TimeoutException {
    throw const ErreurTransportHttp(TypeErreurTransport.delaiDepasse);
  } on SocketException {
    throw const ErreurTransportHttp(
      TypeErreurTransport.serveurInaccessible,
    );
  } on HttpException {
    throw const ErreurTransportHttp(
      TypeErreurTransport.serveurInaccessible,
    );
  } finally {
    client.close(force: true);
  }
}

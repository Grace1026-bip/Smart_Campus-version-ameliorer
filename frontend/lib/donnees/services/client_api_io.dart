import 'dart:convert';
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
    final request = await client.openUrl(methode, uri);
    headers.forEach(request.headers.set);

    if (body != null) {
      request.add(utf8.encode(body));
    }

    final response = await request.close();
    final content = await response.transform(utf8.decoder).join();
    final responseHeaders = <String, String>{};
    response.headers.forEach((name, values) {
      responseHeaders[name.toLowerCase()] = values.join(',');
    });

    return ReponseHttp(
      statusCode: response.statusCode,
      body: content,
      headers: responseHeaders,
    );
  } finally {
    client.close(force: true);
  }
}

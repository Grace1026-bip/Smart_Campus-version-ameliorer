import 'dart:html' as html;

import 'client_api_reponse.dart';

Future<ReponseHttp> envoyerRequeteHttp({
  required String methode,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
}) async {
  final request = html.HttpRequest();
  request
    ..open(methode, uri.toString())
    ..withCredentials = true;

  headers.forEach(request.setRequestHeader);
  request.send(body);
  await request.onLoadEnd.first;

  return ReponseHttp(
    statusCode: request.status ?? 0,
    body: request.responseText ?? '',
    headers: const {},
  );
}

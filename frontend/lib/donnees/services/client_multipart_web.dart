// The existing web transport uses dart:html; this conditional adapter keeps
// the multipart transport on the same platform-specific boundary.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

import 'client_api_reponse.dart';
import 'client_multipart_reponse.dart';

Future<ReponseHttp> envoyerRequeteMultipart({
  required String methode,
  required Uri uri,
  required Map<String, String> headers,
  required Map<String, String> fields,
  required List<MultipartPart> parts,
}) async {
  final request = html.HttpRequest();
  final resultat = Completer<ReponseHttp>();
  final formulaire = html.FormData();
  fields.forEach(formulaire.append);
  for (final part in parts) {
    formulaire.appendBlob(
      part.name,
      html.Blob([part.bytes], part.contentType),
      part.filename,
    );
  }
  request
    ..open(methode, uri.toString())
    ..withCredentials = false
    ..timeout = 10000;
  headers.forEach(request.setRequestHeader);
  request.onLoad.listen((_) {
    if (!resultat.isCompleted) {
      resultat.complete(ReponseHttp(
        statusCode: request.status ?? 0,
        body: request.responseText ?? '',
        headers: const {},
      ));
    }
  });
  request.onTimeout.listen((_) {
    if (!resultat.isCompleted) {
      resultat.completeError(
        const ErreurTransportHttp(TypeErreurTransport.delaiDepasse),
      );
    }
  });
  request.onError.listen((_) {
    if (!resultat.isCompleted) {
      resultat.completeError(
        const ErreurTransportHttp(TypeErreurTransport.cors),
      );
    }
  });
  request.send(formulaire);
  return resultat.future;
}

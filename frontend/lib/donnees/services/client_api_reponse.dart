class ReponseHttp {
  const ReponseHttp({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;
}

enum TypeErreurTransport { serveurInaccessible, delaiDepasse, cors }

class ErreurTransportHttp implements Exception {
  const ErreurTransportHttp(this.type);

  final TypeErreurTransport type;
}

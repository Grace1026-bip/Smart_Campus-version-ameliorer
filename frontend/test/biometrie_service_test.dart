import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_app/donnees/services/client_api_reponse.dart';
import 'package:smart_campus_app/donnees/services/client_multipart_reponse.dart';
import 'package:smart_campus_app/donnees/services/service_api.dart';
import 'package:smart_campus_app/donnees/services/service_biometrie.dart';

void main() {
  test('BiometrieApiService envoie trois images sans encodage client',
      () async {
    final captures = <MultipartPart>[];
    final client = ApiService(
      envoyerMultipart: ({
        required methode,
        required uri,
        required headers,
        required fields,
        required parts,
      }) async {
        captures.addAll(parts);
        expect(uri.path, '/api/v1/appariteur/biometrie/etudiants/7/enroler');
        expect(fields['consentement'], 'true');
        return const ReponseHttp(
          statusCode: 201,
          body: '{"succes":true,"donnees":{"statut":"actif"}}',
          headers: {},
        );
      },
    );
    ApiDataSource.client = client;
    final images = [
      XFile.fromData(Uint8List.fromList([1]),
          name: 'one.png', mimeType: 'image/png'),
      XFile.fromData(Uint8List.fromList([2]),
          name: 'two.png', mimeType: 'image/png'),
      XFile.fromData(Uint8List.fromList([3]),
          name: 'three.png', mimeType: 'image/png'),
    ];

    final result = await const BiometrieApiService().enroler(
      etudiantId: 7,
      images: images,
      consentement: true,
    );

    expect(result['statut'], 'actif');
    expect(captures, hasLength(3));
    expect(captures.every((part) => part.name == 'images'), isTrue);
  });
}

import 'package:camera/camera.dart';

import 'client_multipart_reponse.dart';
import 'service_api.dart';

class BiometrieApiService {
  const BiometrieApiService();

  Future<Map<String, dynamic>> profilEtudiant(int etudiantId) {
    return ApiDataSource.client
        .get('/appariteur/biometrie/etudiants/$etudiantId');
  }

  Future<Map<String, dynamic>> enroler({
    required int etudiantId,
    required List<XFile> images,
    required bool consentement,
    String? motif,
  }) async {
    final parts = await _parts(images);
    final path = motif == null
        ? '/appariteur/biometrie/etudiants/$etudiantId/enroler'
        : '/appariteur/biometrie/etudiants/$etudiantId/reenroler';
    return ApiDataSource.client.postMultipart(
      path,
      fields: {
        'consentement': '$consentement',
        if (motif != null) 'motif': motif,
      },
      parts: parts,
    );
  }

  Future<Map<String, dynamic>> reconnaitre({
    required int seanceId,
    required List<XFile> images,
  }) async {
    return ApiDataSource.client.postMultipart(
      '/surveillant/seances/$seanceId/reconnaissance-faciale',
      parts: await _parts(images),
    );
  }

  Future<List<MultipartPart>> _parts(List<XFile> images) async {
    return Future.wait(images.map((image) async {
      final bytes = await image.readAsBytes();
      return MultipartPart(
        name: 'images',
        bytes: bytes,
        filename: image.name,
        contentType: image.mimeType ?? 'image/jpeg',
      );
    }));
  }
}

class BiometrieDataSource {
  static const BiometrieApiService service = BiometrieApiService();
}

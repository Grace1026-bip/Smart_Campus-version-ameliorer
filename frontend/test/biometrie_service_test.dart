import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_app/donnees/services/client_api_reponse.dart';
import 'package:smart_campus_app/donnees/services/client_multipart_reponse.dart';
import 'package:smart_campus_app/donnees/services/service_api.dart';
import 'package:smart_campus_app/donnees/services/service_biometrie.dart';
import 'package:smart_campus_app/fonctionnalites/apparitorat/presentation/ecran_biometrie_appariteur.dart';

void main() {
  testWidgets('le bouton reste desactive avant trois captures', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionsEnrolementBiometrique(
            nombreCaptures: 2,
            consentement: true,
            envoiEnCours: false,
            onEnregistrer: _noop,
          ),
        ),
      ),
    );

    final bouton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(bouton.onPressed, isNull);
    expect(find.textContaining('Encore 1'), findsOneWidget);
  });

  testWidgets('le bouton est active a partir de trois captures', (tester) async {
    var appels = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionsEnrolementBiometrique(
            nombreCaptures: 3,
            consentement: true,
            envoiEnCours: false,
            onEnregistrer: () => appels++,
          ),
        ),
      ),
    );

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Enregistrer le profil biométrique'));
    expect(appels, 1);
  });

  testWidgets('le bouton bloque le double clic pendant l envoi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionsEnrolementBiometrique(
            nombreCaptures: 3,
            consentement: true,
            envoiEnCours: true,
            onEnregistrer: _noop,
          ),
        ),
      ),
    );

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.text('Enregistrement en cours...'), findsOneWidget);
  });

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

  test('BiometrieApiService remonte une erreur backend sans la masquer',
      () async {
    final client = ApiService(
      envoyerMultipart: ({
        required methode,
        required uri,
        required headers,
        required fields,
        required parts,
      }) async {
        return const ReponseHttp(
          statusCode: 409,
          body: '{"message":"Un profil biometrique actif existe deja"}',
          headers: {},
        );
      },
    );
    ApiDataSource.client = client;

    expect(
      () => const BiometrieApiService().enroler(
        etudiantId: 7,
        images: [
          XFile.fromData(
            Uint8List.fromList([1]),
            name: 'one.png',
            mimeType: 'image/png',
          ),
          XFile.fromData(
            Uint8List.fromList([2]),
            name: 'two.png',
            mimeType: 'image/png',
          ),
          XFile.fromData(
            Uint8List.fromList([3]),
            name: 'three.png',
            mimeType: 'image/png',
          ),
        ],
        consentement: true,
      ),
      throwsA(
        isA<ApiException>().having(
          (erreur) => erreur.statusCode,
          'statusCode',
          409,
        ),
      ),
    );
  });
}

void _noop() {}

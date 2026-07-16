# Reconnaissance faciale MVP - Prompt 7C-A

## Finalisation urgente - 2026-07-16

Le moteur reel est maintenant disponible et importable dans `backend/.venv`.
Les images sont decodees par Pillow puis analysees par `face_recognition` ;
FastAPI n'utilise ni `cv.VideoCapture`, ni `cv.imshow`, ni boucle camera.
La camera reste dans Flutter.

La reconnaissance exige exactement trois captures. Chaque capture doit
contenir exactement un visage ; les captures doivent correspondre au meme
profil et chaque distance doit rester strictement sous 0,5. Le meilleur profil
est selectionne par `numpy.argmin` sur la distance moyenne. Un profil sans
encodage actif, un visage inconnu, une distance a 0,5 ou une incoherence
refuse la reconnaissance sans creer de presence. La reponse expose seulement
la decision, la distance moyenne et l'etudiant necessaire au controle ; elle
n'expose ni encodage ni image.

Validation : 185 tests backend reussis deux fois, dont les tests biometrie et
les tests d'import du moteur reel ; 70 tests Flutter reussis deux fois ;
build Web release reussi ; health checks FastAPI HTTP 200. La reconnaissance
positive par camera n'est pas declaree validee automatiquement : elle exige
un visage reel autorise, un consentement et une captation manuelle dans
Chrome. L'anti-spoofing et la vivacite avancee restent hors perimetre.

## Perimetre et statut

Le Prompt 7C-A pose la fondation biométrique de Smart Faculty et ajoute un
flux d'enrolement facial par l'Appariteur ainsi qu'un controle facial
complementaire pour le Surveillant. La reconnaissance faciale ne remplace
pas le controle d'acces central : elle fournit une identite candidate, puis
le service Presence applique les regles de compte actif, d'enrolement valide,
de promotion, d'inscription et de paiement administratif.

Cette version est une fondation injectable. Le moteur reel optionnel n'est
pas installe dans l'environnement de validation actuel : Pillow est present,
mais `face_recognition`, `dlib`, `numpy` et OpenCV ne le sont pas. Le code
retourne donc une indisponibilite explicite plutot que de simuler une
identification.

## Architecture

Le flux est :

1. Flutter utilise `CameraController` et capture trois images au minimum.
2. Les images sont envoyees en multipart au backend.
3. FastAPI valide le MIME, la taille, les dimensions, le nombre de captures
   et le consentement.
4. Le moteur injectable produit un encodage facial temporaire.
5. Le backend compare les captures au profil actif et appelle le controle
   d'acces Presence existant.
6. Une présence unique par étudiant et séance reste garantie par le modèle
   académique.

Le composant Flutter commun gère la permission, l'absence de caméra, le
changement de caméra, le cycle de vie et le double clic. Il n'y a pas de
boucle OpenCV, de `cv.VideoCapture`, `cv.imshow`, `cv.waitKey`, de fichier
pickle ni de stockage d'image originale.

## Données biométriques

La migration `20260715_0010_fondation_biometrique` crée :

- `profils_biometriques` : profil actif, consentement, version du moteur,
  statut, seuil et historique de révocation ;
- `encodages_faciaux` : vecteur binaire float32 little-endian, dimension et
  empreinte SHA-256.

Un seul profil actif est autorisé par étudiant. Un ré-enrolement révoque
l'ancien profil, conserve son historique et crée une nouvelle version. Les
images originales, les mots de passe, les tokens et les encodages ne sont
jamais renvoyés dans les réponses API ou les journaux.

## Enrolement et reconnaissance

Les routes Appariteur sont :

- `GET /api/v1/appariteur/biometrie/etudiants/{etudiant_id}` ;
- `POST .../enroler` ;
- `POST .../reenroler` ;
- `POST .../suspendre` ;
- `POST .../revoquer`.

L'enrolement exige un étudiant actif, une inscription académique cohérente,
un consentement explicite et trois à cinq captures JPEG ou PNG valides. Un
motif est obligatoire pour le ré-enrolement. La route Surveillant est
`POST /api/v1/surveillant/seances/{seance_id}/reconnaissance-faciale`.
Toutes les captures doivent conduire au même candidat et la distance moyenne
doit respecter le seuil configuré. Un visage inconnu ou ambigu ne crée aucune
présence.

Les types et limites sont centralisés dans `parametres.py`. Le seuil courant
est 0,5, la taille maximale est 5 Mo par capture et la dimension minimale est
160 pixels. Ce seuil devra être recalibré avec un moteur réel et un jeu de
validation contrôlé avant toute mise en production biométrique.

## Sécurité et limites

Le consentement est requis lors de l'enrolement. La biométrie est désactivable
par révocation ou suspension. Le Prompt 7C-A ne couvre pas l'anti-spoofing,
la vivacité renforcée, la caméra serveur, OpenCV, la reconnaissance en
production, la conservation d'images, les statistiques avancées ou les
paiements en ligne. Ces sujets sont reportés au Prompt 7C-B ou à une décision
de sécurité dédiée.

## Migrations et validation

La base principale `smart_faculty` a été sauvegardée puis portée en 0009,
sans tables biométriques ni données biométriques. La migration 0010 a été
appliquée et testée par downgrade/upgrade uniquement sur
`smart_faculty_test`. Aucun test n'écrit dans `smart_faculty`.

La dépendance Flutter utilisée est le plugin officiel [`camera`](https://pub.dev/packages/camera),
version `0.12.0+2`. Le backend ne télécharge pas de dépendance biométrique
optionnelle automatiquement.

Validation réalisée :

- backend : 174 tests réussis lors de deux exécutions complètes ;
- tests biométriques ciblés : 5 réussis ;
- Flutter : 62 tests réussis lors de deux exécutions complètes ;
- analyse Flutter : aucune erreur ni avertissement, 14 informations
  historiques conservées ;
- build Web release réussi ;
- health checks FastAPI HTTP 200.

La vérification interactive des rôles dans Chrome n'a pas pu être exécutée
dans cette session : l'extension de contrôle du navigateur était indisponible
et le port Flutter 52100 était déjà occupé par un serveur existant. Une
validation manuelle reste requise avant de considérer la reconnaissance
faciale réelle comme validée.

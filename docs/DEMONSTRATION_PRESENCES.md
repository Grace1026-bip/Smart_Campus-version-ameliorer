# Demonstration des presences

## Etat valide

- FastAPI : `http://127.0.0.1:8000`
- Flutter Web : `http://localhost:52100`
- base de demonstration : `smart_faculty`
- tests automatises : `smart_faculty_test` uniquement
- mode manuel : controle par matricule
- mode facial : trois captures, moteur `face_recognition` reel disponible

## Demarrage

1. Verifier que MySQL/WAMP est actif sur le port configure par le projet.
2. Depuis `backend`, lancer FastAPI avec `scripts\demarrer_backend.bat`.
3. Depuis `frontend`, lancer `flutter run -d chrome --web-port 52100`.
4. Verifier `/`, `/api/v1/statut` et `/api/v1/sante/base-de-donnees` en HTTP 200.

## Controle manuel

1. Se connecter avec le compte Surveillant local actif.
2. Ouvrir `Controle d'acces`.
3. Creer ou selectionner une seance.
4. Ouvrir la seance.
5. Saisir le matricule de l'etudiant de demonstration.
6. Verifier le motif, l'acces et la presence.
7. Refaire le controle pour verifier l'absence de doublon.
8. Fermer la seance et presenter le resume.

## Enrolement facial

1. Se connecter avec le compte Appariteur local actif.
2. Ouvrir l'enrolement biometrique.
3. Selectionner un etudiant actif avec enrolement valide.
4. Confirmer le consentement explicite.
5. Capturer trois a cinq images d'une seule personne.
6. Verifier la progression, puis terminer l'enrolement.
7. Quitter l'ecran pour liberer le controleur camera.

Les images originales ne sont pas conservees. Ne pas utiliser le visage d'une
personne sans son consentement. Ne pas inserer de photo personnelle dans Git.

## Reconnaissance faciale

1. Se deconnecter puis se connecter comme Surveillant.
2. Selectionner une seance ouverte.
3. Ouvrir le panneau `Reconnaissance faciale`.
4. Autoriser la camera dans Chrome.
5. Capturer exactement trois images du meme visage.
6. Verifier `Visage reconnu`, la distance moyenne, l'acces et le motif.
7. Verifier `Presence enregistree` lorsque le controle central autorise
   l'etudiant.
8. Refaire immediatement la capture : le motif doit indiquer que la presence
   est deja enregistree et aucune seconde ligne ne doit etre creee.
9. Tester un visage non enrole : aucune presence ne doit etre creee.

Le moteur refuse une image vide, un format non JPEG/PNG, plusieurs visages,
aucun visage, des captures incoherentes, un profil suspendu/revoque ou une
distance moyenne superieure ou egale a 0,5. Le paiement, la promotion,
l'inscription, la seance et l'unicite restent controles par le backend.

## Limites a dire au jury

- La vivacite renforcee et l'anti-spoofing complet ne sont pas implementes.
- La reconnaissance faciale est un mode complementaire, pas une garantie
  d'identite a 100 %.
- Le controle manuel par matricule reste le mode de repli.
- Aucune image originale n'est stockee.

## Arret

Fermer l'ecran camera, se deconnecter, puis arreter Flutter avec `q` et
FastAPI avec `Ctrl+C`. Ne pas appliquer de migration ni lancer de test sur
`smart_faculty`.

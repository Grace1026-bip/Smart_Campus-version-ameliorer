# Smart Faculty - Cahier des charges technique

## Role du document

Ce document est la memoire technique permanente du projet Smart Faculty.
Il doit etre mis a jour lorsque des decisions structurantes sont prises.

## Regles de travail validees

- Conserver le travail existant qui fonctionne.
- Ne pas repartir de zero.
- Ne pas reecrire une fonctionnalite lorsqu'une correction locale suffit.
- Travailler par prompts successifs et valider chaque etape avant la suivante.
- Ne pas modifier plusieurs modules importants dans une meme intervention.
- Documenter les raisons, les risques, les fichiers touches et l'impact avant toute modification importante.
- Garder une architecture simple, lisible et maintenable.

## Documentation de reference

La documentation officielle du projet se trouve dans:

- `docs/00_Admission`
- `docs/01_Analyse`
- `docs/02_Conception`

Toute prochaine modification doit rester coherente avec ces documents.

## Etat technique constate le 2026-07-10

### Frontend

- Application Flutter existante dans `frontend`.
- Point d'entree principal: `frontend/lib/main.dart`.
- Application principale: `frontend/lib/application.dart`.
- Routage centralise par role dans `frontend/lib/coeur/routes/routes_application.dart`.
- Services API presents pour l'authentification, les notes, la valve, les notifications, les reclamations, les risques et le dashboard.
- Certains modules conservent encore des donnees fictives ou des anciens dossiers vides.

### Backend

- Backend FastAPI existant dans `backend/app`.
- Point d'entree officiel documente: `backend/app/main.py`.
- Routes API regroupees sous `/api/v1`.
- Modules presents: authentification, academique, dashboard, notes, notifications, valve, reclamations, risques.
- Base de donnees geree via SQLAlchemy, Alembic et MySQL.
- Tests backend existants dans `backend/tests`.
- Ancien code PHP archive dans `legacy/php`.
- Ancien point d'entree Flask archive dans `legacy/flask`.

### Base de donnees

- Schemas SQL actifs presents dans `backend/base_de_donnees`.
- Schemas SQL initiaux archives dans `legacy/autres/bdd_initiale` et `legacy/php/backend_database`.
- Migrations Alembic presentes dans `backend/alembic/versions`.
- Les tests backend exigent une base separee dont le nom finit par `_test`.

## Decisions techniques actuelles

### D1 - Ne pas supprimer l'ancien backend PHP pendant l'audit

Raison: l'audit ne doit pas modifier profondement le projet.

Avantage: aucun risque de perte d'un module encore utile.

Risque: l'ambiguite entre FastAPI et PHP reste visible temporairement.

Impact: une prochaine etape devra clarifier officiellement le backend actif.

### D2 - Considerer FastAPI comme backend principal a verifier en priorite

Raison: la documentation `backend/README.md`, les tests et le frontend pointent vers l'API FastAPI sur le port 8000.

Avantage: donne une cible claire pour les prochains tests.

Risque: l'ancien backend PHP peut contenir des fonctionnalites non migrees.

Impact: les prochains prompts devront comparer avant suppression ou archivage.

### D3 - Ne pas corriger les tests dans le prompt d'audit

Raison: la mission actuelle demande uniquement un audit complet.

Avantage: le rapport reste objectif et ne melange pas correction et diagnostic.

Risque: les tests restent non validables tant que l'environnement `_test` n'est pas prepare.

Impact: Prompt 14 devra inclure une mise en place propre de l'environnement de test.

### D4 - Architecture officielle apres reorganisation controlee

Raison: le Prompt 2 valide Flutter, FastAPI et MySQL comme technologies officielles.

Avantage: la racine du projet se lit plus clairement: `frontend`, `backend`, `docs`, `legacy`, `scripts`.

Risque: les anciens chemins `app_mobile` et `Documents_Smart_Faculty` ne doivent plus etre utilises dans les nouveaux scripts ou documents.

Impact: les prochaines interventions doivent partir de `frontend/` pour Flutter et de `backend/app/main.py` pour FastAPI.

### D5 - Archivage temporaire des anciennes technologies

Raison: PHP et Flask ne sont plus les technologies principales, mais leur suppression definitive n'est pas autorisee dans cette intervention.

Avantage: le code actif n'est plus melange aux anciennes implementations.

Risque: certains anciens elements peuvent encore contenir une logique utile a comparer avant suppression definitive.

Impact: toute suppression future dans `legacy/` devra etre justifiee et validee separement.

### D6 - Environnement de test backend

Raison: les tests backend ne doivent jamais cibler la base principale `smart_faculty`.

Avantage: les tests peuvent creer, modifier ou nettoyer des donnees sans risque pour les donnees reelles.

Risque: tant que MySQL WAMP n'est pas demarre sur le port attendu, les migrations et tests ne peuvent pas etre executes.

Impact: la base de test officielle est `smart_faculty_test`; le modele de configuration est `backend/.env.test.example`.

### D7 - Diagnostic Flutter local

Raison: les commandes `flutter` et `dart` via `frontend/` restent silencieuses dans l'environnement courant.

Avantage: le probleme est isole au SDK Flutter local ou a ses verrous, pas a un ecran ou une logique Flutter.

Risque: le frontend ne peut pas encore etre valide par `flutter analyze` et `flutter test`.

Impact: avant le Prompt 3, il faut liberer ou nettoyer les verrous du SDK Flutter situe hors workspace, puis relancer les commandes Flutter.

## Contraintes techniques importantes

- Ne jamais lancer les tests backend sur la base de production ou de developpement principale.
- Eviter de suivre dans Git les environnements virtuels, caches, builds, logs et sessions.
- Garder un seul point d'entree backend officiel.
- Garder une seule convention de structure frontend.
- Mettre a jour le journal apres chaque intervention.
- Les scripts actifs doivent lancer FastAPI et Flutter uniquement.
- Les anciens scripts PHP ou Flask doivent rester archives dans `legacy/`.
- Les tests backend doivent cibler `smart_faculty_test`.
- Ne jamais contourner la protection `_test` presente dans `backend/tests/conftest.py`.

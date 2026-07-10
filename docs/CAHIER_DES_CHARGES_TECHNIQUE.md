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

Raison: les commandes `flutter` et `dart` via `frontend/` restaient silencieuses lorsque le SDK local ne pouvait pas ecrire dans son cache hors workspace.

Avantage: le probleme est isole a l'environnement d'execution Flutter, pas a un ecran ou une logique Flutter.

Risque: `flutter analyze` signale encore des infos/lints liees a `dart:html`; elles devront etre traitees hors Prompt 2.5.

Impact: `flutter test` est executable et reussi; `flutter analyze` est executable mais retourne 6 infos/lints.

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
- Le script de test backend officiel est `scripts/test_backend.bat`.
## Decision Prompt 2.6 - Architecture backend active

Le backend actif reste FastAPI dans `backend/app`.

- Point d'entree officiel: `backend/app/main.py`.
- Connexion SQLAlchemy officielle: `backend/app/base_de_donnees/connexion.py`.
- Base declarative SQLAlchemy officielle: `backend/app/base_de_donnees/base.py`.
- Configuration active: `backend/app/configuration/`.
- Modeles actifs: `backend/app/modeles/`.
- Schemas actifs: `backend/app/schemas/`.
- Routes actives: `backend/app/routes/`.
- Services actifs: `backend/app/services/`.
- Migrations Alembic: `backend/alembic/versions/`.
- Scripts SQL historiques ou de reference: `backend/base_de_donnees/`.

La documentation conceptuelle emploie les noms `config`, `database`, `models`, `repositories`; le code actif emploie les equivalents francais `configuration`, `base_de_donnees`, `modeles`, `depots`. Cette difference est acceptee car les imports FastAPI, Alembic, scripts et tests confirment la structure francaise existante.

Le reliquat vide `backend/app/bdd/connexion.py` a ete retire car il n'etait importe par aucun fichier actif et doublonnait le nom de responsabilite de `backend/app/base_de_donnees`.

### Resultat Prompt 2.6 - MySQL et tests

MySQL WAMP repond sur `127.0.0.1:3307`.

- `smart_faculty` existe et contient 29 tables.
- `smart_faculty.alembic_version` existe avec la revision `20260705_0002`.
- Une sauvegarde locale de `smart_faculty` a ete creee dans `backend/sauvegardes/`, dossier ignore par Git.
- `smart_faculty_test` a ete creee avec le script non destructif `backend/scripts/preparer_base_test.sql`.
- Les migrations Alembic ont ete appliquees sur `smart_faculty_test` jusqu'a `20260705_0002`.
- Les donnees initiales de test ont ete creees ou verifiees sur `smart_faculty_test`.
- Les tests backend officiels passent: `26 passed in 40.87s`.

Decision: le backend est considere coherent et testable pour preparer le Prompt 3 sur l'authentification.

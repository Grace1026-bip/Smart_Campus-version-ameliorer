# Smart Faculty - Journal de developpement

## 2026-07-10 - Prompt 1 - Audit general du projet

### Module concerne

- Projet complet: documentation, frontend Flutter, backend FastAPI/PHP, base de donnees, tests et structure de depot.

### Fichiers crees

- `CAHIER_DES_CHARGES_TECHNIQUE.md`
- `JOURNAL_DE_DEVELOPPEMENT.md`

### Fichiers modifies

- Aucun fichier applicatif modifie.

### Fichiers supprimes

- Aucun.

### Dossiers crees

- Aucun.

### Dossiers supprimes

- Aucun.

### Bugs detectes

- `pytest` lance depuis `backend` avec le Python global echoue car `fastapi` n'est pas installe dans l'environnement global.
- `pytest` lance avec `backend/.venv/Scripts/python.exe` collecte 26 tests mais les bloque tous car la base configuree est `smart_faculty` et non une base finissant par `_test`.
- `flutter test` reste suspendu sans sortie exploitable pendant l'audit.
- Le depot contient plusieurs points d'entree backend concurrents: FastAPI (`backend/app/main.py`), Flask (`backend/main.py`) et PHP (`backend/public/index.php`).
- Le script `scripts/demarrer_backend.bat` annonce le port 8000 mais lance un serveur PHP, alors que le frontend et le README attendent FastAPI.
- Des fichiers sensibles ou locaux semblent suivis par Git, notamment `.env` et `backend/.env`.
- Des artefacts ignores mais volumineux existent dans le workspace: `.dart_tool`, `build`, `.venv`, caches, logs et sessions.
- Plusieurs dossiers vides ou anciens modules sont presents dans `app_mobile/lib` et dans les dossiers racine `tests`, `ia`, `stockage`.

### Bugs corriges

- Aucun bug applicatif corrige, conformement a la mission d'audit uniquement.

### Optimisations realisees

- Creation de la memoire technique et du journal permanent du projet.

### Points forts

- Frontend Flutter deja structure avec routage par role et services API.
- Backend FastAPI deja organise en routes, services, schemas, modeles et dependances.
- Tests backend nombreux et couverts par module.
- Documentation officielle presente dans `Documents_Smart_Faculty`.
- Migrations Alembic et scripts de donnees initiales presents.

### Points faibles

- Architecture backend encore brouillee par la coexistence FastAPI, Flask et PHP.
- Documentation racine vide ou incomplete (`README.md`, `requirements.txt`, `docker-compose.yml`).
- Ancienne documentation frontend partiellement desynchronisee avec les chemins actuels.
- Environnement de test non directement operationnel.
- Nettoyage Git et hygiene des secrets a traiter rapidement.

### Incoherences

- Nom du projet alterne entre Smart Campus, Smart Faculty et Bulali ID dans certains fichiers.
- Dossiers `coeur/commun/donnees/fonctionnalites` coexistent avec d'anciens dossiers anglophones ou vides.
- Plusieurs schemas SQL coexistent sans decision visible sur la source officielle.
- Le backend officiel est documente comme FastAPI mais un script de demarrage lance PHP.

### Risques

- Risque de lancer ou tester le mauvais backend.
- Risque de fuite de configuration locale si `.env` reste suivi par Git.
- Risque de casser des parcours si les anciens dossiers sont supprimes sans cartographie.
- Risque de faux sentiment de qualite tant que les tests ne tournent pas sur une base `_test`.

### Recommandations

- Valider officiellement FastAPI comme backend actif avant toute suppression.
- Mettre en place une base `smart_faculty_test` et relancer les tests backend.
- Diagnostiquer le blocage `flutter test` avant les corrections frontend.
- Nettoyer progressivement les scripts, dossiers vides, caches et anciennes versions.
- Mettre a jour la documentation racine avec les commandes officielles.
- Ne traiter qu'un module par prompt, comme demande dans la directive CTO.

### Plan d'action propose pour les prochains prompts

1. Prompt 2: reorganisation legere de l'architecture, sans suppression risquee.
2. Prompt 3: revision du systeme d'authentification, cote FastAPI puis Flutter.
3. Prompt 4 a 7: verifier chaque compte utilisateur dans l'ordre: Enseignant, Etudiant, Appariteur, Doyen.
4. Prompt 8 a 13: reviser les modules fonctionnels un par un.
5. Prompt 14: preparer et executer les tests complets.
6. Prompt 15: optimisation finale, nettoyage et documentation de soutenance.

## 2026-07-10 - Prompt 2 - Nettoyage et reorganisation controlee

### Module concerne

- Structure globale du projet: frontend, backend, docs, legacy, scripts, fichiers de configuration.

### Fichiers crees

- `README.md`
- `scripts/demarrer_backend.bat`
- `scripts/demarrer_frontend.bat`
- `legacy/php/README.md`
- `legacy/flask/README.md`
- `legacy/autres/README.md`

### Fichiers modifies

- `.gitignore`
- `docs/CAHIER_DES_CHARGES_TECHNIQUE.md`
- `docs/JOURNAL_DE_DEVELOPPEMENT.md`

### Fichiers deplaces

- `app_mobile/*` vers `frontend/`
- `Documents_Smart_Faculty/00_Admission` vers `docs/00_Admission`
- `Documents_Smart_Faculty/01_Analyse` vers `docs/01_Analyse`
- `Documents_Smart_Faculty/02_conception` vers `docs/02_Conception`
- `documentation/` vers `docs/references_techniques/`
- `CAHIER_DES_CHARGES_TECHNIQUE.md` vers `docs/CAHIER_DES_CHARGES_TECHNIQUE.md`
- `JOURNAL_DE_DEVELOPPEMENT.md` vers `docs/JOURNAL_DE_DEVELOPPEMENT.md`
- Anciennes parties PHP de `backend/` vers `legacy/php/`
- Ancien point d'entree Flask `backend/main.py` vers `legacy/flask/backend_main_flask.py`
- Ancien dossier `bdd/` vers `legacy/autres/bdd_initiale/`
- Ancien dossier `ia/` vers `legacy/autres/ia_experimentale/`
- Fichiers racine vides ou obsoletes vers `legacy/autres/racine_obsolete/`
- Scripts racine vides vers `legacy/autres/scripts_racine_vides/`

### Fichiers supprimes

- Aucun fichier applicatif important supprime.

### Dossiers crees

- `frontend/`
- `docs/`
- `legacy/`
- `legacy/php/`
- `legacy/flask/`
- `legacy/autres/`

### Dossiers supprimes

- `Documents_Smart_Faculty/` apres deplacement de son contenu.
- `tests/` et sous-dossiers vides.
- `stockage/` et sous-dossiers vides.

### Bugs detectes

- Le dossier `app_mobile` etait verrouille pendant le deplacement direct.
- Des processus Dart/Flutter anciens ont du etre arretes pour liberer une partie du contenu.
- Certains caches Flutter restaient presents apres le deplacement et doivent etre ignores par Git.
- `flutter analyze` reste silencieux et la session terminale demeure active meme apres arret des processus Dart visibles.

### Bugs corriges

- Ambiguite du script `scripts/demarrer_backend.bat`: il lance maintenant FastAPI au lieu de PHP.
- Ambiguite des anciennes technologies: PHP et Flask sont archives dans `legacy/`.
- Dossier `app_mobile/` vide supprime apres arret cible des sessions PowerShell bloquees.

### Optimisations realisees

- Isolation du frontend Flutter dans `frontend/`.
- Regroupement de la documentation officielle dans `docs/`.
- Archivage controle du code PHP et Flask.
- Nettoyage des dossiers racine vides.
- Mise a jour de `.gitignore` pour les caches, environnements, logs et secrets locaux.

### Verifications realisees

- Import FastAPI: reussi avec `backend/.venv/Scripts/python.exe -c "from app.main import app; print(app.title)"`, resultat `Smart Faculty API`.
- Tests backend: 26 tests collectes, execution arretee par la protection exigeant une base finissant par `_test`; base actuelle `smart_faculty`.
- Analyse Flutter: `flutter analyze` puis `flutter analyze --no-pub` lances depuis `frontend/`, mais restent sans sortie exploitable et doivent etre consideres comme bloques dans cet environnement.
- Tests Flutter: non relances apres le blocage de `flutter analyze`, pour eviter d'empiler des processus Dart bloques.

### Prochaines etapes

- Relancer les tests backend avec une base `smart_faculty_test`.
- Continuer avec le Prompt 3: revision du systeme d'authentification.

## 2026-07-10 - Prompt 2.5 - Stabilisation environnement et tests

### Module concerne

- Environnement backend, configuration de test, diagnostic Flutter, scripts de lancement et documentation.

### Fichiers crees

- `backend/.env.test.example`
- `backend/scripts/preparer_base_test.sql`
- `scripts/test_backend.bat`

### Fichiers modifies

- `.gitignore`
- `scripts/demarrer_frontend.bat`
- `README.md`
- `docs/CAHIER_DES_CHARGES_TECHNIQUE.md`
- `docs/JOURNAL_DE_DEVELOPPEMENT.md`

### Fichiers supprimes

- Aucun fichier applicatif supprime.

### Dossiers crees

- Aucun.

### Dossiers supprimes

- Aucun.

### Bugs detectes

- MySQL WAMP cible du projet sur `127.0.0.1:3307` est indisponible.
- Le service Windows `wampmysqld64` est arrete.
- Le port `3306` repond, mais ne correspond pas a la configuration active du backend et refuse l'acces sans identifiants.
- `.env` et `backend/.env` sont deja suivis par Git; `.gitignore` ne peut pas les ignorer retroactivement.
- Les commandes `flutter --version` et `dart --version` via le PATH restent silencieuses.
- Le binaire Dart direct `flutter/bin/cache/dart-sdk/bin/dart.exe` fonctionne, ce qui isole le probleme au wrapper Flutter/Dart ou au cache Flutter.
- Des fichiers de verrou Flutter existent hors workspace dans le cache du SDK: `flutter.bat.lock` et `lockfile`.
- Apres autorisation d'acces au cache SDK, Flutter fonctionne; le blocage etait lie a l'environnement sandbox et aux verrous du SDK.
- `flutter analyze --verbose` termine avec 6 infos/lints liees a `dart:html` et `avoid_web_libraries_in_flutter`.
- `flutter doctor -v` signale l'absence de SDK Android.

### Bugs corriges

- Le script `scripts/demarrer_frontend.bat` verifie maintenant que Flutter est accessible avant de lancer l'application.
- Les verrous Flutter obsoletes `flutter.bat.lock` et `lockfile` ont ete supprimes apres autorisation.

### Optimisations realisees

- Ajout d'un modele `backend/.env.test.example` sans secret reel.
- Ajout d'un script SQL non destructif pour creer `smart_faculty_test`.
- Ajout du script `scripts/test_backend.bat` ciblant `smart_faculty_test`.
- Ajout de `.env.test` et `backend/.env.test` dans `.gitignore`.
- Documentation de la base de test officielle `smart_faculty_test`.
- Documentation des commandes de test backend avec variable `MYSQL_DATABASE=smart_faculty_test`.

### Verifications realisees

- Structure active: `frontend/`, `backend/`, `docs/`, `legacy/`, `scripts/`.
- Recherche hors `legacy/`: aucune reference active a `app_mobile`, `Documents_Smart_Faculty`, `backend/main.py`, PHP ou Flask.
- Import FastAPI, routes, modeles et services: reussi avec le venv backend; application detectee `Smart Faculty API`.
- Configuration backend: chargee depuis `.env` et `backend/.env`; base principale detectee `smart_faculty`.
- SQLAlchemy: configure via `app/base_de_donnees/connexion.py`.
- Alembic: configure via `backend/alembic.ini` et `backend/alembic/env.py`.
- MySQL: connexion projet sur `127.0.0.1:3307` impossible tant que le service WAMP MySQL est arrete.
- Flutter/Dart: `where.exe flutter` et `where.exe dart` trouvent le SDK; Dart direct fonctionne; wrappers Flutter/Dart bloquent.
- FastAPI: Uvicorn demarre sur port de diagnostic `8010`; `/` et `/api/v1/statut` repondent correctement.
- Pytest avec `MYSQL_DATABASE=smart_faculty_test`: 26 tests collectes, 1 reussi, 9 echoues, 16 erreurs; cause principale: connexion refusee vers MySQL `127.0.0.1:3307`.
- Flutter: `flutter --version` OK, `dart --version` OK, `flutter doctor -v` OK sauf SDK Android absent.
- Flutter: `flutter pub get` OK.
- Flutter: `flutter test --reporter expanded` OK, 2 tests reussis.
- Flutter: `flutter analyze --verbose` termine avec 6 infos/lints.

### Commandes MySQL recommandees

Si WAMP MySQL est demarre et que les droits sont disponibles, creer la base de test vide avec:

```sql
CREATE DATABASE IF NOT EXISTS smart_faculty_test
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
```

### Prochaines etapes

- Demarrer le service MySQL WAMP `wampmysqld64`.
- Creer `smart_faculty_test`.
- Appliquer les migrations Alembic sur `smart_faculty_test`.
- Relancer `backend/.venv/Scripts/python.exe -m pytest -v`.
- Corriger les 6 infos/lints Flutter `dart:html` dans une intervention frontend dediee.
- Retirer `.env` et `backend/.env` de l'index Git sans supprimer les fichiers locaux, apres validation.
## Prompt 2.6 - Clarification backend et finalisation MySQL

### Objectif

- Clarifier les dossiers backend similaires avant toute intervention sur l'authentification.
- Verifier MySQL WAMP sur `127.0.0.1:3307`.
- Creer et utiliser `smart_faculty_test` pour les migrations et tests backend.

### Documents consultes

- `docs/CAHIER_DES_CHARGES_TECHNIQUE.md`
- `docs/JOURNAL_DE_DEVELOPPEMENT.md`
- `docs/02_Conception/02.01 - Architecture generale.docx`
- `docs/02_Conception/02.02 - Conception de la base de donnees.docx`
- `docs/02_Conception/02.03 - Architecture du projet.docx`
- `docs/02_Conception/02.04 - Architecture des API REST.docx`
- `docs/01_Analyse/01.07 - Regles metier.docx`

### Clarification d'architecture

- La documentation officielle confirme l'architecture Flutter, FastAPI et MySQL.
- La documentation conceptuelle nomme les responsabilites `config`, `database`, `models`, `schemas`, `routes`, `services`, `repositories`.
- Le code actif utilise des noms francais equivalents: `configuration`, `base_de_donnees`, `modeles`, `schemas`, `routes`, `services`, `depots`.
- `backend/app/base_de_donnees/connexion.py` est importe par les routes, dependances, tests, scripts et reste le chemin officiel de connexion SQLAlchemy.
- `backend/app/base_de_donnees/base.py` est importe par les modeles et Alembic comme base declarative SQLAlchemy.
- `backend/base_de_donnees` n'est pas un module Python FastAPI; il contient des scripts SQL et migrations SQL historiques ou de reference.
- `backend/app/bdd/connexion.py` etait vide, non importe et non utilise.

### Modification structurelle realisee

- Suppression de `backend/app/bdd/connexion.py`, fichier vide et doublon reel inutilise.
- Aucun modele metier, aucune route, aucune migration Alembic et aucune regle d'authentification n'ont ete modifies.

### Etat MySQL

- La verification MySQL complete du Prompt 2.6 reste a terminer: l'environnement d'execution a bloque les commandes avant la verification du port, la sauvegarde, la creation de `smart_faculty_test`, les migrations et les tests.
- Aucune donnee de `smart_faculty` n'a ete modifiee pendant cette phase.

### Resultats finaux apres reprise des commandes

- MySQL WAMP repond sur `127.0.0.1:3307`.
- `smart_faculty` existe, contient 29 tables et pointe sur Alembic `20260705_0002`.
- Une sauvegarde locale de `smart_faculty` a ete creee dans `backend/sauvegardes/`, dossier ignore par Git.
- `smart_faculty_test` a ete creee avec `backend/scripts/preparer_base_test.sql`.
- Avant migrations, `smart_faculty_test` etait vide.
- Alembic a applique les revisions `20260705_0001` puis `20260705_0002` sur `smart_faculty_test`.
- Apres migrations, `smart_faculty_test` contient 29 tables et `alembic_version=20260705_0002`.
- `backend/scripts/creer_donnees_initiales.py` est idempotent et ne contient pas de suppression destructrice; il a ete execute sur `smart_faculty_test`.
- Import FastAPI reussi: `Smart Faculty API`, 86 routes, moteur SQLAlchemy cible `smart_faculty_test`.
- Uvicorn a demarre sur `127.0.0.1:8010`; `/` et `/api/v1/statut` ont repondu correctement.
- Alembic current: `20260705_0002 (head)`.
- Tests backend avec `scripts/test_backend.bat`: 26 tests collectes, 26 reussis, 0 echec, 0 erreur, 0 ignore, duree 40.87 s.
- Aucune donnee de `smart_faculty` n'a ete modifiee hors sauvegarde en lecture.

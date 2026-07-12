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

## Prompt 3B - Demandes d'inscription et approbation

### Etat initial valide

- `scripts/test_backend.bat`: 41 tests collectes, 41 reussis avant modification.
- MySQL WAMP disponible sur `127.0.0.1:3307`.
- Base de test officielle: `smart_faculty_test`.

### Audit avant modification

- Aucun modele SQLAlchemy actif ne gerait les demandes d'inscription.
- Aucune route FastAPI active ne permettait la creation, l'approbation ou le rejet d'une demande.
- Une table historique `demandes_inscription` existait uniquement dans une sauvegarde SQL ancienne; elle n'a pas ete reprise comme source principale.
- Les modeles actifs disponibles pour l'approbation sont `Utilisateur`, `UtilisateurRole`, `Etudiant`, `Enseignant`, `Promotion` et `Role`.

### Fichiers crees

- `backend/app/modeles/inscriptions.py`
- `backend/app/schemas/inscriptions.py`
- `backend/app/services/inscriptions.py`
- `backend/app/routes/inscriptions.py`
- `backend/alembic/versions/20260711_0003_demandes_inscription.py`
- `backend/tests/test_inscriptions.py`
- `frontend/lib/donnees/services/service_inscriptions.dart`
- `frontend/lib/fonctionnalites/authentification/presentation/ecran_demande_inscription.dart`

### Fichiers modifies

- `backend/app/modeles/__init__.py`
- `backend/app/routes/api.py`
- `frontend/lib/coeur/routes/routes_application.dart`
- `frontend/lib/fonctionnalites/authentification/presentation/ecran_connexion.dart`
- `frontend/test/service_api_test.dart`
- `README.md`
- `docs/CAHIER_DES_CHARGES_TECHNIQUE.md`
- `docs/JOURNAL_DE_DEVELOPPEMENT.md`

### Regles implementees

- Les demandes publiques acceptent seulement `etudiant` et `enseignant`.
- Le mot de passe est hache immediatement et le hash n'est jamais retourne.
- Les statuts de demande sont `en_attente`, `approuvee`, `rejetee`.
- L'approbation cree un compte utilisateur `actif`, le profil correspondant et le role attendu.
- Le rejet ne cree aucun compte.
- Une demande deja traitee ne peut pas etre retraitee.
- La consultation publique du statut exige la reference et l'email.
- Le formulaire Flutter public ne propose aucun role privilegie et ne cree aucune session apres soumission.

### Resultats de verification

- Tests inscriptions seuls: 16 collectes, 16 reussis.
- Suite backend complete, execution 1: 57 collectes, 57 reussis, 0 echec, 0 erreur.
- Suite backend complete, execution 2: 57 collectes, 57 reussis, 0 echec, 0 erreur.
- FastAPI demarre sur `127.0.0.1:8010`; `/`, `/api/v1/statut` et `POST /api/v1/inscriptions/demandes` repondent.
- Flutter `flutter test --reporter expanded`: 15 tests reussis.
- Flutter `flutter analyze`: 6 infos historiques `dart:html`, aucune nouvelle alerte liee au Prompt 3B.
- `smart_faculty` reste a Alembic `20260705_0002` et ne contient pas `demandes_inscription`.

## Prompt 3B.1 - Deploiement local controle de la migration d'inscription

### Objectif

- Appliquer sur la base locale principale `smart_faculty` la migration deja testee `20260711_0003_demandes_inscription.py`.
- Ne developper aucune nouvelle fonctionnalite.
- Ne pas lancer de seed de test sur `smart_faculty`.

### Verifications prealables

- MySQL WAMP repond sur `127.0.0.1:3307`.
- `APP_ENV` et `MYSQL_DATABASE` etaient absents de l'environnement avant migration.
- `smart_faculty`: revision `20260705_0002`, 29 tables, `demandes_inscription` absente.
- `smart_faculty_test`: revision `20260711_0003`, 30 tables, `demandes_inscription` presente.
- Migration presente: `backend/alembic/versions/20260711_0003_demandes_inscription.py`.

### Audit de migration

- Upgrade: creation de la table `demandes_inscription`.
- Colonnes: reference, type_demande, email, identite, mot_de_passe_hash, champs etudiant, champs enseignant, statut, utilisateur lie, approbateur, dates.
- Index: email, statut, type_demande/statut.
- Contrainte unique: reference.
- Relations: promotion et utilisateurs.
- Aucun `DROP TABLE`, aucune suppression de colonne, aucune modification de compte existant.

### Sauvegarde

- Sauvegarde complete locale creee dans `backend/sauvegardes/`.
- Fichier non vide: environ 41 Ko.
- Dossier confirme ignore par Git.
- La sauvegarde n'a pas ete affichee ni ajoutee au depot.

### Migration appliquee

- Commande: `backend/.venv/Scripts/python.exe -m alembic upgrade head`.
- Cible: `127.0.0.1:3307/smart_faculty`.
- Revision avant: `20260705_0002`.
- Revision apres: `20260711_0003`.
- Aucune erreur Alembic.

### Verifications apres migration

- `smart_faculty`: 30 tables.
- `demandes_inscription`: presente avec 20 colonnes.
- Contrainte unique `uq_demandes_inscription_reference` presente.
- Index `email`, `statut`, `type_demande/statut` presents.
- Utilisateurs et roles existants toujours presents.
- FastAPI demarre sur `127.0.0.1:8010`.
- `GET /` OK.
- `GET /api/v1/statut` OK.
- `POST /api/v1/inscriptions/demandes` OK sur une demande de demonstration non approuvee: `demo.inscription.3b1@smartfaculty.test`.

### Tests apres migration

- `scripts/test_backend.bat`: cible verifiee `127.0.0.1:3307/smart_faculty_test`.
- Alembic test applique jusqu'a `20260711_0003`.
- Backend: 57 tests collectes, 57 reussis, 0 echec, 0 erreur, duree 66.10 s.
- Les tests Flutter n'ont pas pu etre relances pendant 3B.1 car l'escalade SDK Flutter a ete refusee par la limite d'utilisation de l'environnement.
- Dernier resultat Flutter valide du Prompt 3B: `flutter test --reporter expanded`, 15 tests reussis; `flutter analyze`, 6 infos historiques `dart:html`.

### Performance

- Le run a 634.92 s observe pendant 3B etait ponctuel: la suite identique repasse a 66.10 s apres la migration locale.
- Cause probable: ralentissement externe temporaire, attente MySQL/shell ou contention locale, plutot qu'un test precis devenu lent.
- Recommandation: si le phenomene revient, mesurer par test avec `pytest --durations=20` sans modifier la logique metier.

## Prompt 2.7 - Isolation et reproductibilite des tests backend

### Etat initial et cause

- Etat reproduit: 26 tests collectes, 24 reussis, 2 echoues, 0 erreur.
- `BD201` conservait une evaluation publiee de ponderation 100 % et `WEB202` une evaluation brouillon de ponderation 100 %.
- Le seed FastAPI actif cree les deux cours, mais aucune evaluation, note ou ponderation; `backend/base_de_donnees/donnees_test.sql` est historique et n'est pas execute.
- Les fixtures ne faisaient que verifier le suffixe `_test`; les sessions FastAPI validaient leurs transactions et aucun nettoyage ne suivait.
- Les tables de test etaient en MyISAM, moteur non transactionnel choisi par defaut par MySQL WAMP. Un rollback SQLAlchemy ne pouvait donc pas annuler les ecritures.

### Correction

- Ajout de `backend/scripts/reinitialiser_base_test.py`: cible verrouillee sur `127.0.0.1:3307/smart_faculty_test`, recreation controlee, migrations Alembic et seed actif sans affichage du mot de passe de test.
- Mise a jour de `backend/alembic/env.py`: InnoDB est force uniquement pour la cible officielle lorsque `APP_ENV=test`.
- Mise a jour de `backend/tests/conftest.py`: transaction externe autouse, surcharge de la dependance FastAPI, sessions directes liees a la meme connexion, savepoints et rollback final.
- Mise a jour de `scripts/test_backend.bat`: preparation automatique, variables locales a `setlocal` et propagation du code d'erreur de `pytest`.
- Aucune regle metier, route, ponderation, authentification, role, statut ou seed n'a ete modifie.

### Resultats

- Revision de `smart_faculty_test`: `20260705_0002`; 29 tables InnoDB.
- Trois suites consecutives sans reset intermediaire: `26 passed in 39.47s`, `26 passed in 40.89s`, `26 passed in 39.37s`.
- Controle d'ordre: `test_notes_resultats.py` seul `3 passed in 3.10s`; suite complete `26 passed in 39.73s`; fichier cible apres la suite `3 passed in 3.11s`.
- Apres tous les tests, `smart_faculty_test.evaluations` contient 0 ligne.
- `smart_faculty` existe toujours avec 29 tables. Aucune commande d'ecriture ne l'a ciblee.

Decision: les 26 tests historiques sont stables et reproductibles. Le Prompt 3A peut etre repris.

## Prompt 3A - Alignement de la connexion, des roles et des statuts

### Etat avant correction

- Reference obligatoire relancee: 26 tests historiques reussis, 0 echec, 0 erreur.
- La connexion verifiait deja le mot de passe bcrypt, le statut `actif`, le role possede en base, la signature et l'expiration JWT.
- Le refresh token etait deja aleatoire, hache en base, tourne a l'actualisation et revoque a la deconnexion.
- Le schema public limitait toutefois les roles a `etudiant`, `enseignant`, `appariteur`, `doyen`, `administrateur`.
- Flutter appliquait des alias injustifies: `icp` vers chef de promotion et `paritaire` vers appariteur; un role backend inconnu pouvait retomber sur le role local demande.
- `SessionService.connectAs` pouvait fabriquer une session locale sans reponse FastAPI, meme si cette methode n'etait appelee nulle part.

### Correction appliquee

- Roles fonctionnels FastAPI: `etudiant`, `enseignant`, `chef_promotion`, `surveillant`, `appariteur`, `doyen`, `vice_doyen`.
- `administrateur` reste technique et reserve; aucune route d'inscription ou d'approbation n'a ete creee.
- `icp` et `paritaire` sont conserves par le seed comme roles historiques, sans compte automatique ni acceptation publique.
- Le seed de test fournit des comptes actifs pour chef de promotion, surveillant et vice-doyen; le chef possede aussi `etudiant`, le vice-doyen aussi `enseignant`.
- Le seed n'affiche plus le mot de passe commun dans sa sortie standard.
- Flutter centralise les six conversions de ses espaces existants et utilise exclusivement le `role_actif` retourne et confirme dans `utilisateur.roles`.
- Flutter ne convertit plus `icp`, `paritaire`, `surveillant` ou `vice_doyen` vers un espace different. Les deux derniers restent connectables par FastAPI en attendant un espace Flutter dedie.
- La creation locale de session par role a ete retiree; `currentRole` est derive de l'utilisateur authentifie.

### Problemes infirmes

- Aucun mot de passe en clair n'est stocke par le backend actif.
- Aucun mot de passe ni hash n'est retourne par les schemas de reponse ou place dans le JWT.
- Seul le statut `actif` permet deja la connexion; aucun changement du modele de statuts n'etait necessaire.
- FastAPI verifiait deja le role actif en base a la connexion et sur chaque requete protegee.
- Les jetons expires, modifies, associes a un utilisateur supprime ou a un role retire etaient deja refuses.

### Tests

- Ajout de 15 cas collectes: trois roles fonctionnels, quatre statuts refuses, normalisation email, champs sensibles absents, refresh token hache, token expire, token modifie, utilisateur supprime, role retire et role Flutter falsifie.
- Suite officielle: 41 collectes, 41 reussis, 0 echec, 0 erreur, duree 57.83 s.
- `flutter analyze`: aucune erreur nouvelle; 6 informations historiques sur `dart:html`.
- `flutter test --reporter expanded`: lancement refuse par la limite d'usage de l'environnement Codex, sans resultat de test exploitable pour cette execution.

### Securite des donnees

- Tous les tests backend ont cible exclusivement `smart_faculty_test`.
- `smart_faculty` n'a recu aucune migration, aucun seed et aucune ecriture pendant le Prompt 3A.

Decision: le backend du Prompt 3A est valide avec 41/41 tests. La validation globale reste conditionnee a une nouvelle execution des tests Flutter lorsque l'environnement autorisera l'acces au SDK.

## Prompt 3A.1 - Communication reelle Flutter Web et FastAPI

### Cause exacte

- L'URL Flutter etait deja correcte: `http://127.0.0.1:8000` avec le prefixe unique `/api/v1`; la connexion cible bien `POST /api/v1/auth/connexion`.
- Aucune ancienne URL PHP, Flask, ni aucun port `8010` n'etait utilise par le frontend actif.
- FastAPI autorisait seulement `http://localhost:3000` et `http://localhost:5000`.
- Les prevols provenant de `http://localhost:52100` et `http://127.0.0.1:52100` repondaient `400 Disallowed CORS origin`.
- Le navigateur masquait alors la reponse au code Flutter. Le client recevait un echec de transport ou un statut `0`, ensuite transforme par le traitement generique en message `Serveur indisponible`.

### Correctif

- Ajout limite aux environnements configures des origines `http://localhost:52100` et `http://127.0.0.1:52100`; aucune origine globale `*` n'a ete ajoutee.
- Ajout d'erreurs de transport typees: serveur inaccessible, delai depasse et blocage CORS.
- Le client Web utilise un delai de 10 secondes. En cas d'erreur opaque du navigateur, un probe `fetch` en mode `no-cors` distingue un backend joignable mais bloque par CORS d'un serveur reellement inaccessible.
- Le client IO applique les memes delais et distingue les erreurs socket.
- Les reponses HTTP `401`, `403`, `422` et `500` conservent desormais leur code et leur message backend; une reponse JSON invalide reste identifiee separement.
- Aucun mot de passe ni jeton complet n'est journalise.

### Verification reelle

- `GET /`: HTTP 200.
- `GET /api/v1/statut`: HTTP 200.
- Prevol CORS depuis les deux origines `:52100`: HTTP 200 avec `Access-Control-Allow-Origin` exact.
- Connexion valide depuis l'origine Web: HTTP 200, `role_actif=etudiant`, access token et refresh token presents.
- Mauvais mot de passe: HTTP 401 avec le message backend, et non `Serveur indisponible`.
- Role non possede: HTTP 401 avec le message backend.
- Deconnexion reelle: HTTP 200.
- `flutter run -d chrome --web-port 52100` a bien ete relance, mais le processus de debogage Chrome est reste en attente de connexion dans l'environnement Codex; aucune erreur applicative ou CORS n'a ete observee apres correction.

### Tests finaux

- Backend officiel: 41 collectes, 41 reussis, 0 echec, 0 erreur, 24.90 s.
- Flutter: 12 tests reussis, 0 echec.
- `flutter analyze`: aucune erreur nouvelle; les 6 informations historiques liees a `dart:html` restent hors perimetre.
- Le test de JWT modifie a ete rendu deterministe en alterant le premier caractere de la signature Base64URL plutot que son dernier caractere de remplissage.

Decision: la communication HTTP Flutter-FastAPI, CORS, la classification des erreurs et les scenarios de connexion/deconnexion sont valides. Le Prompt 3B peut commencer apres une confirmation visuelle locale de la redirection dans la fenetre Chrome deja utilisee par le developpeur.

## Audit de reprise Copilot avant le Prompt 3C - 2026-07-11

### Sauvegarde et historique Git

- Branche active: `main`.
- Branche locale de securite creee: `sauvegarde-avant-audit-copilot`, pointee sur `2fd8e45`.
- Aucun push, reset, suppression de commit ou reecriture d'historique n'a ete effectue.
- Les commits recents sont `2fd8e45` (`ah pardon`), `a36c3a4` (checkpoint VS Code), `4724657` (`modification eeeh`) et `614751c` (`moi`).
- `shared_preferences` a ete ajoute dans `2fd8e45`, signe par l'auteur Git `Grace1026-bip`.
- `service_persistence.dart` a ete ajoute dans ce meme commit. Aucun commit distinct attribuable a Copilot n'est identifiable dans Git; Git permet de constater l'auteur du commit, pas l'outil qui a produit chaque ligne.
- Le dernier commit avant l'ajout de la persistance est anterieur a `2fd8e45` (`a36c3a4`/`4e52452`). Le resultat historique de 15 tests Flutter est consigne dans les rapports precedents, mais aucun commit ne permet d'en prouver seul la provenance exacte.

### Etat Copilot et correction

- Avant l'audit, les changements non committes concernaient `service_session.dart`, `pubspec.yaml`, `pubspec.lock` et le registrant macOS genere.
- `service_persistence.dart`, `shared_preferences`, ainsi que les premiers changements de `service_api.dart` et `service_api_test.dart`, etaient deja dans `HEAD`; ils n'ont donc pas ete restaures globalement.
- La cause de `Binding has not yet been initialized` etait l'appel asynchrone a `SharedPreferences.getInstance()` depuis `ApiService.configurerSession()` et `ApiService.viderSession()` pendant les tests, sans binding Flutter.
- La correction conserve `shared_preferences`, mais rend l'acces paresseux, injectable via `SessionStorage`, tolerant aux erreurs et sans appel plateforme a l'import. `SessionService.clear()` ne lance plus une seconde suppression concurrente.

### Authorization et persistance

- Le code de transport actuel construisait deja `Authorization: Bearer <access_token>`; aucune valeur litterale masquee n'est envoyee.
- Les tests verifient l'absence du header sans token, la valeur Bearer exacte avec des valeurs fictives, le remplacement apres refresh et l'absence de `******` dans la requete capturee.
- La persistance ne contient que `access_token`, `refresh_token` et `role_actif`. Aucun mot de passe n'est accepte par le contrat de stockage; les tests verifient aussi la suppression complete et les erreurs de lecture/ecriture.
- `shared_preferences` est un stockage de preferences, pas un coffre-fort. Ses valeurs sont plus exposees que dans Keychain/Keystore; le Web n'offre pas d'equivalent natif. Une evolution vers `flutter_secure_storage` sur mobile ou vers des cookies HttpOnly sur le Web devra etre decidee dans un prompt ulterieur coordonne avec le backend.

### Resultats de stabilisation

- `flutter pub get`: reussi.
- `flutter test --reporter expanded`: `18 passed`, `0 failed`, sans erreur de binding.
- `flutter analyze`: aucune erreur ni nouvelle alerte; les 6 informations historiques `dart:html` restent presentes.
- Backend: `scripts\\test_backend.bat` a cible `smart_faculty_test`; `57 passed`, `0 failed`. Aucun code backend ni aucune donnee de `smart_faculty` n'a ete modifie.

### Decision

L'etat Flutter est stable, l'en-tete Authorization est correct et la persistance minimale est testable sans dependance de mock supplementaire. Les changements Copilot sont acceptables apres cette reparation. Le Prompt 3C complet n'est pas termine; son volet 3C-A peut reprendre a partir de cet etat valide.

## Prompt 3C-A - Persistance et restauration de session Flutter - 2026-07-11

### Perimetre

Cette intervention a porte uniquement sur la sauvegarde apres connexion, la restauration au redemarrage, la verification de session par FastAPI, le nettoyage d'une session invalide et la navigation selon le role actif confirme. Aucun changement de theme, de couleur, de design, de backend ou de base `smart_faculty` n'a ete effectue.

### Implementation

- `ApiService.configurerSession` attend maintenant l'ecriture locale avant de terminer; `viderSession` attend la suppression des trois valeurs.
- `ApiAuthService.login` sauvegarde la session seulement apres validation de `role_actif` et de sa presence dans les roles retournes.
- `ApiAuthService.restoreSession` recharge les donnees persistantes, appelle `/auth/moi`, reconstruit l'utilisateur a partir du role backend confirme et laisse `SmartFacultyApp` ouvrir `AppRoutes.dashboardForRole`.
- Une session absente, incomplete ou refusee est effacee de la memoire et du stockage avant le retour a `AppRoutes.login`.
- Le bouton de deconnexion attend le nettoyage local avant de remplacer la route.

### Tests ajoutes

- restauration d'une session sauvegardee et verification de l'appel `/auth/moi`;
- navigation vers le tableau de bord correspondant au role confirme par l'API;
- suppression complete d'une session refusee;
- absence de session sans appel API;
- sauvegarde deterministe apres connexion et gestion des erreurs du stockage.

### Validation finale

- `flutter pub get`: reussi;
- `flutter analyze`: 0 erreur, 0 nouvelle alerte, 6 informations historiques `dart:html`;
- `flutter test --reporter expanded`: 22 passed, 0 echec;
- `scripts\\test_backend.bat`: 57 passed sur `smart_faculty_test`, revision Alembic `20260711_0003`;
- aucune donnee de `smart_faculty` modifiee.

Decision: le Prompt 3C-A est valide. Le Prompt 3C complet n'est pas declare termine; la prochaine intervention UI pourra traiter separement le theme beige et marron.

## Prompt UI-1 - Theme global beige et marron - 2026-07-12

### Audit initial

- Branche de travail creee et activee: `ui-theme-beige-marron`.
- Etat avant UI-1: 22 tests Flutter reussis, 57 tests backend reussis, authentification et session stables.
- L'ancien theme etait centralise, mais bleu: `#0B3D91`, `#2563EB`, fonds `#F3F7FC` / `#F8FAFC`, accents cyan et violet.
- Un seul fichier contenait les codes hexadecimaux: `couleurs_application.dart`; les ecrans consommaient majoritairement `AppColors`.
- Les blancs et transparences de la connexion et de la sidebar etaient des couleurs de contraste sur fond sombre, pas des palettes concurrentes.

### Correctif visuel

- Palette officielle beige/marron centralisee dans `couleurs_application.dart`.
- `ColorScheme` et `ThemeData` mis en coherence avec les surfaces creme, le marron profond et le terracotta.
- Ajout/configuration des themes AppBar, cartes, boutons, champs, icones, diviseurs, drawer, dialogues, SnackBar, progression, chips et tableaux.
- Connexion: fond creme, panneau marron, formulaire beige, focus terracotta, bouton marron, liens terracotta.
- Demande d'inscription: carte beige, bordures marron clair, champs et bouton alignes sur la connexion.
- Navigation laterale: fond marron profond, texte beige, selection claire et sorties preservees.
- Cyan et violet remplaces par des variantes desaturees uniquement pour les graphiques/categories; les couleurs semantiques de succes, avertissement et erreur restent distinctes.

### Verification visuelle

- `flutter build web --release`: reussi.
- `flutter run -d chrome` ne rendait pas le canvas dans l'environnement de debug, le canal Dart restant en attente; la build statique Web a donc ete servie localement.
- Connexion controlee en desktop 1280x720 et mobile 390x844.
- Demande d'inscription controlee en desktop et mobile.
- Aucun texte coupe, bouton inaccessible, debordement ou perte de contraste observe.

### Tests et securite fonctionnelle

- `flutter pub get`: reussi, sans `flutter upgrade` ni `flutter pub upgrade`.
- `flutter analyze`: aucune erreur ni nouvelle alerte; 6 informations historiques `dart:html`.
- `flutter test --reporter expanded`: 24 passed, 0 echec;
- `scripts\\test_backend.bat`: 57 passed sur `127.0.0.1:3307/smart_faculty_test`.
- Aucun backend, route, service fonctionnel, modele, API ou base `smart_faculty` n'a ete modifie.
- L'authentification et la persistance de session restent couvertes par les tests precedents.

Decision: le Prompt UI-1 est valide. Le theme beige et marron est applique et coherent sur les surfaces controlees. Les ajustements visuels plus fins des dashboards pourront etre traites ulterieurement sans remettre en cause la logique fonctionnelle.

## Correction CORS Flutter Web / FastAPI - 2026-07-12

### Diagnostic

- URL backend Flutter: `http://127.0.0.1:8000/api/v1`.
- Origine navigateur Flutter observee pour le test: `http://localhost:52100`; Flutter peut aussi utiliser `http://127.0.0.1:<port>` ou un port local dynamique.
- Ancienne configuration: liste de ports fixes, `allow_credentials=True`, `allow_methods=["*"]`, `allow_headers=["*"]`.
- Cause du blocage: une origine locale dynamique non presente dans `FRONTEND_ORIGINS` recevait `Disallowed CORS origin` lors du preflight `OPTIONS`.

### Correction appliquee

- `backend/app/main.py` utilise la regex locale uniquement pour `development`, `dev` et `test`: `^http://(localhost|127\\.0\\.0\\.1)(:\\d+)?$`.
- La production utilise toujours la liste explicite `parametres.frontend_origins`.
- Methodes autorisees: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS`.
- Headers autorises: `Authorization`, `Content-Type`, `Accept`.
- `allow_credentials=False`, car les jetons Smart Faculty ne sont pas des cookies inter-origines.
- Aucun wildcard d'origine, aucun secret et aucun middleware CORS concurrent n'ont ete ajoutes.

### Tests CORS ajoutes

- preflight localhost avec port `3000`;
- preflight `127.0.0.1` avec port dynamique;
- refus d'une origine externe;
- requete simple locale sans header credentials.

### Verification reelle

- `OPTIONS /api/v1/auth/connexion`: HTTP 200, `Access-Control-Allow-Origin: http://localhost:52100`;
- `POST /api/v1/auth/connexion`: HTTP 200;
- `GET /api/v1/auth/moi` avec Bearer: HTTP 200;
- identifiants invalides: HTTP 401 provenant de l'API, sans erreur navigateur CORS;
- origine externe: preflight refuse.

### Validation finale

- `scripts\\test_backend.bat`: `61 passed` sur `smart_faculty_test`;
- `flutter analyze`: aucune erreur ni nouvelle alerte, 6 informations historiques `dart:html`;
- `flutter test --reporter expanded`: `24 passed`;
- aucune logique d'authentification, écran, thème, route métier, migration ou base de données modifiee.

Decision: la correction CORS ciblée est valide. Flutter Web peut communiquer avec FastAPI sur les origines locales autorisees, tandis que la production conserve une liste explicite d'origines.

## Correction ciblee du diagnostic CORS Flutter Web - 2026-07-12

### Constat

Le backend repondait correctement depuis l'origine `http://localhost:52100`: preflight `OPTIONS 200`, connexion `POST 200`, verification `/auth/moi 200` et identifiants fictifs invalides `401`. Le message Flutter « connexion bloquee par CORS » etait donc trop generique pour conclure a un blocage CORS.

### Correction Flutter

- `service_api.dart` mappe les erreurs HTTP 401, 403, 422 et 500 vers des messages utilisateur distincts.
- Le timeout affiche `La connexion a expire.`.
- Une indisponibilite ou erreur reseau inattendue affiche `Le serveur FastAPI est inaccessible.`.
- Le message `Requete refusee par le navigateur.` est reserve au type de transport CORS emis apres un probe `no-cors` reussi vers la meme URL API.
- `client_api_web.dart` ne sonde plus la racine generique du serveur: il sonde l'URL API demandee, ce qui evite de conclure a tort a partir d'un endpoint different.
- L'ecran de connexion utilise le message utilisateur mappe par `ApiException`, sans afficher d'exception technique brute.

### Controle et limites

- Aucun changement de politique CORS pendant cette intervention.
- Aucun changement de logique d'authentification, role, session, backend, base de donnees ou theme.
- Aucun token, mot de passe ou corps sensible n'a ete affiche.
- `scripts\\test_backend.bat`: `61 passed` sur `smart_faculty_test` lors de la validation CORS.
- Derniere suite Flutter validee avant cette correction: `24 passed`, `flutter analyze` sans erreur ni nouvelle alerte et 6 informations historiques `dart:html`.
- La relance Flutter ciblee apres correction est restee bloquee avant toute sortie dans l'environnement local; le processus a ete arrete proprement et aucun echec de test n'a ete observe.

Decision: le diagnostic CORS est corrige cote Flutter et la configuration backend existante est confirmee fonctionnelle. Une nouvelle execution Flutter hors de cet etat d'environnement est necessaire pour clore la validation automatique de cette correction.

## Prompt 4A-R - Deblocage Flutter et socle Enseignant - 2026-07-12

### Deblocage de l'environnement

- Le depot est reste sur `ui-theme-beige-marron`; les changements anterieurs non valides n'ont pas ete ecrases.
- `flutter --version`: Flutter `3.41.9`, Dart `3.11.5`.
- Le blocage venait d'un `lockfile` orphelin dans le cache du SDK Flutter, alors qu'aucun processus Dart/Flutter ne tournait. Les deux verrous SDK ont ete supprimes avec une autorisation ciblee; Flutter n'a pas ete reinstalle ni mis a jour.
- `.dart_tool/` et `build/` du frontend ont ete nettoyes; `pubspec.lock` a ete conserve.
- `flutter pub get` a resolu les dependances, mais retourne un code non nul pour la creation de liens symboliques de plugins Windows, Developer Mode n'etant pas active. Les tests Dart et le build Web fonctionnent malgre cette restriction.

### Implementation backend

- Ajout de `backend/app/routes/enseignants.py`.
- Ajout de `backend/app/services/enseignants.py`.
- Inclusion du routeur dedie avant les routes academiques generiques afin que `/enseignants/moi` ne soit pas capture par `/enseignants/{enseignant_id}`.
- Les requetes utilisent le role actif enseignant, `Enseignant.utilisateur_id` et `CoursEnseignant.enseignant_id`.
- Le chargement SQLAlchemy des collections utilise `selectinload` pour eviter les doublons et les conflits de strategie.

### Implementation Flutter

- `EnseignantApiService` appelle uniquement les routes `/enseignants/moi` dans l'espace Enseignant.
- Ajout du profil enseignant distant en lecture seule.
- Dashboard recentre sur les cours et donnees disponibles; les statistiques fictives de notes et de risques ont ete retirees du socle.
- Ajout de l'etat vide explicite pour un enseignant sans cours.
- Les erreurs d'API utilisent les messages utilisateur existants, notamment acces refuse et serveur inaccessible.
- Aucun developpement complet de la Valve, des Notes ou des Presences.

### Tests

- Ajout de `backend/tests/test_enseignants.py`: autorisations, profil, multi-role, compte inactif, filtrage entre enseignants, detail, liste vide, donnees sensibles et coherence promotion/annee.
- Ajout de `frontend/test/enseignant_service_test.dart`: profil, liste vide et detail des routes dediees.
- Tests Flutter fichier par fichier: tous reussis.
- Suite Flutter complete avec concurrence minimale: `28 passed`, 0 echec.
- `flutter analyze`: 6 informations historiques `dart:html`, aucune nouvelle alerte.
- `flutter build web --release`: reussi.
- Suite backend officielle: `68 passed` lors de deux executions, uniquement sur `smart_faculty_test`.

### Verification manuelle et securite

- Connexion avec le compte enseignant de demonstration: dashboard ouvert sur `#/teacher`.
- Dashboard: 3 cours et 2 etudiants reels affiches.
- Navigation Mes cours, profil et deconnexion verifiees en desktop.
- Aucun `enseignant_id` libre n'est accepte par les nouvelles routes.
- Aucun token, mot de passe ou hash n'est retourne par le profil.
- Aucune migration, aucune ecriture de test dans `smart_faculty` et aucun changement de theme n'ont ete effectues.

Decision: le Prompt 4A-R est valide. Le socle Enseignant est fonctionnel, le profil est securise, les cours sont filtres par le backend et le projet est pret pour le Prompt 4B. La suite mobile reste a refaire dans un navigateur de verification qui accepte le viewport reduit; elle n'a revele aucun defaut de compilation ou de test.

## Prompt 4B - Valve Enseignant - 2026-07-12

### Audit et decision

Le depot possedait deja un module Valve actif: modele SQLAlchemy, routes FastAPI, service, tests de cycle, stockage de pieces jointes et ecran Flutter. Aucun doublon, aucune migration et aucune modification de la base principale n'ont donc ete introduits.

L'audit a releve deux ecarts fonctionnels. Le formulaire Flutter forcait `publier_maintenant=true` et ne permettait pas de publier un brouillon. De plus, le backend verifiait seulement l'affectation au cours pour les mutations, ce qui autorisait un collegue affecte au meme cours a modifier ou archiver une publication d'un autre auteur.

### Corrections

- `EnseignantApiService` transmet maintenant le choix brouillon ou publication immediate et expose la publication d'un brouillon;
- l'ecran Valve affiche l'action `Publier` seulement pour un brouillon dont l'utilisateur est auteur;
- le backend derive `auteur_id` du contexte authentifie et controle l'auteur pour modifier, publier, archiver et gerer les pieces jointes;
- `est_auteur` est retourne dans la liste enseignant pour aligner l'interface sur l'autorisation backend;
- les types de creation restent bornes par le schema et `publication_notes` est refuse dans le perimetre 4B;
- les donnees de Notes, evaluations, presences, reclamations et statistiques ne sont pas touchees.

### Tests et securite

Le test backend Valve couvre le brouillon, le type invalide, l'affectation d'un second enseignant au meme cours et le refus de ses mutations. La suite officielle a termine a `69 passed`. La suite Flutter a termine a `31 passed`, dont trois tests du service Valve. `flutter pub get` a resolu les dependances sans upgrade, `flutter analyze` conserve seulement les 6 informations historiques `dart:html`, et le build Web release est reussi.

Aucun mot de passe, token ou secret n'est ajoute dans les reponses ou les logs. La preparation backend utilise uniquement `smart_faculty_test`; aucune ecriture de `smart_faculty` n'a ete effectuee. Aucun commit ni push automatique n'a ete realise.

Decision: le Prompt 4B est techniquement valide sur les tests automatises. La Valve enseignant permet maintenant de creer, lister, modifier, publier et archiver dans le perimetre securise des cours affectes, avec mutations reservees a l'auteur. Les modules Notes et les autres valves fonctionnelles restent hors perimetre.

## Prompt 4C-A - Evaluations et saisie des notes - 2026-07-12

### Audit de l'existant

Les tables et routes Notes existaient deja, mais l'ecran enseignant actif restait partiellement visuel: il encodeait trois colonnes fixes et appelait des methodes Flutter qui levaient volontairement une exception car elles ne correspondaient plus aux routes Notes par evaluation. Le backend, lui, gerait deja le cycle brouillon, saisie, publication et verrouillage.

Les documents officiels imposent qu'un enseignant ne gere que ses cours attribues, qu'une note brouillon ne soit pas visible, qu'une note publiee soit protegee et que les resultats soient alimentes apres publication. Les types retenus depuis les donnees initiales sont `interrogation`, `travail_pratique`, `examen` et `autre`.

### Corrections realisees

- ajout de `GET /enseignant/types-evaluations` pour alimenter Flutter depuis les types actifs;
- ajout du type d'evaluation dans les reponses de liste et detail;
- verification de l'annee academique active et du statut academique actif dans le roster;
- restriction des mutations au createur de l'evaluation, y compris saisie, publication, archivage et verrouillage;
- verification transactionnelle de la somme des ponderations, plafonnee a 100 %;
- retour d'un roster minimal securise pour une evaluation;
- remplacement de l'ecran enseignant fixe par `TeacherEvaluationsScreen`, avec creation/modification, liste des evaluations, ponderation, saisie par evaluation, zero distinct d'une absence et lecture seule apres publication;
- correction du nom de champ Flutter `confirmer_notes_manquantes` attendu par FastAPI.

### Tests et limites

Les tests backend couvrent types, creation, titre vide, type absent, ponderations, modification, roster, confidentiality, note zero, note negative, note hors bareme, doublon, modification d'une note, et autre enseignant. La suite officielle est a `71 passed`. Flutter est a `34 passed`, dont trois tests Notes du service API. L'analyse conserve seulement les 6 informations historiques `dart:html`; le build Web release est reussi.

Aucune migration n'a ete creee. Les tests utilisent uniquement `smart_faculty_test`; aucune donnee de `smart_faculty` n'a ete modifiee. Aucun mot de passe, hash, token ou email d'etudiant n'est expose par le roster.

Le calcul de resultat et la notification declenches historiquement par la route de publication existaient avant 4C-A et n'ont pas ete etendus. Leur formalisation, la moyenne semestrielle/annuelle, les releves, les reclamations, l'affichage Etudiant complet et Campus Analytics sont reportes au Prompt 4C-B.

Decision: le socle Evaluations et saisie des notes est valide techniquement pour 4C-A. Le projet est pret pour une intervention 4C-B centree sur le calcul, la publication et les resultats, sous reserve de conserver ces limites.

## Prompt 4C-B1 - Calcul et publication des resultats d'un cours - 2026-07-12

### Audit

Le code actif calculait deja un `ResultatCours` lors de la publication d'une evaluation. Ce calcul historique produisait une valeur sur 100, mais ignorait une note manquante dans la contribution et renseignait aussi les credits et la reussite/echec. Ces effets ne sont pas etendus dans B1, car ils appartiennent au traitement global des resultats prevu en B2.

Les regles documentaires confirment qu'une absence ou une note manquante ne doit pas devenir automatiquement un zero. Le nouveau calcul distingue donc explicitement note zero, note absente et resultat incomplet.

### Implementation

- ajout de l'aperçu backend `GET /enseignant/cours/{cours_id}/resultats/apercu`;
- ajout de la publication backend `POST /enseignant/cours/{cours_id}/resultats/publier`;
- calcul Decimal sur 100, arrondi final a deux decimales;
- blocage si ponderation differente de 100 %, evaluation active en brouillon ou note manquante;
- filtrage par affectation enseignant, inscription active, annee active et statut etudiant actif;
- publication transactionnelle, dates renseignees, verrouillage des evaluations et comportement idempotent;
- annonce Valve `publication_notes` sans notes individuelles;
- aperçu Flutter avec etat, total ponderation, notes manquantes, resultats provisoires et confirmation de publication;
- lecture seule maintenue apres verrouillage.

### Tests et limites

Les tests B1 couvrent calcul mono/multi-evaluation, ponderation complete, note zero, note absente, arrondi, aperçu, refus cours etranger, refus autre role/enseignant, publication incomplete, publication complete, date/statut/verrouillage, idempotence et absence de notes individuelles dans la Valve. La suite backend complete est a `73 passed` et la suite Flutter a `35 passed`.

`flutter analyze` conserve seulement les 6 informations historiques `dart:html`; le build Web release est reussi. Les tests utilisent uniquement `smart_faculty_test`. Aucune migration, aucune modification de `smart_faculty`, aucun credit, aucune decision reussite/echec et aucune moyenne semestrielle ou annuelle n'ont ete ajoutes.

Decision: le Prompt 4C-B1 est valide techniquement pour le calcul a la demande et la publication/verrouillage des notes d'un cours. Le projet est pret pour le Prompt 4C-B2, qui devra traiter separement les resultats persistes, credits et decisions globales.

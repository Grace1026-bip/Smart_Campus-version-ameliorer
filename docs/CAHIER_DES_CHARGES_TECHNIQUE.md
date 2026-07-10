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

## Decision Prompt 2.7 - Isolation des tests backend

La base officielle reste exclusivement `smart_faculty_test` sur `127.0.0.1:3307`. Le script `backend/scripts/reinitialiser_base_test.py` refuse toute autre cible, recree ce schema, applique Alembic jusqu'a `20260705_0002` et charge uniquement le seed FastAPI actif. `scripts/test_backend.bat` est la commande officielle et propage le code de sortie de `pytest`.

La persistance observee provenait de deux causes combinees: les tests validaient de vraies transactions sans nettoyage, et le serveur creait les tables en MyISAM, moteur sans rollback. Pour la cible officielle de test uniquement, `backend/alembic/env.py` force maintenant InnoDB avant les migrations. La fixture autouse de `backend/tests/conftest.py` lie FastAPI et `SessionLocale` a une transaction externe par test, utilise des savepoints pour tolerer les `commit()` applicatifs, puis execute un rollback final.

Le seed actif cree les cours `BD201` et `WEB202`, mais ne cree aucune evaluation, note ou ponderation. Le fichier historique `backend/base_de_donnees/donnees_test.sql` n'est pas utilise par la suite FastAPI.

Validation sans reset entre executions:

- execution 1: 26 collectes, 26 reussis, 0 echec, 0 erreur, 39.47 s;
- execution 2: 26 collectes, 26 reussis, 0 echec, 0 erreur, 40.89 s;
- execution 3: 26 collectes, 26 reussis, 0 echec, 0 erreur, 39.37 s;
- ordre cible: 3 tests de notes reussis, 26 tests complets reussis, puis 3 tests de notes reussis.

La protection `_test` reste obligatoire. Aucune operation de preparation ou de nettoyage ne doit viser `smart_faculty`.

## Decision Prompt 3A - Connexion, roles et statuts

Les roles fonctionnels de connexion FastAPI sont `etudiant`, `enseignant`, `chef_promotion`, `surveillant`, `appariteur`, `doyen` et `vice_doyen`. Le role `administrateur` est conserve comme role technique reserve. `icp` et `paritaire` restent dans le referentiel historique, sans activation dans le schema public de connexion ni conversion Flutter.

Le role selectionne par Flutter est une demande de role actif. FastAPI charge les roles en base, refuse un role non possede, puis place le role verifie dans le JWT. Chaque requete authentifiee recharge l'utilisateur, exige le statut `actif` et verifie de nouveau que le role du jeton est encore possede. La suppression de l'utilisateur ou le retrait du role invalide donc un ancien access token.

Les statuts utilisateurs officiels restent ceux du modele SQLAlchemy et de la migration active: `en_attente`, `actif`, `bloque`, `rejete`, `archive`. Seul `actif` permet la connexion. Aucun statut `approuve` n'est ajoute; une future approbation fera passer `en_attente` a `actif`.

Flutter centralise les six conversions correspondant a ses espaces existants dans `modeles_faculte.dart`: `administrator/administrateur`, `apparitor/appariteur`, `student/etudiant`, `teacher/enseignant`, `promotionChief/chef_promotion`, `dean/doyen`. Le service utilise uniquement `role_actif` retourne par FastAPI et verifie sa presence dans les roles de l'utilisateur. `surveillant` et `vice_doyen` restent des roles backend valides sans etre assimiles localement a un espace plus privilegie.

La protection des mots de passe et jetons existante est conservee: bcrypt, absence de mot de passe ou hash dans les reponses et JWT, refresh token hache en base, signature et expiration JWT, rotation du refresh token et revocation a la deconnexion ou au changement de mot de passe.

Validation: 41 tests backend reussis, 0 echec, 0 erreur. L'analyse Flutter ne signale aucune erreur liee au Prompt 3A; les 6 informations historiques `dart:html` restent hors perimetre.

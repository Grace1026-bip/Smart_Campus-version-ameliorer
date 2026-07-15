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

## Decision Prompt 3B - Demandes d'inscription

Les demandes publiques d'inscription sont limitees a `etudiant` et `enseignant`. Les roles `administrateur`, `appariteur`, `doyen`, `vice_doyen`, `chef_promotion`, `surveillant`, `icp` et `paritaire` ne sont pas exposables publiquement.

Une demande possede ses propres statuts: `en_attente`, `approuvee`, `rejetee`. Ces statuts sont distincts des statuts de compte utilisateur (`en_attente`, `actif`, `bloque`, `rejete`, `archive`). Une demande approuvee cree un compte utilisateur `actif`.

Le modele actif est `backend/app/modeles/inscriptions.py`, table `demandes_inscription`. La migration non destructive est `backend/alembic/versions/20260711_0003_demandes_inscription.py`.

Routes retenues:

- `POST /api/v1/inscriptions/demandes`
- `GET /api/v1/inscriptions/demandes/statut`
- `GET /api/v1/inscriptions/demandes`
- `GET /api/v1/inscriptions/demandes/{id}`
- `POST /api/v1/inscriptions/demandes/{id}/approuver`
- `POST /api/v1/inscriptions/demandes/{id}/rejeter`

Autorites:

- `appariteur`: approuve ou rejette les demandes etudiant et enseignant.
- `chef_promotion`: approuve ou rejette uniquement les demandes etudiant de sa promotion lorsque son profil etudiant permet d'etablir ce perimetre.
- `doyen`: approuve ou rejette les demandes enseignant.
- `administrateur`: conserve comme role technique autorise.

Securite:

- Le mot de passe de la demande est hache immediatement avec le mecanisme existant.
- Aucune demande ne cree de session ni de jeton.
- Aucun mot de passe ni hash n'est retourne par l'API.
- L'approbation verifie le statut `en_attente`, les doublons, cree le compte, le profil et le role dans une transaction.
- `smart_faculty` n'a pas recu la migration de test; elle reste a la revision `20260705_0002`.

## Decision Prompt 3B.1 - Migration locale principale

La migration deja testee `20260711_0003_demandes_inscription.py` a ete appliquee sur la base locale principale `smart_faculty`.

Controle avant application:

- MySQL WAMP disponible sur `127.0.0.1:3307`.
- `smart_faculty`: revision `20260705_0002`, 29 tables, table `demandes_inscription` absente.
- `smart_faculty_test`: revision `20260711_0003`, 30 tables, table `demandes_inscription` presente.
- Migration relue: creation uniquement de `demandes_inscription`, de ses index et contraintes; aucune suppression, aucune modification des comptes existants.

Controle apres application:

- `smart_faculty`: revision `20260711_0003`.
- `smart_faculty`: 30 tables.
- `demandes_inscription`: 20 colonnes, contrainte unique `uq_demandes_inscription_reference`, index `email`, `statut`, `type_demande/statut`, et index de relations vers `promotions` et `utilisateurs`.
- Les utilisateurs et roles existants restent presents.
- Une demande de demonstration `demo.inscription.3b1@smartfaculty.test` a ete creee en `en_attente` pour verifier la route publique; elle n'a pas ete approuvee.

Tests apres migration:

- `scripts/test_backend.bat`: cible confirmee `smart_faculty_test`, 57 tests reussis en 66.10 s.
- Les tests Flutter n'ont pas pu etre relances pendant 3B.1 a cause de la limite d'execution de l'environnement; le dernier resultat valide du Prompt 3B reste `15 passed` et `flutter analyze` avec 6 infos historiques `dart:html`.

Performance:

- Le run backend precedent a 634.92 s semble exceptionnel: le run 3B.1 est revenu a 66.10 s avec la meme suite, ce qui indique probablement un ralentissement externe ponctuel autour de MySQL, du shell ou du poste, plutot qu'un test structurellement lent.

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

## Exigences techniques - Prompt UI-1

Le theme visuel global Flutter est centralise dans `frontend/lib/coeur/theme/couleurs_application.dart` et `frontend/lib/coeur/theme/theme_application.dart`. Les ecrans ne doivent pas redeclarer de palette generale ni multiplier les codes hexadecimaux.

Regles de repartition:

- `#FFFDF8` pour le fond general et `#FAF4EA` pour les surfaces et cartes;
- `#5D4037` pour les actions principales, AppBar et navigation profonde;
- `#795548` pour les actions secondaires et icones principales;
- `#C47A5A` pour les liens, le focus et les accents terracotta;
- `#2F2522` et `#6D625D` pour les textes;
- `#D8C8B8` pour les bordures;
- `#4F7A5A`, `#C48A2A` et `#B94A48` pour les etats succes, avertissement et erreur;
- `#E7DDD2` et `#9B8E87` pour les elements desactives.

Le `ThemeData` central configure `ColorScheme`, `AppBarTheme`, `CardThemeData`, `InputDecorationTheme`, boutons Material, `IconTheme`, `DividerTheme`, `DrawerTheme`, `DialogThemeData`, `SnackBarTheme`, `ProgressIndicatorTheme`, `ChipTheme` et `DataTableTheme`. Les couleurs de graphiques et de categories sont conservees uniquement lorsqu'elles ont une signification independante de la palette generale.

Le Prompt UI-1 couvre la connexion, la demande d'inscription, la navigation laterale et les composants partages sans modifier la structure des ecrans, les routes ou la logique metier. La build Web release a ete verifiee visuellement sur desktop et mobile. Validation: 24 tests Flutter reussis, 57 tests backend reussis sur `smart_faculty_test`, aucune nouvelle alerte d'analyse; les 6 informations historiques `dart:html` restent connues.

## Exigences techniques - Politique CORS Flutter Web / FastAPI

Le backend distingue les environnements locaux et la production. En `development`, `dev` ou `test`, `CORSMiddleware` utilise la regex locale `^http://(localhost|127\\.0\\.0\\.1)(:\\d+)?$`. Elle autorise uniquement HTTP, les deux hotes locaux et un port numerique optionnel. En production, seule la liste explicite `FRONTEND_ORIGINS` est utilisee.

La politique autorise explicitement les methodes `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS` et les headers `Authorization`, `Content-Type`, `Accept`. `allow_credentials=False` est obligatoire pour l'architecture actuelle, qui transporte les jetons dans les headers ou le JSON et n'utilise pas de cookies inter-origines. Aucun wildcard d'origine n'est utilise.

Le preflight d'une connexion doit retourner `Access-Control-Allow-Origin` egal a l'origine locale recue, ainsi que les methodes et headers autorises. Une origine externe doit etre refusee. Cette regle ne modifie ni l'authentification, ni les roles, ni les statuts, ni les routes metier.

Validation de la correction: 4 tests CORS ajoutes, suite backend `61 passed` sur `smart_faculty_test`, suite Flutter `24 passed`, preflight reel HTTP 200 depuis `http://localhost:52100`, connexion HTTP 200, `/auth/moi` HTTP 200, identifiants invalides HTTP 401. Aucune base de donnees n'a ete modifiee.

## Classification des erreurs reseau Flutter Web

Le client Flutter ne doit pas assimiler toute exception reseau a CORS. `ServiceApi` conserve le type de transport remonte par le client Web et mappe les statuts HTTP independamment:

- serveur inaccessible ou erreur reseau inattendue: `Le serveur FastAPI est inaccessible.`;
- timeout: `La connexion a expire.`;
- 401: `Identifiants incorrects.`;
- 403: compte non autorise ou acces refuse;
- 422: requete invalide;
- 500: erreur du serveur FastAPI;
- erreur CORS: `Requete refusee par le navigateur.` uniquement apres un echec XHR accompagne d'un probe `no-cors` reussi vers la meme URL API.

Le probe ne permet pas de lire la reponse et ne remplace pas l'appel authentifie; il sert uniquement a separer une origine joignable mais refusee par la politique du navigateur d'un serveur inaccessible. Les corps HTTP sont traduits en messages utilisateur sans afficher de token ou de mot de passe.

Le controle reel depuis `http://localhost:52100` vers `http://127.0.0.1:8000/api/v1/auth/connexion` a retourne `OPTIONS 200`, `POST 200`, `/auth/moi 200` et `401` pour des identifiants fictifs invalides. Aucun changement de politique CORS, d'authentification, de role, de base ou de theme n'est requis par ce correctif.

## Exigences techniques - Prompt 3C-A

La session Flutter repose sur trois valeurs minimales: `access_token`, `refresh_token` et `role_actif`. `SessionPersistenceService` utilise un stockage paresseux compatible avec `shared_preferences`; aucun appel a `SharedPreferences.getInstance()` n'est execute au chargement du module. Le stockage implemente le contrat injectable `SessionStorage` afin de tester la restauration et la suppression sans dependance de plateforme.

Le flux obligatoire est le suivant:

1. `ApiAuthService.login` valide la reponse de connexion, confirme que `role_actif` figure dans les roles de l'utilisateur, configure la session memoire et attend sa sauvegarde locale.
2. Au demarrage, `restoreSession` recharge les jetons, configure le client API et appelle `GET /api/v1/auth/moi`.
3. Le role de navigation est derive de la reponse backend verifiee, jamais d'un role local choisi arbitrairement.
4. Si les donnees sont absentes, incompletes, expirees ou refusees, la session memoire et les trois cles locales sont supprimees avant le retour a la connexion.
5. La deconnexion attend la suppression locale meme si l'appel backend echoue.

Les tests Flutter couvrent la sauvegarde apres connexion, la restauration valide, la verification `/auth/moi`, la suppression d'une session invalide, l'absence de session et la navigation selon le role confirme. Validation de l'etape: 22 tests Flutter reussis, 57 tests backend reussis sur `smart_faculty_test`, 0 erreur d'analyse et 6 informations historiques `dart:html`. Le theme, les couleurs et le design ne font pas partie de cette etape.

## Exigences techniques - Compte Enseignant 4A-R

Le socle Enseignant reutilise les modeles `Utilisateurs`, `Enseignants`, `Cours`, `CoursEnseignant`, `Promotions`, `Semestres` et `AnneeAcademique`. Aucune table ni migration n'est necessaire.

Routes dediees:

- `GET /api/v1/enseignants/moi`;
- `GET /api/v1/enseignants/moi/cours`;
- `GET /api/v1/enseignants/moi/cours/{cours_id}`.

Chaque route utilise `exiger_role("enseignant")`. Cette dependance valide le bearer token, le compte actif et le `role_actif` enseignant. La requete SQL retrouve ensuite le profil `Enseignant` par `utilisateur_id` et la liste par `CoursEnseignant`. Un cours non attribue retourne `404`; un autre role actif retourne `403`.

Le profil expose uniquement l'identite, l'email, le telephone, le matricule agent, le grade, le departement, le statut et les roles. Aucun mot de passe, hash, access token, refresh token ou secret n'est serialise.

Le frontend remplace les appels generiques `/cours` et `/cours/{id}` dans `EnseignantApiService`. Le dashboard affiche les cours, les etudiants inscrits, les publications et les reclamations lorsqu'elles sont disponibles. Le profil enseignant est consulte aupres de FastAPI en lecture seule. L'etat vide est distinct d'une erreur et n'invente aucune donnee.

Validation 4A-R:

- Flutter: `28 tests` reussis avec `--concurrency=1`;
- analyse: 6 informations historiques `dart:html`, aucune nouvelle erreur;
- build Web release reussi;
- backend: `68 tests` reussis lors de deux executions sur `smart_faculty_test`;
- responsive desktop controle; la tentative de capture mobile du navigateur de verification a expire sans impact sur le build.

## Exigences techniques - Prompt 4B Valve Enseignant

Le module Valve actif est reutilise. Le modele `PublicationValve` relie chaque publication a un `cours_id` et a l'utilisateur auteur, avec les statuts `brouillon`, `publiee` et `archivee`. Aucune table ni migration n'est necessaire pour ce prompt.

Les routes enseignant couvrent la liste, la creation, le detail, la modification, la publication et l'archivage sous `/api/v1/enseignant/valve`. Chaque route exige le role actif `enseignant`. Le cours est autorise par `CoursEnseignant`; l'auteur est derive du bearer token lors de la creation. La lecture d'un cours affecte est permise, mais modifier, publier, archiver ou gerer les pieces jointes d'une publication est reserve a son auteur. La reponse expose `est_auteur` pour que Flutter n'affiche pas d'action d'ecriture sur une publication d'un collegue.

Le schema Pydantic limite les types de publication a `annonce`, `communique`, `devoir`, `support_de_cours`, `changement_horaire`, `consigne_examen` et `rappel`. `publication_notes` demeure reserve au cycle Notes et n'est pas acceptable dans la creation Valve 4B. Les fonctions Notes, resultats, evaluations, presences, reclamations et statistiques ne sont pas implementees ou modifiees par ce prompt.

Flutter utilise `ValveApiService` et `EnseignantApiService`: le formulaire choisit entre publication immediate et brouillon, puis une carte permet de publier un brouillon de l'auteur. Les filtres et l'affichage des statuts reutilisent les donnees FastAPI normalisees. Le picker et les routes de pieces jointes existants sont conserves sans nouveau stockage ni encodage improvises.

Validation 4B: `scripts\\test_backend.bat` a retourne `69 passed` sur `smart_faculty_test`; `flutter pub get` a resolu les dependances; `flutter test --reporter expanded --concurrency=1` a retourne `31 passed`; `flutter analyze` ne signale aucune erreur et conserve uniquement les 6 informations historiques `dart:html`; `flutter build web --release` est reussi. Aucune donnee de `smart_faculty` n'a ete ecrite et aucun backend hors Valve n'a ete modifie.

## Exigences techniques - Prompt 4C-A Evaluations et Notes

Le schema actif contenait deja `TypeEvaluation`, `Evaluation`, `Note`, `InscriptionCours`, `Etudiant`, `Promotion`, `Cours` et `CoursEnseignant`. Aucune migration n'est necessaire. Les types de donnees initiales sont `interrogation`, `travail_pratique`, `examen` et `autre`; Flutter les charge via `GET /api/v1/enseignant/types-evaluations` au lieu d'envoyer un libelle arbitraire.

Routes enseignant utilisees:

- `GET /api/v1/enseignant/types-evaluations`;
- `GET` et `POST /api/v1/enseignant/cours/{cours_id}/evaluations`;
- `GET` et `PUT /api/v1/enseignant/evaluations/{evaluation_id}`;
- `GET` et `PUT /api/v1/enseignant/evaluations/{evaluation_id}/notes`;
- `POST /api/v1/enseignant/evaluations/{evaluation_id}/publier`;
- `POST /api/v1/enseignant/evaluations/{evaluation_id}/verrouiller`.

La dependance d'authentification impose un compte actif et le role actif `enseignant`. L'affectation `CoursEnseignant` est verifiee pour toute lecture ou ecriture. La creation determine `cree_par` depuis le contexte authentifie. Les mutations d'evaluation et de notes sont reservees a cet auteur; un autre enseignant affecte au meme cours peut consulter mais ne peut pas modifier. Les notes sont limitees a la liste des inscriptions actives de l'annee academique active et aux etudiants de statut academique actif. Les reponses de roster exposent uniquement identifiant, matricule, nom et promotion, sans email, mot de passe ni token.

La somme des ponderations non archivees est calculee côté backend et ne peut pas depasser 100 %. La verification verrouille les lignes d'evaluation du cours pendant la transaction. Les contraintes Pydantic et metier refusent titre/type/ponderation/note maximale invalides. La contrainte unique `evaluation_id + etudiant_id` et la mise a jour par couple evitent les doublons. Une note vide n'est pas envoyee par Flutter; une valeur `0` est envoyee explicitement et reste distincte d'une absence.

Flutter propose le choix du cours, la liste des evaluations, les types, les statuts, la ponderation utilisee/restante, la creation et modification d'un brouillon, la saisie par evaluation, les etats vide/chargement/erreur et la lecture seule apres publication/verrouillage. L'interface reste responsive par composants existants et ne modifie pas le theme.

Limites reportees au Prompt 4C-B: formalisation du calcul general des resultats semestriels, moyenne annuelle, decisions reussi/echoue, releves, affichage Etudiant complet, reclamations et Campus Analytics. La publication backend existante conserve ses effets historiques de calcul et notification; aucune nouvelle logique de resultats n'a ete ajoutee ici.

Validation 4C-A: `scripts\\test_backend.bat` a retourne `71 passed` sur `smart_faculty_test`; Flutter `34 passed`; `flutter analyze` conserve seulement les 6 informations historiques `dart:html`; `flutter build web --release` est reussi. Aucun schema n'a ete migre et `smart_faculty` n'a pas ete modifiee.

## Exigences techniques - Prompt 4C-B1 Calcul et publication des resultats d'un cours

Le calcul B1 reutilise `Evaluation`, `Note`, `InscriptionCours`, `Etudiant`, `CoursEnseignant` et `PublicationValve`. Aucun stockage de resultat supplementaire et aucune migration ne sont necessaires. L'aperçu n'est pas persiste: il est recalcule a la demande a partir des donnees actives.

Routes ajoutees:

- `GET /api/v1/enseignant/cours/{cours_id}/resultats/apercu`;
- `POST /api/v1/enseignant/cours/{cours_id}/resultats/publier`.

Les deux routes exigent un compte actif avec `role_actif=enseignant` et une affectation au cours. Aucun `enseignant_id`, `auteur_id` ou resultat fourni par Flutter n'est accepte. Le roster reprend uniquement les inscriptions actives de l'annee active et les etudiants academiquement actifs.

La formule retenue depuis le code actif est `contribution = note_obtenue / note_maximale * ponderation`, puis `resultat du cours = somme des contributions`, sur 100. Les calculs internes utilisent `Decimal`; aucune contribution n'est arrondie avant la somme et les valeurs exposees sont arrondies a deux decimales. Le zero est conserve; l'absence reste dans `notes_manquantes` et ne contribue pas comme zero.

L'aperçu expose l'etat `incomplet`, `publie` ou `verrouille`, la ponderation totale/restante, les contributions par evaluation, les notes manquantes et les resultats provisoires. Il n'expose ni credits, ni statut de reussite/echec, ni moyenne semestrielle ou annuelle. La publication est refusee si la ponderation n'est pas 100 %, si une evaluation active reste en brouillon ou si une note manque.

La publication verrouille les lignes d'evaluation du cours, revalide l'aperçu dans la transaction, publie les evaluations, renseigne leur date, active `est_verrouillee` et cree une annonce Valve de type `publication_notes` sans note individuelle. Une seconde publication retourne l'etat verrouille sans creer de doublon. La modification des notes reste bloquee par le verrouillage existant.

Le calcul historique de `ResultatCours`, des credits et de la reussite/echec existe encore dans l'ancien flux de publication d'une evaluation; il n'est pas utilise par le nouvel aperçu B1 et n'a pas ete etendu. Sa formalisation appartient au Prompt 4C-B2.

Validation B1: `scripts\\test_backend.bat` a retourne `73 passed` sur `smart_faculty_test`; les tests Flutter sont a `35 passed`; `flutter analyze` conserve uniquement les 6 informations historiques `dart:html`; `flutter build web --release` est reussi. Aucun schema n'a ete migre et `smart_faculty` n'a pas ete modifiee.

## Exigences techniques - Prompt 4C-B2A Consolidation academique semestrielle

### Audit et source de verite

Les documents officiels confirment le calcul automatique des moyennes et credits, le seuil de reussite d'un cours a 50/100 et l'acquisition des credits uniquement lorsqu'un cours est reussi. Ils ne definissent pas de formule semestrielle ponderee par credits, de compensation, de rattrapage ou de decision officielle. Le code actif utilisait une moyenne simple des `ResultatCours`; cette formule est conservee provisoirement et documentee comme une limite a confirmer.

Le moteur B2A reutilise le modele actif `ResultatCours` et le service central `calcul_academique`. La publication d'un cours B1 persiste maintenant le resultat de chaque inscription active apres publication et verrouillage des evaluations. Le service `resultats_academiques.py` ne recalcule pas les notes brutes: il consomme les resultats publies, verifies par les evaluations verrouillees. Aucune seconde table de consolidation et aucune migration ne sont necessaires.

### Consolidation et completude

La consolidation est calculee a la demande pour l'annee academique active. Tous les cours actifs du semestre appartenant a la promotion de l'etudiant sont consideres comme les cours du programme, car le modele actuel ne porte pas de drapeau obligatoire ni d'unites d'enseignement. L'etudiant doit etre actif, sa promotion active et chaque cours doit avoir une inscription active dans la meme annee.

Un cours est exploitable seulement lorsque ses evaluations actives sont publiees et verrouillees et que son `ResultatCours` porte le statut `reussi` ou `echoue`. Les etats exposes sont `incomplet` et `provisoire`. Les blocages retournes sont notamment `resultat_non_publie`, `inscription_cours_invalide`, `credits_incoherents`, `cours_manquant` et `annee_academique_incoherente`. Un cours echoue ne bloque pas la completude: il reste `non_acquis` et ses credits acquis sont zero. Une note zero reste donc un resultat valide et peut conduire a un cours non acquis.

### Formule, credits et precision

La formule actuelle est `moyenne_semestre = somme(resultats_cours) / nombre_de_resultats_cours`, sur 100. Les valeurs internes utilisent `Decimal`; l'arrondi a deux decimales intervient seulement a l'exposition. Cette moyenne simple est un choix de compatibilite avec le code actif, pas une confirmation d'une future ponderation par credits. Les credits prevus sont la somme des credits des cours du semestre, les credits acquis la somme des credits des cours `reussi`, et les credits non acquis la difference. Le seuil de 50/100 est applique au resultat de cours deja publie; aucune compensation n'est appliquee.

### Roles et API

Les routes sont:

- `GET /api/v1/resultats/etudiants` pour la selection securisee des etudiants par les responsables;
- `GET /api/v1/resultats/etudiants/{etudiant_id}/semestres`;
- `GET /api/v1/resultats/etudiants/{etudiant_id}/semestres/{semestre_id}/apercu`;
- `GET /api/v1/resultats/mes-semestres`;
- `GET /api/v1/resultats/mes-semestres/{semestre_id}/apercu`.

L'etudiant ne voit que son propre identifiant academique. Les roles autorises pour la consultation responsable sont `appariteur`, `doyen` et `administrateur`. Le role actif est valide par le backend a partir du token; Flutter ne peut pas imposer une promotion, une annee ou un role. L'enseignant reste responsable de ses resultats de cours, mais ne valide pas un semestre.

La reponse contient l'etudiant concerne, l'annee, le semestre, les cours, les resultats publies, les credits, la moyenne provisoire, l'etat, les raisons de blocage et `decision_provisoire=en_attente_de_validation` lorsque les donnees sont completes. `decision_officielle=false` et `publie_a_etudiant=false` signalent explicitement les limites de B2A. Aucune decision `admis`, `ajourne` ou `echec` semestriel n'est inventee.

### Flutter et limites reportees

`AcademicResultsScreen` permet a l'etudiant et aux responsables autorises de choisir la periode disponible et de consulter un apercu responsive. Il distingue chargement, aucun etudiant, aucun semestre, incomplet, provisoire et erreur. Il n'affiche pas de releve officiel. La moyenne annuelle, la validation administrative, la deliberation, la publication officielle aux etudiants, les reclamations de resultat, le PDF, la compensation et le rattrapage sont reportes au Prompt 4C-B2B.

Validation B2A: `97 passed` sur `smart_faculty_test` lors de deux executions; `36 passed` Flutter lors de deux executions avec `--concurrency=1`; `flutter analyze` retourne uniquement les 6 informations historiques `dart:html`; `flutter build web --release` reussi. Les tests B2A couvrent moyenne mono et multi-cours, Decimal et arrondi, note zero, absence de resultat, brouillon/non-verrouille, credits, seuil 50, autre annee/semestre, inscription, acces etudiant/responsable, role falsifie, absence de donnees sensibles, idempotence et absence de decision arbitraire. Aucune migration et aucune ecriture dans `smart_faculty`.

## Audit Prompt 4C-B2B - Validation administrative et publication officielle

### Regles confirmees

La lecture de `docs/01_Analyse/01.07 - Regles metier.docx` confirme uniquement qu'un cours est reussi lorsque sa moyenne est superieure ou egale a 50 % et que ses credits sont valides uniquement lorsqu'il est reussi. `docs/01_Analyse/01.04 - Cas d'utilisation.docx` indique que l'enseignant publie les resultats de ses cours, que l'appariteur valide certaines inscriptions et que le doyen consulte les notes publiees.

### Ambiguites bloquantes

Les documents ne confirment pas la formule de moyenne semestrielle, le seuil de validation d'un semestre, le role habilite a valider un semestre, le role habilite a publier officiellement, la compensation, le rattrapage, la seconde session, la correction apres validation ni la publication officielle aux etudiants. Une phrase generale sur la supervision du doyen ne constitue pas une autorisation explicite de validation semestrielle.

### Audit du modele actif

Le modele `ResultatCours` contient uniquement la moyenne du cours, les credits obtenus, le statut `en_attente/reussi/echoue` et la date de calcul. Il ne contient pas le statut administratif, la moyenne snapshot, les credits snapshot, le validateur, la date de validation, le responsable de publication, la date de publication, le motif de correction ou la version de formule. `JournalAudit` permet une trace technique, mais ne remplace pas un snapshot officiel. Les migrations actives ne proposent aucune table de validation semestrielle.

### Decision technique

La validation administrative, le verrouillage officiel, la demande de correction et la publication officielle ont ete volontairement arretes avant modification. Les implementer exigerait d'inventer une regle ou un role, ce que la source documentaire interdit. Aucune route B2B, aucun statut officiel, aucune migration et aucune modification du backend n'ont ete ajoutes. Le moteur B2A reste provisoire et continue de signaler `en_attente_de_validation`.

Les preconditions B2A ont ete verifiees avant cet audit: backend `97 passed`, Flutter `36 passed`, analyse Flutter avec uniquement les 6 informations historiques `dart:html`, et endpoints FastAPI `/` et `/api/v1/statut` operationnels. Le fichier `.vscode/settings.json` conserve sa modification preexistante et n'a pas ete touche.

Pour reprendre B2B, la documentation doit d'abord confirmer explicitement la formule semestrielle, le seuil semestriel, le validateur, le responsable de publication et les transitions de correction. Une migration non destructive pourra alors etre etudiee sur `smart_faculty_test` uniquement.

## Regles academiques LMD appliquees par Smart Faculty

Les decisions LMD du projet sont formalisees dans `docs/REGLES_LMD_RDC.md`.
Elles s'appuient sur le Decret n°22/39 du 8 decembre 2022, les arretes
ministeriels n°093/MINESU/CAB.MIN/MNB/RMM/2023 et
n°401/MINESU/CABMIN/MNB/RMM/MKK/2023, ainsi que l'Instruction academique n°027
pour l'annee 2025-2026.

Le moteur conserve la valeur historique des cours sur 100 et calcule la valeur
officielle sur 20 par division par 5. La moyenne semestrielle est ponderee par
les credits avec `Decimal`; le seuil est 10/20, un semestre normal vaut 30
credits et une annee 60 credits. Les decisions finales sont `ADM`, `COMP`,
`DEF` et `AJ`.

Le `Cours` actuel est traite comme une UE autonome pour le MVP. Le jury est la
seule autorite de decision: le doyen ou vice-doyen organise la session, le
president enregistre les decisions et l'appariteur assure les operations
administratives et la publication d'une session deja cloturee. La cloture
genere un snapshot officiel versionne et immuable; toute correction conserve
l'historique et passe par une nouvelle deliberation.

La progression annuelle complete, la seconde session et la decomposition
EC-UE-BCC restent reportees a une evolution ulterieure.

## Projets et encadrements - regle fonctionnelle

L'appariteur attribue les enseignants encadreurs en fonction du type de projet.
L'enseignant consulte les etudiants et projets qui lui sont attribues.
L'etudiant consultera les enseignants qui encadrent son projet dans un module
ulterieur. Le MVP accepte les types `reseaux`, `systemes_embarques`,
`intelligence_artificielle` et `genie_logiciel`, avec validation backend.

Le modele actif est minimal: un projet reference un etudiant, une promotion,
une annee et un type; plusieurs encadrements actifs sont possibles, sans
doublon enseignant-projet. L'enseignant ne consulte que les encadrements
derives de son token via `/api/v1/enseignants/moi/encadrements`. L'attribution,
la messagerie, les fichiers, les reunions, l'evaluation et la note de projet
sont hors perimetre. La reference detaillee est
`docs/PROJETS_ENCADREMENTS_MVP.md`.

### Implementation Prompt 4C-B2B-RDC

La migration `20260713_0004` cree de maniere additive `sessions_deliberation`,
`membres_jury`, `decisions_jury` et `resultats_semestre_officiels`. Les
decisions sont enregistrees par le president affecte et present; la cloture
recalcule la grille et cree les snapshots dans une transaction. La publication
est reservee a l'appariteur, au doyen et au vice-doyen apres cloture.

Les routes actives sont sous `/api/v1/deliberations` et la consultation
etudiante officielle sous `/api/v1/resultats/mes-semestres/{semestre_id}/officiel`.
Les membres enseignants peuvent consulter leur session; un enseignant non
membre, un etudiant tiers et un role falsifie sont refuses par le backend.

La correction apres cloture cree une nouvelle version avec motif obligatoire et
conserve l'ancienne version. Les tests utilisent toujours `smart_faculty_test`.
La validation finale du prompt a donne 107 tests backend reussis, 37 tests
Flutter reussis, 0 erreur d'analyse et un build Web release reussi.

## Prompt 4D - Encadrements de projets

Le modele MVP `ProjetAcademique` represente un projet rattache a un etudiant,
une promotion, une annee academique, un titre, un type controle et un statut.
`EncadrementProjet` permet plusieurs encadreurs actifs et interdit le doublon
actif d'un meme enseignant sur un projet. La migration `20260713_0005` est
additive et se teste uniquement sur `smart_faculty_test`.

Le backend derive l'enseignant actif du token et filtre toutes les lectures
par cette identite. Les routes de consultation sont
`/api/v1/enseignants/moi/encadrements` et
`/api/v1/enseignants/moi/encadrements/{encadrement_id}`. Flutter expose
`Mes encadrements` avec liste, detail, etats de chargement, vide, erreur,
acces refuse et session expiree.

La suite de validation 4D compte `120 passed` backend et `39 passed` Flutter,
avec deux executions de chaque suite, analyse Flutter sans erreur et build
Web release reussi. L'attribution par appariteur et la vue etudiante des
encadreurs sont reservees aux modules suivants.

## Prompt 5A - Enrolements academiques appariteur

L'enrolement academique est une operation distincte de la demande d'inscription
d'un compte et de l'inscription pedagogique a un cours. Pour le MVP, il relie
un etudiant actif, une promotion et une annee academique, puis conserve une
fiche administrative avec reference, dates, statut et auteur des operations.
Le programme affiche est derive des cours actifs de la promotion; aucune
inscription de cours n'est creee automatiquement.

Le modele `EnrolementAcademique` est porte par la table
`enrolements_academiques`, introduite par la migration additive
`20260713_0006`. Les statuts controles sont `en_attente`, `valide` et
`annule`. Une contrainte logique et une cle unique nullable interdisent deux
enrolements actifs pour le meme triplet etudiant-promotion-annee, tout en
conservant les enrolements annules. La reference de fiche est unique.

Le backend expose les routes appariteur sous
`/api/v1/appariteur/enrolements`. L'utilisateur appariteur est derive du
token, le compte doit etre actif et le role actif doit etre `appariteur`.
Les validations controlent l'existence des references, l'appartenance de
l'etudiant a la promotion, la coherence de l'annee et les transitions de
statut. La modification des references sensibles est interdite apres
validation ou annulation. La fiche MVP fournit des donnees structurees, sans
PDF.

Flutter utilise le service API appariteur et l'ecran `Enrolements` avec liste,
filtres, creation, detail, validation et annulation. Les etats de chargement,
liste vide, erreur reseau, acces refuse et session expiree sont traites. Le
theme et les regles des modules existants ne sont pas modifies.

La migration a ete appliquee sur `smart_faculty_test`, verifiee par downgrade
vers `20260713_0005` puis upgrade vers `20260713_0006`. La base principale
`smart_faculty` reste a `20260713_0005` et n'a recu aucune donnee de test.
L'attribution des encadreurs, les paiements, les notes, les presences, le PDF
et la consultation etudiante sont reportes aux modules suivants.

Validation: deux suites backend a `128 passed`, deux suites Flutter a
`42 passed`, analyse Dart avec 0 erreur et 0 avertissement, 6 informations
historiques `dart:html`, build Web release reussi. Les endpoints FastAPI `/`,
`/api/v1/statut` et `/api/v1/sante/base-de-donnees` repondent correctement.

## Prompt 5B - Gestion appariteur des projets et encadrements

La migration `20260713_0006` a ete deployee sur `smart_faculty` apres une
sauvegarde complete. L'etat avant migration etait `20260713_0005`, avec 36
tables et sans table d'enrolement; l'etat apres est `20260713_0006`, avec 37
tables et une table `enrolements_academiques` vide. Les compteurs des tables
existantes sont restes inchanges.

Le modele `ProjetAcademique` est reutilise. La creation appariteur exige un
etudiant actif, une promotion coherente, une annee derivee de cette promotion
et un `EnrolementAcademique` valide. Un seul projet non archive est autorise
pour un etudiant et une annee. La modification ne peut pas changer librement
l'etudiant, la promotion ou l'annee; le changement de type est refuse si un
encadreur actif n'a pas la nouvelle specialite.

Le modele `SpecialiteEncadrementEnseignant`, ajoute par `20260713_0007`, porte
les domaines explicitement configures par l'appariteur. Les specialites sont
controlees par le meme referentiel que les projets et leur desactivation garde
la ligne historique. La migration ajoute aussi
`desactive_par_utilisateur_id` a `EncadrementProjet`.

Les routes appariteur sont:

- `GET/POST /api/v1/appariteur/projets`;
- `GET/PATCH /api/v1/appariteur/projets/{projet_id}`;
- `POST /api/v1/appariteur/projets/{projet_id}/archiver`;
- `GET /api/v1/appariteur/enseignants-encadreurs`;
- `GET/PUT /api/v1/appariteur/enseignants-encadreurs/{enseignant_id}/specialites`;
- `POST /api/v1/appariteur/projets/{projet_id}/encadrements`;
- `PATCH /api/v1/appariteur/projets/{projet_id}/encadrements/{encadrement_id}`;
- `POST /api/v1/appariteur/projets/{projet_id}/encadrements/{encadrement_id}/desactiver`.

Un seul encadreur principal actif est autorise. Plusieurs co-encadreurs sont
possibles. Le remplacement du principal est une action explicite; l'ancien
encadrement devient inactif et reste consultable dans l'historique. La base
utilise la valeur historique `coencadreur`; l'API et Flutter utilisent
`co_encadreur`.

La migration `20260713_0007` a ete verifiee par downgrade vers `0006` puis
upgrade vers `0007` sur `smart_faculty_test`. Elle n'a pas ete appliquee a
`smart_faculty` dans ce prompt. Les tests automatises n'utilisent que la base
suffixee `_test`.

Flutter expose l'ecran Appariteur `Projets et encadrements`, avec filtres,
creation, detail, configuration des specialites, attribution compatible,
remplacement, desactivation et archivage. Les enseignants continuent de
consulter uniquement leurs encadrements par leur token. La consultation
Etudiant et les fonctions de projet avancees sont reportees.

Validation finale: `134 passed` backend lors de chacune des deux executions
completes et `44 passed` Flutter lors de chacune des deux executions completes.
`flutter analyze` ne signale aucune erreur ni avertissement; les 14 informations
restantes correspondent aux 6 informations historiques `dart:html` et a 8
recommandations de style deja presentes dans l'ancien ecran de supervision.
`flutter build web --release` est reussi. FastAPI repond HTTP 200 sur `/`,
`/api/v1/statut` et `/api/v1/sante/base-de-donnees`. `smart_faculty` reste en
`20260713_0006`; `20260713_0007` est validee uniquement sur
`smart_faculty_test` et son deploiement principal est reporte a une operation
controlee separee.

## Prompt 5C - Espace Etudiant

Le module etudiant utilise le profil associe au token et impose le role actif
`etudiant`. Les routes `/api/v1/etudiants/moi/enrolements` et
`/api/v1/etudiants/moi/projets` ne prennent aucun identifiant d'etudiant
comme autorite. Les details refusent un identifiant appartenant a un autre
profil par une reponse introuvable.

Une fiche officielle est disponible uniquement pour un enrolement `valide`.
`GET /api/v1/etudiants/moi/enrolements/{id}/fiche` genere un PDF A4 en
memoire avec ReportLab `4.2.5`, ajoute `Content-Type: application/pdf`,
`Content-Disposition: attachment` et `Cache-Control: private, no-store`.
Le document contient la reference, l'etudiant, la promotion, l'annee, les
dates, le statut, le programme, les credits et le pied de page; il ne contient
aucun secret, paiement, note ou chemin local.

Le client Flutter fournit `ApiService.getBytes`, qui conserve le Bearer token
et reutilise le rafraichissement de session. L'implementation Web utilise un
import conditionnel et un telechargement par Blob; les plateformes sans
integration de partage de fichier affichent un retour explicite sans
persistance serveur. Les ecrans `Mon enrolement` et `Mon projet` reutilisent
le theme et la navigation existants.

Les projets etudiants sont filtres par le profil du token et excluent les
projets archives ainsi que les encadrements inactifs. Seuls le titre, le type,
la description autorisee, le statut, la promotion, l'annee et les encadreurs
actifs sont exposes. L'etudiant n'accede ni a l'historique interne ni aux
actions d'attribution.

Validation 5C: backend `141 passed` lors de chacune des deux executions, dont
7 tests dedies; Flutter `47 passed` lors de chacune des deux executions;
`flutter analyze` conserve 14 informations connues sans erreur ni
avertissement; le PDF de test A4 de 5 187 octets a ete rendu sur deux pages
sans chevauchement; build Web release reussi. Les health checks FastAPI `/`,
`/api/v1/statut` et `/api/v1/sante/base-de-donnees` repondent HTTP 200.

## Prompt 6A - Regles de l'espace Etudiant academique

L'identite Etudiant est derivee du token et le compte doit etre actif. Le
backend est l'autorite du perimetre: un Etudiant ne consulte que ses
`InscriptionCours` actives, sa promotion, un cours actif et l'annee active.
`EnrolementAcademique` reste le dossier administratif annuel; la convention
MVP utilise les inscriptions de cours actives pour le perimetre courant.

Les routes sont `GET /api/v1/etudiants/moi/tableau-de-bord`,
`GET /api/v1/etudiants/moi/cours`, `GET /api/v1/etudiants/moi/cours/{id}`,
`GET /api/v1/etudiants/moi/cours/{id}/notes` et
`GET /api/v1/etudiants/moi/historique-academique`. Valve et notes reutilisent
leurs routes Etudiant existantes; brouillons, archives, evaluations non
publiees et champs internes restent masques. Les resultats semestriels
officiels viennent des snapshots de deliberation publies.

Flutter propose `Mes cours`, `Valve`, `Mes notes`, `Mes resultats`,
`Historique`, `Mon enrolement`, `Mon projet`, `Profil` et la deconnexion. Le
dashboard signale l'absence d'inscription active et n'affiche aucun calcul
academique invente. Aucune migration ni dependance n'a ete ajoutee.

## Prompt 7A - Presences academiques et controle d'acces - 2026-07-14

Le modele historique `Presence` (`presences`) reste utilise par le suivi des
risques et n'est pas supprime. Le socle de presence par cours est porte par
`SeanceAcademique` et `PresenceAcademique`, introduits par la migration additive
`20260714_0008`.

Une seance conserve le cours, la promotion, l'annee, le semestre, les horaires
configurables, le type `cours_1`/`cours_2`/`autre`, son statut et les acteurs
d'ouverture et de fermeture. Une presence conserve le statut, la methode
manuelle par matricule, le motif de refus et le pourcentage de paiement observe.
La contrainte `(seance_id, etudiant_id)` garantit une seule presence par
etudiant et par seance.

Le service central verifie compte actif, enrôlement `valide`, promotion
coherente, inscription active ou validee au cours, seance ouverte et paiement
administratif superieur ou egal a 50 %. Le champ
`EnrolementAcademique.pourcentage_paiement` est lu par le controle ; aucun
paiement en ligne n'est implemente et le module Presence ne peut pas le
modifier.

Le role actif `surveillant` ouvre et ferme les seances et traite le controle
manuel. Le chef de promotion agit sur la promotion de son profil Etudiant et
peut confirmer une seance `cours_2` ouverte. Les actions sont tracees dans
`JournalAudit`. Flutter expose `Controle d acces` et `Cours 2` sans camera
simulee. Les routes et limites sont detaillees dans
`docs/PRESENCES_ACADEMIQUES_MVP.md`.

Validation Prompt 7A : migration downgrade/upgrade reussie sur
`smart_faculty_test`, deux suites backend a `152 passed`, suite Flutter a `56
passed`, analyse Flutter sans erreur ni avertissement avec 14 informations
historiques. La base `smart_faculty` et `.vscode/settings.json` restent hors
perimetre.

## Prompt 7B - Consultation, absences et corrections

La fermeture d'une `SeanceAcademique` genere les absences manquantes des
etudiants actifs, enroles et inscrits au cours. L'operation est idempotente et
ne remplace jamais un statut `present`, `retard` ou `refuse`. Le resume de
seance et le taux de presence sont calcules dans le backend.

Les routes de consultation utilisent exclusivement l'identite issue du token :
Etudiant pour ses propres presences, Enseignant pour ses cours affectes et
Chef de promotion pour sa promotion. Les champs financiers restent reserves
au controle Surveillant et ne sont pas exposes dans les vues pedagogiques.

Une correction de statut exige un motif et un role `surveillant` ou
`appariteur`. La table additive `corrections_presences_academiques`, creee par
`20260715_0009`, conserve l'ancienne valeur, la nouvelle valeur, la
justification, l'auteur et la date ; `JournalAudit` est egalement alimente.
La migration 0009 est appliquee uniquement a `smart_faculty_test` pendant ce
prompt.

## Prompt 7C-A - Fondation biometrique

La capture camera Flutter utilise le plugin officiel `camera` et un composant
partage qui gere permissions, cycle de vie, changement de camera et captures
multiples. Les images sont transmises en multipart a FastAPI pour validation.
Le backend ne conserve pas les images originales et ne recoit pas de token,
de mot de passe ou d'encodage fourni par le client.

Les tables `profils_biometriques` et `encodages_faciaux` sont ajoutees par la
migration additive `20260715_0010_fondation_biometrique`. Le profil actif,
le consentement, la version du moteur, le seuil, la revocation et l'historique
sont separes des encodages binaires. Un reenrolement revoque l'ancien profil
et conserve sa trace. Le moteur facial est une dependance optionnelle
injectable ; aucune reconnaissance reelle n'est simulee lorsque le moteur
n'est pas installe.

Les routes d'enrolement sont reservees a l'Appariteur. La reconnaissance en
seance est reservee au Surveillant et reutilise le service central de controle
Presence. Un candidat inconnu ou ambigu est refuse, la contrainte d'unicite
de presence reste active, et les champs financiers ne sont pas exposes dans
la reponse biometrique.

La migration 0010 a ete verifiee par downgrade/upgrade sur
`smart_faculty_test`; `smart_faculty` est restee en 0009 sans donnees
biometriques. La validation compte 174 tests backend et 62 tests Flutter
reussis lors de deux executions completes, sans erreur d'analyse Flutter, et
un build Web release reussi. L'anti-spoofing et la vivacite renforcee sont
hors perimetre et reportes au Prompt 7C-B.

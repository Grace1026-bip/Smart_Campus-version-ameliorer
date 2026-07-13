# Smart Faculty

Smart Faculty est une application de gestion academique pour une faculte. Le projet couvre les comptes et parcours administrateur, etudiant, enseignant, appariteur, doyen et chef de promotion, avec des modules comme les notes, la valve academique, les reclamations, les notifications, les etudiants a risque et les tableaux de bord.

## Technologies officielles

- Frontend: Flutter
- Backend: Python avec FastAPI
- Base de donnees: MySQL

Les anciennes versions PHP et Flask sont archivees dans `legacy/` et ne font plus partie de l'architecture officielle.

## Structure du projet

```text
Smart_Campus/
  frontend/      Application Flutter
  backend/       API FastAPI, migrations Alembic, tests backend
  docs/          Documentation officielle et memoire projet
  legacy/        Anciennes implementations archivees
  scripts/       Scripts de lancement et maintenance
```

## Documentation

- Documents d'admission: `docs/00_Admission`
- Analyse: `docs/01_Analyse`
- Conception: `docs/02_Conception`
- Cahier technique: `docs/CAHIER_DES_CHARGES_TECHNIQUE.md`
- Journal de developpement: `docs/JOURNAL_DE_DEVELOPPEMENT.md`
- Anciennes references techniques: `docs/references_techniques`
- Regles LMD RDC: `docs/REGLES_LMD_RDC.md`
- Projets et encadrements MVP: `docs/PROJETS_ENCADREMENTS_MVP.md`

## Regles academiques LMD appliquees par Smart Faculty

Le moteur de deliberation suit les regles LMD RDC documentees dans
`docs/REGLES_LMD_RDC.md`: seuil d'acquisition 10/20 (50/100 en valeur source),
moyenne semestrielle ponderee par les credits, 30 credits par semestre,
decisions de jury `ADM`, `COMP`, `DEF` et `AJ`, et publication uniquement apres
cloture d'un jury. Le champ historique `ResultatCours.moyenne` reste sur 100;
la deliberation le convertit vers 20 sans modifier la source.

La migration additive `20260713_0004` ajoute les sessions de deliberation,
membres de jury, decisions et snapshots officiels. Elle a ete verifiee par
upgrade et downgrade sur `smart_faculty_test` uniquement. La derniere
validation a retourne 107 tests backend et 37 tests Flutter reussis; le build
Web release est egalement valide.

## Encadrements enseignant

Le module enseignant consulte ses projets et etudiants encadres via les routes
`/api/v1/enseignants/moi/encadrements`. Les types de projet sont controles par
le backend. L'attribution par l'appariteur et la consultation des encadreurs
par l'etudiant restent reservees aux prochains modules. Voir
`docs/PROJETS_ENCADREMENTS_MVP.md`.

## Configuration backend

Depuis `backend/`:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Configurer ensuite `backend/.env` avec les informations locales MySQL. Ne pas versionner ce fichier.

Le fichier `backend/.env.example` reste un modele sans secret reel.

## Configuration des tests backend

Les tests backend doivent utiliser une base MySQL separee nommee:

```text
smart_faculty_test
```

Un modele sans secret est disponible:

```text
backend/.env.test.example
```

La configuration actuelle du backend lit les variables `MYSQL_*` depuis l'environnement ou depuis `.env` / `backend/.env`. La commande officielle force `APP_ENV=test` et `MYSQL_DATABASE=smart_faculty_test`, verifie la cible exacte, recree la base de test, applique les migrations et le seed actif, puis lance `pytest`.

Commande SQL a executer dans MySQL Workbench si la base de test n'existe pas encore:

```sql
CREATE DATABASE IF NOT EXISTS smart_faculty_test
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
```

Depuis la racine, lancer:

```powershell
.\scripts\test_backend.bat
```

Le script refuse toute remise a zero si la cible n'est pas exactement `127.0.0.1:3307/smart_faculty_test` ou si son nom ne finit pas par `_test`. Ne jamais lancer `pytest` sur `smart_faculty`.

Pendant les migrations de cette cible de test uniquement, Alembic force InnoDB. Chaque test utilise ensuite une transaction externe et des savepoints SQLAlchemy; les `commit()` de l'application restent visibles pendant le scenario, puis toutes ses ecritures sont annulees automatiquement a la fin du test.

Apres une preparation officielle, une relance directe sans remise a zero est possible depuis `backend/`:

```powershell
$env:APP_ENV = "test"
$env:MYSQL_DATABASE = "smart_faculty_test"
.\.venv\Scripts\python.exe -m pytest -v
```

## Lancer FastAPI

Depuis la racine:

```powershell
.\scripts\demarrer_backend.bat
```

Commande equivalente depuis `backend/`:

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Documentation interactive:

```text
http://127.0.0.1:8000/docs
```

## Configuration frontend

Depuis `frontend/`:

```powershell
flutter pub get
```

L'API par defaut attendue est:

```text
http://127.0.0.1:8000/api/v1
```

## Lancer Flutter

Depuis la racine:

```powershell
.\scripts\demarrer_frontend.bat
```

Commande equivalente depuis `frontend/`:

```powershell
flutter run -d chrome --web-port 3000
```

## Tests

Analyse Flutter:

```powershell
cd frontend
flutter analyze
```

Tests Flutter:

```powershell
cd frontend
flutter test
```

Tests backend:

```powershell
.\scripts\test_backend.bat
```

Important: les tests backend refusent de tourner sur la base principale. Configurer une base MySQL separee dont le nom finit par `_test`, par exemple `smart_faculty_test`, avant d'executer `pytest`.

## Diagnostic Flutter connu

Sur cette machine, `where flutter` et `where dart` detectent le SDK dans `C:\Users\gisel\Downloads\flutter\bin`. Dans un environnement sandbox strict, les commandes Flutter peuvent rester silencieuses si le SDK ne peut pas ecrire dans `flutter\bin\cache`. Dans ce cas, fermer les processus Flutter/Dart restants, verifier les fichiers `flutter.bat.lock` et `lockfile`, puis relancer les commandes avec un acces autorise au cache SDK.

## Archives

- `legacy/php`: anciens modules PHP et ancien script de lancement PHP.
- `legacy/flask`: ancien point d'entree Flask.
- `legacy/autres`: anciens elements racine ou experimentaux qui ne font pas partie de l'architecture officielle.
## Architecture backend active

Le backend actif est le backend FastAPI situe dans `backend/app`.

- Point d'entree officiel: `backend/app/main.py`.
- Connexion SQLAlchemy officielle: `backend/app/base_de_donnees/connexion.py`.
- Base declarative SQLAlchemy: `backend/app/base_de_donnees/base.py`.
- Configuration: `backend/app/configuration/`.
- Modeles SQLAlchemy: `backend/app/modeles/`.
- Schemas Pydantic: `backend/app/schemas/`.
- Routes FastAPI: `backend/app/routes/`.
- Services metier: `backend/app/services/`.
- Migrations Alembic: `backend/alembic/versions/`.
- Scripts SQL historiques ou de reference: `backend/base_de_donnees/`.
- Scripts Python d'exploitation: `backend/scripts/`.
- Tests backend: `backend/tests/`.

Le dossier actif de connexion n'est pas `bdd`; le reliquat vide `backend/app/bdd/connexion.py` a ete retire apres verification qu'aucun import, script ou test ne l'utilisait.

## Resultat de stabilisation backend

Verification realisee avec MySQL WAMP sur `127.0.0.1:3307`.

- Base principale detectee: `smart_faculty`.
- Base de test officielle: `smart_faculty_test`.
- Sauvegarde locale de `smart_faculty`: creee dans `backend/sauvegardes/`, dossier ignore par Git.
- Migrations Alembic appliquees sur `smart_faculty_test`: revision `20260705_0002`.
- Donnees initiales de test: recreees par la commande officielle, sans evaluations ni notes concurrentes avec les tests.
- Isolation: tables de test InnoDB, transaction externe et rollback automatique par test.
- Reproductibilite: trois suites consecutives sans reset intermediaire ont chacune obtenu `26 passed`.
- Controle d'ordre: `test_notes_resultats.py` seul (`3 passed`), suite complete (`26 passed`), puis fichier cible (`3 passed`).

La base principale `smart_faculty` reste la base normale de developpement. Les tests doivent continuer a utiliser uniquement une base dont le nom finit par `_test`.

## Demandes d'inscription

Le processus d'inscription public est limite aux roles `etudiant` et `enseignant`.

Routes principales:

```text
POST /api/v1/inscriptions/demandes
GET  /api/v1/inscriptions/demandes/statut
GET  /api/v1/inscriptions/demandes
GET  /api/v1/inscriptions/demandes/{id}
POST /api/v1/inscriptions/demandes/{id}/approuver
POST /api/v1/inscriptions/demandes/{id}/rejeter
```

Regles:

- Une demande publique ne cree aucune session et ne retourne aucun jeton.
- Le mot de passe est hache immediatement; aucun mot de passe ni hash n'est retourne.
- Une demande utilise les statuts `en_attente`, `approuvee`, `rejetee`.
- Une approbation cree un compte `actif`, le profil correspondant et le role autorise.
- Les demandes etudiant sont approuvables par `appariteur` ou par `chef_promotion` dans son perimetre.
- Les demandes enseignant sont approuvables par `appariteur` ou `doyen`.
- Les roles privilegies ne sont pas disponibles dans le formulaire public Flutter.

Migration de test associee:

```text
20260711_0003_demandes_inscription.py
```

### Migration locale principale

La migration `20260711_0003` a ete appliquee sur la base locale principale `smart_faculty` apres sauvegarde complete dans `backend/sauvegardes/`.

Commande utilisee depuis `backend/`:

```powershell
.\.venv\Scripts\python.exe -m alembic upgrade head
```

Etat apres migration:

- `smart_faculty`: revision `20260711_0003`.
- Nouvelle table principale: `demandes_inscription`.
- Les tests backend restent executes uniquement sur `smart_faculty_test` via `scripts/test_backend.bat`.
- Une demande de demonstration locale peut etre supprimee avec une requete SQL ciblee sur son email de test, par exemple `demo.inscription.3b1@smartfaculty.test`.

## Authentification, roles et statuts

La connexion FastAPI accepte les roles fonctionnels `etudiant`, `enseignant`, `chef_promotion`, `surveillant`, `appariteur`, `doyen` et `vice_doyen`. `administrateur` reste un role technique reserve. Les roles historiques `icp` et `paritaire` sont conserves dans le referentiel, mais ne sont pas acceptes par le schema public de connexion.

Un utilisateur peut posseder plusieurs roles. Flutter demande un role actif, puis FastAPI verifie en base que l'utilisateur le possede avant de creer les jetons. Le role actif du backend est la seule source utilisee par Flutter pour ouvrir un espace; aucune session ne peut etre fabriquee localement.

Correspondances des espaces Flutter actuellement disponibles:

- `administrator` -> `administrateur`;
- `apparitor` -> `appariteur`;
- `student` -> `etudiant`;
- `teacher` -> `enseignant`;
- `promotionChief` -> `chef_promotion`;
- `dean` -> `doyen`.

`surveillant` et `vice_doyen` sont pris en charge par FastAPI, mais ne sont pas assimiles a un autre espace Flutter tant qu'un espace fonctionnel dedie n'existe pas. Les statuts officiels sont `en_attente`, `actif`, `bloque`, `rejete` et `archive`; seul `actif` autorise la connexion.

Validation Prompt 3A: 41 tests backend reussis, dont les 26 historiques et 15 cas supplementaires collectes. `flutter analyze` ne remonte aucune erreur nouvelle et conserve les 6 informations historiques relatives a `dart:html`.

## Persistance de session Flutter - Prompt 3C-A

Apres une connexion FastAPI reussie, Flutter sauvegarde uniquement `access_token`, `refresh_token` et `role_actif` via `SessionPersistenceService`. Au redemarrage, le frontend recharge ces valeurs sans appel plateforme a l'import, verifie la session avec `GET /api/v1/auth/moi`, puis ouvre le tableau de bord correspondant au `role_actif` confirme par FastAPI.

Une session absente, incomplete ou invalide est supprimee localement et l'application revient a la connexion. Le stockage est injectable pour les tests et les erreurs de preferences ne bloquent pas la session memoire. Le nettoyage de deconnexion est attendu jusqu'a la suppression locale complete.

Validation Prompt 3C-A:

- `flutter pub get`: reussi.
- `flutter analyze`: 0 erreur, 0 nouvelle alerte, 6 informations historiques liees a `dart:html`.
- `flutter test --reporter expanded`: 22 tests reussis.
- `scripts\\test_backend.bat`: 57 tests backend reussis sur `smart_faculty_test`.

Le theme, les couleurs et le design restent hors perimetre de cette validation et seront traites dans une intervention UI separee.

## Theme global beige et marron - Prompt UI-1

Le theme Flutter central est defini dans `frontend/lib/coeur/theme/couleurs_application.dart` et `frontend/lib/coeur/theme/theme_application.dart`.

Palette officielle appliquee:

- marron principal: `#5D4037`;
- marron secondaire: `#795548`;
- beige principal: `#F5EFE6`;
- fond creme: `#FFFDF8`;
- surface: `#FAF4EA`;
- terracotta: `#C47A5A`;
- texte principal: `#2F2522`;
- texte secondaire: `#6D625D`;
- bordure: `#D8C8B8`;
- succes: `#4F7A5A`;
- avertissement: `#C48A2A`;
- erreur: `#B94A48`;
- desactive: `#E7DDD2` / `#9B8E87`.

Le `ThemeData` configure le `ColorScheme`, AppBar, cartes, boutons, champs, icones, diviseurs, drawer, dialogues, SnackBar, indicateurs, chips et tableaux. La connexion, la demande d'inscription et la navigation laterale utilisent le meme langage visuel. Les couleurs cyan/violet sont conservees sous une forme desaturee uniquement pour les categories et graphiques qui portent une information distincte.

Validation UI-1:

- reference avant: 22 tests Flutter reussis;
- resultat final: 24 tests Flutter reussis, dont 3 tests de theme;
- `flutter analyze`: aucune erreur ni nouvelle alerte, 6 informations historiques liees a `dart:html`;
- build Web release: reussie;
- verification visuelle: connexion et demande d'inscription controlees en desktop et mobile, sans debordement;
- backend: 57 tests reussis sur `smart_faculty_test`.

Aucune logique d'authentification, route, API, service backend ou base de donnees n'a ete modifiee. Les ajustements de couleurs restent centralises et le travail UI des autres ecrans repose sur les memes aliases `AppColors`.

## Politique CORS Flutter Web / FastAPI

En developpement et en test, FastAPI autorise uniquement les origines HTTP locales correspondant a `localhost` ou `127.0.0.1`, avec ou sans port: `^http://(localhost|127\\.0\\.0\\.1)(:\\d+)?$`. Cela couvre le port conseille `3000` et les ports dynamiques de Flutter Web sans ouvrir les origines externes.

La configuration locale autorise explicitement `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS` et les headers `Authorization`, `Content-Type`, `Accept`. `allow_credentials` est desactive, car Smart Faculty utilise des access/refresh tokens et non des cookies inter-origines. En production, la regex locale n'est pas utilisee: la configuration revient a la liste explicite `FRONTEND_ORIGINS`.

Validation CORS:

- preflight `OPTIONS` depuis `http://localhost:52100`: HTTP 200, origine retournee exactement;
- connexion Flutter/API: HTTP 200;
- route protegee `/api/v1/auth/moi` avec Bearer: HTTP 200;
- identifiants invalides: HTTP 401 transmis par l'API, avec CORS present;
- origine externe: preflight refuse;
- suite backend: 61 tests reussis, dont 4 tests CORS;
- suite Flutter: 24 tests reussis.

Aucun secret, role, statut, route metier, migration ou donnee de `smart_faculty` n'a ete modifie.

## Diagnostic des erreurs reseau Flutter Web

Le message de connexion ne declare plus automatiquement une erreur CORS pour toute erreur reseau. Le client Web distingue maintenant:

- serveur FastAPI inaccessible: `Le serveur FastAPI est inaccessible.`;
- delai depasse: `La connexion a expire.`;
- HTTP 401: `Identifiants incorrects.`;
- HTTP 403: compte non autorise ou acces refuse;
- HTTP 422: requete invalide;
- HTTP 500: erreur du serveur FastAPI;
- refus verifiable par le navigateur: `Requete refusee par le navigateur.`.

Une erreur XHR opaque est classee CORS uniquement lorsque le probe `fetch` en mode `no-cors` confirme que l'origine API est joignable. Un `ClientException` ou une erreur inattendue est conserve comme indisponibilite du serveur et n'est plus presente comme CORS par defaut.

Verification reelle depuis `http://localhost:52100` vers `http://127.0.0.1:8000/api/v1/auth/connexion`:

- `OPTIONS`: HTTP 200, origine autorisee retournee;
- `POST`: HTTP 200;
- `/auth/moi`: HTTP 200;
- identifiants invalides: HTTP 401 avec les headers CORS presents;
- aucun secret ni corps sensible n'est affiche dans les logs ou le rapport.

La politique CORS n'a pas ete modifiee pendant ce diagnostic. Les tests backend restent a `61 passed`; la derniere suite Flutter validee avant cette correction comptait `24 passed`. Le test Flutter cible lance apres correction est reste bloque avant toute sortie dans l'environnement local, sans echec de test exploitable.

## Compte Enseignant - Prompt 4A-R

Le compte Enseignant utilise maintenant des routes dediees et securisees par le role actif confirme dans le JWT:

- `GET /api/v1/enseignants/moi` pour le profil professionnel;
- `GET /api/v1/enseignants/moi/cours` pour les cours attribues;
- `GET /api/v1/enseignants/moi/cours/{cours_id}` pour le detail d'un cours attribue.

Le backend determine l'enseignant depuis l'utilisateur courant et filtre directement par `CoursEnseignant`. Flutter ne fournit aucun `enseignant_id` d'autorite et ne recupere plus la liste generale `/cours` dans l'espace Enseignant. Les reponses de profil excluent mot de passe, hash, tokens et secrets.

Le frontend couvre le dashboard, le profil enseignant en lecture, les cours, le detail, le chargement, les erreurs d'autorisation, la session expiree et l'etat vide `Aucun cours ne vous est actuellement attribue.`. La Valve, les Notes et les Presences restent hors du socle 4A.

Validation 4A-R:

- Flutter: `28 tests reussis`, 0 echec;
- `flutter analyze`: 6 informations historiques `dart:html`, aucune nouvelle alerte;
- `flutter build web --release`: reussi;
- backend: `68 tests reussis` lors de chacune des deux executions officielles;
- build Web controle en desktop: connexion enseignant, dashboard, Mes cours, profil et deconnexion verifies.

## Valve Enseignant - Prompt 4B

Le Prompt 4B reutilise le module Valve existant (`PublicationValve`, ses routes et son stockage de pieces jointes). Il couvre uniquement les publications liees aux cours attribues a l'enseignant:

- creation d'une publication en brouillon ou publication immediate;
- consultation des publications des cours affectes;
- modification, publication et archivage par leur auteur;
- types autorises: annonce, communique, devoir, support, changement horaire, consigne d'examen et rappel;
- rejet backend des types arbitraires et de `publication_notes`, reserve au module Notes;
- affichage Flutter des statuts brouillon, publiee et archivee, avec action de publication d'un brouillon.

Le backend determine le cours depuis l'affectation de l'utilisateur courant et ne recoit jamais un auteur libre fourni par Flutter. Les publications des collegues restent consultables dans le perimetre du cours, mais leurs mutations sont refusees. Les pieces jointes restent limitees aux extensions et a la taille deja configurees; aucune nouvelle strategie de stockage n'a ete ajoutee.

Validation 4B:

- backend: `69 tests reussis` sur `smart_faculty_test`;
- Flutter: `31 tests reussis`, dont 3 tests du service Valve;
- `flutter pub get`: dependances resolues sans upgrade;
- `flutter analyze`: 0 erreur et 6 informations historiques `dart:html`;
- `flutter build web --release`: reussi;
- aucune migration, aucune modification de `smart_faculty`, aucun changement Notes, evaluations, presences ou theme.

## Evaluations et saisie des notes - Prompt 4C-A

Le module Notes reutilise les tables actives `types_evaluations`, `evaluations`, `notes`, `inscriptions_cours`, `etudiants`, `promotions` et `cours_enseignants`. Les types fournis par les donnees initiales sont `interrogation`, `travail_pratique`, `examen` et `autre`.

Le workflow enseignant est limite au cours affecte et au role actif `enseignant`:

- liste et creation d'evaluations en brouillon;
- note maximale et ponderation strictement positives;
- somme des ponderations actives limitee a 100 %, verifiee par le backend avec verrouillage transactionnel;
- modification et saisie des notes reservees au createur de l'evaluation;
- roster limite aux inscriptions actives de l'annee active et aux etudiants academiquement actifs;
- note zero conservee comme une saisie, champ vide conserve comme absence;
- publication et verrouillage distincts de la saisie brouillon.

Flutter utilise `TeacherEvaluationsScreen`, `NotesApiService` et les routes Notes existantes. Les resultats finaux, la moyenne annuelle, les releves, les reclamations, l'affichage Etudiant complet et Campus Analytics restent reportes au Prompt 4C-B. Le calcul historique declenche par la publication backend n'a pas ete etendu dans ce prompt.

Validation 4C-A: backend `71 passed` sur `smart_faculty_test`, Flutter `34 passed`, `flutter analyze` sans erreur avec 6 informations historiques `dart:html`, build Web release reussi. Aucune migration n'a ete creee et `smart_faculty` n'a pas ete utilisee par les tests.

## Calcul et publication des resultats d'un cours - Prompt 4C-B1

Le calcul B1 est realise a la demande par FastAPI via `GET /api/v1/enseignant/cours/{cours_id}/resultats/apercu`. La formule est celle deja active dans le projet: `note_obtenue / note_maximale * ponderation`, additionnee sur une echelle de 100. Les valeurs sont calculees en Decimal et arrondies a deux decimales uniquement au resultat et aux contributions affichees.

Une note manquante n'est jamais convertie en zero. Une note zero reste une note saisie. Un cours est `incomplet` si une evaluation active est en brouillon, si la ponderation totale n'est pas 100 % ou si un etudiant inscrit n'a pas toutes ses notes. L'aperçu fournit les contributions, le resultat provisoire, les notes manquantes et le resultat officiel uniquement lorsque les conditions sont remplies.

La publication explicite `POST /api/v1/enseignant/cours/{cours_id}/resultats/publier` verrouille la transaction, publie les evaluations actives, enregistre leur date et les verrouille. Elle est idempotente apres publication. Une annonce Valve `publication_notes` est creee sans inclure de notes individuelles. Les credits, decisions de reussite/echec, moyennes semestrielles et annuelles restent hors perimetre.

Validation B1: backend `73 passed` sur `smart_faculty_test`, tests Flutter `35 passed`, analyse sans erreur avec 6 informations historiques `dart:html`, build Web release reussi. Aucune migration et aucune ecriture dans `smart_faculty`.

## Consolidation academique semestrielle - Prompt 4C-B2A

Le moteur semestriel consomme les `ResultatCours` publies et verrouilles par le cycle B1. Il ne relit pas les notes brutes dans un second calcul. Lorsqu'un cours est publie par le workflow B1, son resultat est centralise dans `ResultatCours` avec le seuil documentaire de 50/100.

La moyenne semestrielle est actuellement une moyenne simple des resultats de cours publies, sur 100, avec calcul interne en `Decimal` et arrondi final a deux decimales. Les documents ne definissent pas encore une ponderation semestrielle par credits, une compensation ou une deliberation; le resultat reste donc provisoire. Les credits prevus sont la somme des credits des cours actifs du programme. Les credits acquis sont ceux des cours `reussi`; les credits non acquis correspondent a la difference.

La consolidation est calculee a la demande. Elle exige l'etudiant actif, sa promotion et son inscription active dans l'annee courante, les cours actifs du semestre, les evaluations publiees et verrouillees et un `ResultatCours` valide pour chaque cours. Un resultat absent, brouillon, non verrouille ou incoherent rend le semestre incomplet. Un cours echoue reste calculable, mais n'acquiert aucun credit.

Routes ajoutees:

- `GET /api/v1/resultats/etudiants/{etudiant_id}/semestres`;
- `GET /api/v1/resultats/etudiants/{etudiant_id}/semestres/{semestre_id}/apercu`;
- `GET /api/v1/resultats/mes-semestres`;
- `GET /api/v1/resultats/mes-semestres/{semestre_id}/apercu`.

Un etudiant ne peut consulter que ses propres resultats. Les roles `appariteur`, `doyen` et `administrateur` peuvent consulter un apercu dans le perimetre backend. Aucun enseignant ne valide un semestre. Flutter utilise `AcademicResultsScreen` avec les etats chargement, incomplet, provisoire, credits, blocages et erreur; l'interface affiche `Resultat provisoire - non encore valide officiellement`.

Validation B2A: backend `97 passed` lors de deux executions officielles sur `smart_faculty_test`; Flutter `36 passed` lors de deux executions avec concurrence minimale; `flutter analyze` conserve seulement les 6 informations historiques `dart:html`; build Web release reussi. Aucune migration, aucune modification de `smart_faculty`, aucune publication officielle, aucun PDF et aucune decision `admis` ou `ajourne` n'ont ete ajoutes.

## Audit Prompt 4C-B2B - Validation officielle

L'audit B2B a ete execute sans modification fonctionnelle. Les documents `01.07 - Regles metier.docx` confirment le seuil d'un cours a 50/100 et l'acquisition des credits lorsqu'un cours est reussi. `01.04 - Cas d'utilisation.docx` attribue a l'enseignant la publication des resultats de ses cours, a l'appariteur la validation de certaines inscriptions et au doyen la consultation des notes publiees, mais aucun document ne designe explicitement le validateur d'un semestre ni le responsable de sa publication officielle.

Les documents ne confirment pas non plus la formule semestrielle, le seuil de validation du semestre, la compensation, le rattrapage, la correction apres validation ou la publication officielle aux etudiants. Le modele actif `ResultatCours` ne contient pas de statut administratif, snapshot, validateur, date de validation, responsable de publication ou date de publication; `JournalAudit` ne suffit pas a stocker ces donnees.

Decision: la validation administrative, la demande de correction et la publication officielle sont bloquees jusqu'a confirmation ecrite de ces regles. Aucun second workflow, aucune migration, aucune ecriture dans `smart_faculty` et aucun changement du fichier `.vscode/settings.json` preexistant n'ont ete effectues.

## Prompt 4D - Encadrements enseignant

Le MVP des encadrements est disponible dans l'espace Enseignant via
`Mes encadrements`. L'appariteur attribue les encadreurs par type de projet;
l'enseignant consulte uniquement les projets et etudiants derives de son
token. Les types controles sont `reseaux`, `systemes_embarques`,
`intelligence_artificielle` et `genie_logiciel`.

La migration additive `20260713_0005` ajoute les tables des projets et des
encadrements, sans supprimer de structure existante. Elle a ete testee par
downgrade et upgrade sur `smart_faculty_test`; `smart_faculty` n'a pas ete
migree. Les routes de lecture sont `GET /api/v1/enseignants/moi/encadrements`
et `GET /api/v1/enseignants/moi/encadrements/{encadrement_id}`.

Validation 4D: `120 passed` backend lors de deux executions, `39 passed`
Flutter lors de deux executions, analyse Flutter sans erreur avec 6
informations historiques et build Web release reussi. L'attribution
appariteur et la consultation etudiante des encadreurs sont reportees.

## Prompt 5A - Enrolements academiques appariteur - 2026-07-13

L'enrolement academique est distingue de la demande de creation de compte et
de l'inscription a un cours. Il rattache un etudiant actif a une promotion et
a une annee academique. Le parcours MVP ne cree pas automatiquement de compte,
de paiement, de note, de presence ou d'inscription de cours.

La migration additive `20260713_0006` cree `enrolements_academiques`. Elle a
ete appliquee et testee sur `smart_faculty_test`, avec verification du cycle
downgrade `0006 -> 0005` puis upgrade `0005 -> 0006`. La base principale
`smart_faculty` reste volontairement a `20260713_0005`; aucune donnee de
demonstration n'y a ete ajoutee. La sauvegarde pre-migration est conservee
dans `backend/sauvegardes/`.

Les statuts sont `en_attente`, `valide` et `annule`. Le triplet etudiant,
promotion, annee n'admet qu'un seul enrolement actif; une annulation conserve
l'historique et libere le triplet pour une nouvelle fiche. Une reference unique
est generee cote backend. L'appariteur authentifie est determine par son token
et ne peut pas fournir une identite d'autorite depuis Flutter.

Routes principales: `GET` et `POST /api/v1/appariteur/enrolements`,
`PATCH /api/v1/appariteur/enrolements/{id}`, validation, annulation, detail,
liste par etudiant et donnees de fiche. Les reponses excluent mots de passe,
hash, tokens, donnees financieres et informations personnelles inutiles.

Flutter expose `Enrolements` dans la navigation Appariteur avec liste,
recherche, filtres, creation, detail, validation, annulation, chargement,
absence, erreur et session expiree. La fiche reste une reponse de donnees:
le PDF et le telechargement etudiant sont reportes. L'attribution des
encadreurs, les paiements, les notes et les presences restent hors perimetre.

Validation 5A: deux executions backend ont donne `128 passed`; deux
executions Flutter ont donne `42 passed`; `flutter analyze` ne signale aucune
erreur ni avertissement et conserve 6 informations historiques `dart:html`;
le build Web release est reussi. FastAPI repond HTTP 200 sur `/`,
`/api/v1/statut` et le health check MySQL. Le Prompt 5A est techniquement
valide et la migration `0006` est prete pour un deploiement controle ulterieur
sur `smart_faculty`.

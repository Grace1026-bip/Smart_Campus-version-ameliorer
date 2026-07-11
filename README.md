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

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

La configuration actuelle du backend lit les variables `MYSQL_*` depuis l'environnement ou depuis `.env` / `backend/.env`. Pour lancer les tests sans toucher a la base principale, definir au minimum `MYSQL_DATABASE=smart_faculty_test` dans la session PowerShell avant les migrations et `pytest`.

Commande SQL a executer dans MySQL Workbench si la base de test n'existe pas encore:

```sql
CREATE DATABASE IF NOT EXISTS smart_faculty_test
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
```

Avec PowerShell, une session de test typique ressemble a ceci:

```powershell
cd backend
$env:MYSQL_DATABASE = "smart_faculty_test"
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe scripts\creer_donnees_initiales.py
.\.venv\Scripts\python.exe -m pytest -v
Remove-Item Env:\MYSQL_DATABASE
```

Ne jamais lancer `pytest` sur `smart_faculty`.

Un script dedie existe aussi depuis la racine:

```powershell
.\scripts\test_backend.bat
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
- Donnees initiales de test: creees ou deja presentes sur `smart_faculty_test`.
- Tests backend officiels: `26 passed in 40.87s` avec `scripts/test_backend.bat`.

La base principale `smart_faculty` reste la base normale de developpement. Les tests doivent continuer a utiliser uniquement une base dont le nom finit par `_test`.

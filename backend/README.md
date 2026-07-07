# Smart Faculty - Backend FastAPI

Backend FastAPI de Smart Faculty, centre sur le MVP Phase 2:

- authentification JWT avec refresh token;
- gestion des roles;
- structure academique;
- promotions, cours, etudiants, enseignants;
- affectations enseignant-cours;
- inscriptions etudiant-cours;
- migrations MySQL avec Alembic;
- tests automatises.

L'ancien backend PHP peut encore exister dans le depot, mais la nouvelle API officielle se lance avec:

```powershell
uvicorn app.main:app --reload
```

## Prerequis

- Python 3.11 ou plus recent;
- MySQL ou WAMP MySQL;
- une base MySQL `smart_faculty`;
- PowerShell sous Windows.

Sur cette machine, MySQL WAMP est disponible ici:

```text
C:\wamp64\bin\mysql\mysql8.4.7\bin\mysql.exe
```

## Installation

Depuis le dossier `backend`:

```powershell
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Configurer ensuite `.env`:

```env
APP_NAME=Smart Faculty
APP_ENV=development
APP_DEBUG=true

MYSQL_HOST=127.0.0.1
MYSQL_PORT=3307
MYSQL_DATABASE=smart_faculty
MYSQL_USER=root
MYSQL_PASSWORD=

JWT_SECRET_KEY=changer_cette_cle
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=15

FRONTEND_ORIGINS=http://localhost:3000,http://localhost:5000
```

En production, remplacer `JWT_SECRET_KEY`.

## Creation de la base

Si la base n'existe pas:

```powershell
& "C:\wamp64\bin\mysql\mysql8.4.7\bin\mysql.exe" --host=127.0.0.1 --port=3307 --user=root --execute="CREATE DATABASE IF NOT EXISTS smart_faculty CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
```

## Migrations

```powershell
.venv\Scripts\python.exe -m alembic upgrade head
```

Retour arriere en developpement:

```powershell
.venv\Scripts\python.exe -m alembic downgrade base
```

## Donnees initiales

```powershell
.venv\Scripts\python.exe scripts\creer_donnees_initiales.py
```

Le script est idempotent.

Comptes de test:

```text
admin@smartfaculty.test       / Smart@123456 / administrateur
enseignant@smartfaculty.test  / Smart@123456 / enseignant
etudiant@smartfaculty.test    / Smart@123456 / etudiant
appariteur@smartfaculty.test  / Smart@123456 / appariteur
doyen@smartfaculty.test       / Smart@123456 / doyen ou enseignant
```

## Lancement du serveur

```powershell
.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Swagger:

```text
http://127.0.0.1:8000/docs
```

OpenAPI:

```text
http://127.0.0.1:8000/openapi.json
```

## Tests

Les tests automatises doivent tourner sur une base separee finissant par `_test`.

Creation d'une base de test temporaire:

```powershell
& "C:\wamp64\bin\mysql\mysql8.4.7\bin\mysql.exe" --host=127.0.0.1 --port=3307 --user=root --execute="DROP DATABASE IF EXISTS smart_faculty_test; CREATE DATABASE smart_faculty_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
```

Migration et seed sur la base de test:

```powershell
$env:MYSQL_DATABASE="smart_faculty_test"
.venv\Scripts\python.exe -m alembic upgrade head
.venv\Scripts\python.exe scripts\creer_donnees_initiales.py
.venv\Scripts\python.exe -m pytest -q
Remove-Item Env:\MYSQL_DATABASE
```

Suppression de la base de test:

```powershell
& "C:\wamp64\bin\mysql\mysql8.4.7\bin\mysql.exe" --host=127.0.0.1 --port=3307 --user=root --execute="DROP DATABASE IF EXISTS smart_faculty_test"
```

Scripts de verification manuelle:

```powershell
.venv\Scripts\python.exe scripts\verifier_auth_etape_d.py
.venv\Scripts\python.exe scripts\verifier_academique_etape_e.py
```

## Format des reponses

Succes:

```json
{
  "succes": true,
  "message": "Operation reussie",
  "donnees": {}
}
```

Erreur:

```json
{
  "succes": false,
  "message": "Une erreur est survenue",
  "erreurs": []
}
```

## Routes principales

Systeme:

```text
GET /api/v1/statut
GET /api/v1/sante/base-de-donnees
```

Authentification:

```text
POST /api/v1/auth/connexion
POST /api/v1/auth/actualiser
POST /api/v1/auth/deconnexion
GET  /api/v1/auth/moi
PUT  /api/v1/auth/mot-de-passe
```

La connexion exige:

```json
{
  "email": "admin@smartfaculty.test",
  "mot_de_passe": "Smart@123456",
  "role": "administrateur"
}
```

Gestion academique:

```text
GET    /api/v1/promotions
GET    /api/v1/promotions/{id}
POST   /api/v1/promotions
PUT    /api/v1/promotions/{id}
DELETE /api/v1/promotions/{id}

GET    /api/v1/cours
GET    /api/v1/cours/{id}
POST   /api/v1/cours
PUT    /api/v1/cours/{id}
DELETE /api/v1/cours/{id}

GET    /api/v1/etudiants
GET    /api/v1/etudiants/{id}
POST   /api/v1/etudiants
PUT    /api/v1/etudiants/{id}

GET    /api/v1/enseignants
GET    /api/v1/enseignants/{id}
POST   /api/v1/enseignants
PUT    /api/v1/enseignants/{id}

POST   /api/v1/cours/{id}/enseignants
PUT    /api/v1/affectations/{id}
DELETE /api/v1/affectations/{id}

POST   /api/v1/inscriptions-cours
PUT    /api/v1/inscriptions-cours/{id}
DELETE /api/v1/inscriptions-cours/{id}
```

## Securite

- mots de passe hashes avec bcrypt;
- access token JWT court;
- refresh token aleatoire stocke hashe;
- refresh token revoque a la deconnexion;
- role actif verifie dans le token;
- permissions verifiees cote FastAPI;
- `.env` ignore par Git.

## Structure actuelle

```text
backend/
  app/
    main.py
    configuration/
    base_de_donnees/
    modeles/
    schemas/
    services/
    routes/
    dependances/
    exceptions/
    utilitaires/
  alembic/
  scripts/
  tests/
  alembic.ini
  requirements.txt
  .env.example
```

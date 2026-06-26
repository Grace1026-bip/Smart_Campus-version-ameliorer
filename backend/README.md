# Smart Faculty - Backend PHP POO MVC

Backend PHP oriente objet pour demarrer Smart Faculty avec une API REST JSON, MySQL, PDO, sessions PHP, roles multiples et demandes d'inscription.

Le travail actuel couvre volontairement seulement:

- authentification;
- inscription et approbation;
- sessions classiques;
- option "Se souvenir de moi" pendant 15 jours;
- roles et permissions de base;
- premiers tableaux de bord etudiant et enseignant.

Les modules notes, stages, projets, analytics et reclamations ne sont pas encore developpes.

## Structure principale

```text
backend/
  public/index.php
  application/
    controleurs/
    modeles/
    services/
    middlewares/
    noyau/
    aides/
  configuration/
    application.php
    base_de_donnees.php
  base_de_donnees/
    schema.sql
    donnees_test.sql
```

Les anciens dossiers `app`, `config` et `database` peuvent encore exister dans le projet, mais l'API publique charge maintenant la structure francaise ci-dessus.

## Installation locale

1. Copier la configuration:

```powershell
Copy-Item backend\.env.example backend\.env
```

2. Modifier `backend\.env` avec les identifiants MySQL.

3. Importer le schema puis les donnees de test:

```powershell
mysql -u root -p < backend\base_de_donnees\schema.sql
mysql -u root -p smart_faculty < backend\base_de_donnees\donnees_test.sql
```

4. Lancer l'API:

```powershell
php -S 127.0.0.1:8000 -t backend\public backend\public\index.php
```

Base URL Postman/Thunder Client:

```text
http://127.0.0.1:8000
```

Depuis un emulateur Android Flutter:

```text
http://10.0.2.2:8000
```

## Comptes de test

```text
admin@smartfaculty.test       / Admin@123456
paritaire@smartfaculty.test   / Paritaire@123456
icp@smartfaculty.test         / Icp@123456
doyen@smartfaculty.test       / Doyen@123456
vice.doyen@smartfaculty.test  / Vice@123456
etudiant@smartfaculty.test    / Etudiant@123456
enseignant@smartfaculty.test  / Enseignant@123456
```

## Roles

```text
etudiant
enseignant
chef_promotion
icp
appariteur
paritaire
doyen
vice_doyen
administrateur
```

Un doyen ou vice-doyen doit aussi posseder le role `enseignant`. Les donnees de test appliquent deja cette regle.

## Format JSON

Toutes les reponses suivent ce contrat:

```json
{
  "succes": true,
  "message": "Connexion reussie",
  "donnees": {}
}
```

En cas d'erreur:

```json
{
  "succes": false,
  "message": "Email ou mot de passe incorrect",
  "erreurs": []
}
```

## Endpoints principaux

### Connexion

```powershell
curl.exe -c cookies.txt -b cookies.txt -X POST http://127.0.0.1:8000/api/connexion `
  -H "Content-Type: application/json" `
  -d "{\"email\":\"admin@smartfaculty.test\",\"mot_de_passe\":\"Admin@123456\",\"se_souvenir_de_moi\":true}"
```

Aliases acceptes: `password`, `remember`, `remember_me`.

### Utilisateur connecte

```powershell
curl.exe -b cookies.txt http://127.0.0.1:8000/api/utilisateur/connecte
```

### Deconnexion

```powershell
curl.exe -b cookies.txt -c cookies.txt -X POST http://127.0.0.1:8000/api/deconnexion
```

### Inscription etudiant

```powershell
curl.exe -X POST http://127.0.0.1:8000/api/inscription/etudiant `
  -H "Content-Type: application/json" `
  -d "{\"nom\":\"Kanza\",\"postnom\":\"Mbuyi\",\"prenom\":\"Aline\",\"email\":\"aline@example.com\",\"matricule\":\"SF-L2-0100\",\"promotion\":\"L2 Informatique\",\"mot_de_passe\":\"Secret123\"}"
```

Le compte cree reste `en_attente` et ne peut pas se connecter avant approbation.

### Inscription enseignant

```powershell
curl.exe -X POST http://127.0.0.1:8000/api/inscription/enseignant `
  -H "Content-Type: application/json" `
  -d "{\"nom\":\"Mabika\",\"postnom\":\"Lukusa\",\"prenom\":\"Paul\",\"email\":\"paul@example.com\",\"departement\":\"Informatique\",\"cours\":\"PHP MVC\",\"mot_de_passe\":\"Secret123\"}"
```

### Lister les demandes

```powershell
curl.exe -b cookies.txt http://127.0.0.1:8000/api/demandes-inscription
curl.exe -b cookies.txt "http://127.0.0.1:8000/api/demandes-inscription?statut=en_attente"
```

### Approuver une demande

```powershell
curl.exe -b cookies.txt -X POST http://127.0.0.1:8000/api/demandes-inscription/1/approuver
```

### Rejeter une demande

```powershell
curl.exe -b cookies.txt -X POST http://127.0.0.1:8000/api/demandes-inscription/1/rejeter `
  -H "Content-Type: application/json" `
  -d "{\"motif\":\"Informations incompletes\"}"
```

### Tableaux de bord

```powershell
curl.exe -b cookies.txt http://127.0.0.1:8000/api/etudiant/tableau-de-bord
curl.exe -b cookies.txt http://127.0.0.1:8000/api/enseignant/tableau-de-bord
```

## Regles d'approbation

Demandes etudiantes:

```text
icp, paritaire, doyen, vice_doyen, administrateur
```

Demandes enseignantes:

```text
paritaire, doyen, vice_doyen, administrateur
```

## Preparation Flutter

Le frontend Flutter pourra consommer progressivement:

- `POST /api/connexion`;
- `GET /api/utilisateur/connecte`;
- `POST /api/deconnexion`;
- les tableaux de bord selon le role connecte.

Pour Flutter Web ou mobile, garder `Content-Type: application/json` et activer la conservation des cookies si l'application utilise les sessions PHP. Pour une future version mobile plus robuste, on pourra ajouter une authentification par Bearer token sans casser ces endpoints.

## Securite deja appliquee

- Mots de passe hashes avec `password_hash()`.
- Verification avec `password_verify()`.
- Requetes SQL via PDO et statements prepares.
- Cookies `HttpOnly` et `SameSite`.
- Token remember-me aleatoire, stocke hashe en base.
- Routes privees protegees par session et roles.

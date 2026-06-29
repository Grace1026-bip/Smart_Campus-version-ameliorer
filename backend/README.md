# Smart Faculty - Backend PHP POO MVC

Backend PHP oriente objet pour demarrer Smart Faculty avec une API REST JSON, MySQL, PDO, sessions PHP, roles multiples et demandes d'inscription.

Le travail actuel couvre volontairement seulement:

- authentification;
- inscription et approbation;
- sessions classiques;
- option "Se souvenir de moi" pendant 15 jours;
- roles et permissions de base;
- premiers tableaux de bord etudiant et enseignant.

Les espaces etudiant et enseignant consomment maintenant l'API pour les tableaux de bord, cours, notes, valve, alertes et reclamations.

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

Sur cette installation WAMP, la base `smart_faculty` repond correctement sur le port `3307`; le fichier local `backend\.env` doit donc contenir:

```env
DB_HOST=127.0.0.1
DB_PORT=3307
DB_PORT_FALLBACKS=3307,3306
DB_DATABASE=smart_faculty
DB_USERNAME=root
DB_PASSWORD=
```

Le port `3306` peut aussi etre ouvert par un autre MySQL/WAMP, mais il doit contenir la base `smart_faculty` et accepter les memes identifiants. Si tu veux l'essayer, mets `DB_PORT=3306` et garde `DB_PORT_FALLBACKS=3307,3306` pour que l'API tente automatiquement l'autre port en cas d'echec.

3. Importer le schema puis les donnees de test:

```powershell
mysql -u root -p < backend\base_de_donnees\schema.sql
mysql -u root -p smart_faculty < backend\base_de_donnees\donnees_test.sql
```

Si `mysql` n'est pas dans le PATH avec WAMP:

```powershell
& "C:\wamp64\bin\mysql\mysql8.4.7\bin\mysql.exe" -h 127.0.0.1 -P 3307 -u root -e "SOURCE C:/Users/gisel/Projet_L2/Smart_Campus/backend/base_de_donnees/schema.sql"
& "C:\wamp64\bin\mysql\mysql8.4.7\bin\mysql.exe" -h 127.0.0.1 -P 3307 -u root smart_faculty -e "SOURCE C:/Users/gisel/Projet_L2/Smart_Campus/backend/base_de_donnees/donnees_test.sql"
```

4. Exposer l'API avec une URL fixe.

Option recommandee avec Apache/WAMP/Laragon: faire pointer le serveur web vers le dossier `backend/public`, ou placer le projet sous le document root Apache.

Sur cette machine, IIS occupe le port `80` et WAMP/Apache ecoute sur `8080`. Un lien local a ete cree:

```text
C:\wamp64\www\smart-faculty -> C:\Users\gisel\Projet_L2\Smart_Campus
```

Exemples d'URLs API valides:

```text
http://localhost:8080/smart-faculty/backend/public/api/status
http://localhost:8080/smart-faculty/backend/public/api/connexion
```

Le fichier `backend/public/.htaccess` redirige les routes `/api/...` vers `index.php`. Le routeur PHP retire automatiquement le prefixe du sous-dossier Apache, donc `/smart-faculty/backend/public/api/connexion` devient bien `/api/connexion` cote backend.

Option de developpement avec le serveur PHP integre:

```powershell
& "C:\wamp64\bin\php\php8.4.15\php.exe" -S localhost:8000 -t backend\public backend\public\index.php
```

Le script `scripts\demarrer_backend.bat` existe seulement comme raccourci de developpement pour cette commande. Flutter ne depend pas de ce script.

## Configuration Flutter de l'API

La configuration centrale se trouve dans:

```text
app_mobile/lib/core/config/api_config.dart
```

Valeurs par defaut:

```text
Web/Desktop:       http://localhost:8080/smart-faculty/backend/public
Android Emulator:  http://10.0.2.2:8080/smart-faculty/backend/public
Telephone reel:    http://ADRESSE_IP_DU_PC:8080/smart-faculty/backend/public
```

Tu peux forcer une URL au lancement Flutter:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:8000
flutter run --dart-define=API_BASE_URL=http://localhost:8080/smart-faculty/backend/public
```

## Comptes de test

```text
admin@smartfaculty.test       / Admin@123456
paritaire@smartfaculty.test   / Paritaire@123456
icp@smartfaculty.test         / Icp@123456
doyen@smartfaculty.test       / Doyen@123456
vice.doyen@smartfaculty.test  / Vice@123456
etudiant@smartfaculty.test    / Etudiant@123456
enseignant@smartfaculty.test  / password123
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

### Espace etudiant dynamique

```powershell
curl.exe -b cookies.txt http://127.0.0.1:8000/api/etudiant/cours
curl.exe -b cookies.txt http://127.0.0.1:8000/api/etudiant/cours/1
curl.exe -b cookies.txt http://127.0.0.1:8000/api/etudiant/valve
curl.exe -b cookies.txt http://127.0.0.1:8000/api/etudiant/valve/cours/1
curl.exe -b cookies.txt http://127.0.0.1:8000/api/etudiant/notes
curl.exe -b cookies.txt http://127.0.0.1:8000/api/etudiant/alertes
```

Creer une reclamation:

```powershell
curl.exe -b cookies.txt -X POST http://127.0.0.1:8000/api/etudiant/reclamations `
  -H "Content-Type: application/json" `
  -d "{\"cours_id\":1,\"titre\":\"Verification note\",\"description\":\"Je souhaite verifier ma moyenne finale.\"}"
```

### Espace enseignant dynamique

```powershell
curl.exe -b cookies.txt http://127.0.0.1:8000/api/enseignant/cours
curl.exe -b cookies.txt http://127.0.0.1:8000/api/enseignant/cours/1
curl.exe -b cookies.txt http://127.0.0.1:8000/api/enseignant/valve
curl.exe -b cookies.txt http://127.0.0.1:8000/api/enseignant/cours/1/etudiants
curl.exe -b cookies.txt http://127.0.0.1:8000/api/enseignant/cours/1/notes
curl.exe -b cookies.txt http://127.0.0.1:8000/api/enseignant/cours/1/etudiants-a-risque
curl.exe -b cookies.txt http://127.0.0.1:8000/api/enseignant/reclamations
```

Publier dans la valve:

```powershell
curl.exe -b cookies.txt -X POST http://127.0.0.1:8000/api/enseignant/valve/publication `
  -H "Content-Type: application/json" `
  -d "{\"cours_id\":1,\"type_publication\":\"annonce\",\"titre\":\"Rappel TP\",\"contenu\":\"Le TP est a remettre avant vendredi.\"}"
```

Encoder des notes en brouillon:

```powershell
curl.exe -b cookies.txt -X POST http://127.0.0.1:8000/api/enseignant/cours/1/notes/brouillon `
  -H "Content-Type: application/json" `
  -d "{\"notes\":[{\"matricule\":\"SF-L2-0001\",\"type\":\"moyenne_finale\",\"valeur\":14.5}]}"
```

Publier et verrouiller les notes:

```powershell
curl.exe -b cookies.txt -X POST http://127.0.0.1:8000/api/enseignant/cours/1/notes/publier
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

Les ecrans etudiant et enseignant consomment maintenant l'API PHP:

- login reel via `POST /api/connexion`;
- dashboard etudiant via `GET /api/etudiant/tableau-de-bord`;
- dashboard enseignant via `GET /api/enseignant/tableau-de-bord`;
- page notes etudiant/enseignant via les endpoints dedies.

Pour Flutter Web ou mobile, garder `Content-Type: application/json` et activer la conservation des cookies si l'application utilise les sessions PHP. Pour une future version mobile plus robuste, on pourra ajouter une authentification par Bearer token sans casser ces endpoints.

## Securite deja appliquee

- Mots de passe hashes avec `password_hash()`.
- Verification avec `password_verify()`.
- Requetes SQL via PDO et statements prepares.
- Cookies `HttpOnly` et `SameSite`.
- Token remember-me aleatoire, stocke hashe en base.
- Routes privees protegees par session et roles.

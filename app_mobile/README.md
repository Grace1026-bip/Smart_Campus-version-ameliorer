# Smart Faculty

Frontend Flutter responsive pour Smart Faculty.

## Lancer l'application

```bash
flutter pub get
flutter run -d chrome --web-port 3000
```

Le port web `3000` est conseille parce qu'il est autorise par le CORS du
backend FastAPI.

## Backend attendu

- API par defaut : `http://127.0.0.1:8000/api/v1`
- Override possible avec `--dart-define=API_BASE_URL=http://ADRESSE:PORT`
- Authentification : email + mot de passe + role
- Jetons : `access_token` Bearer + `refresh_token`

## Comptes de test FastAPI

Mot de passe commun : `Smart@123456`.

- `etudiant@smartfaculty.test`
- `enseignant@smartfaculty.test`
- `appariteur@smartfaculty.test`
- `doyen@smartfaculty.test`
- `admin@smartfaculty.test`

## Etat actuel

- Connexion Flutter orientee FastAPI.
- Services API crees pour notes, valve, presences, reclamations,
  notifications, risques et dashboard decisionnel.
- Certains ecrans non MVP ou anciens parcours conservent encore des donnees
  fictives et seront traites progressivement.

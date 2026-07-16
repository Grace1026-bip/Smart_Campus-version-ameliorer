# Guide de la structure du projet Smart Faculty

## 1. Carte mentale generale

Le projet officiel repose sur trois blocs actifs :

```text
frontend/  -> interface Flutter vue par l'utilisateur
backend/   -> API FastAPI, regles metier et acces MySQL
docs/      -> analyse, conception, memoire et preuves du projet
```

Les autres blocs ont des fonctions de support :

```text
scripts/   -> commandes simples de demarrage et de test
legacy/    -> anciennes versions PHP et Flask, non actives
.git/      -> historique Git
.vscode/   -> configuration locale de l'editeur
```

Le trajet normal d'une action est :

```text
Ecran Flutter
  -> service Flutter
  -> requete HTTP vers /api/v1/...
  -> route FastAPI
  -> schema Pydantic
  -> service metier Python
  -> modele SQLAlchemy
  -> table MySQL
```

## 2. Racine du projet

### `README.md`

Page d'accueil technique du projet. Elle explique les technologies officielles, la structure, les commandes de lancement, les tests et les decisions importantes.

### `.gitignore`

Indique a Git les fichiers qui ne doivent pas etre versionnes : secrets, environnements virtuels, caches, builds, logs et sauvegardes locales.

### `.env`

Configuration locale de la racine. Un fichier `.env` peut contenir des parametres sensibles et ne doit normalement pas etre publie.

### `.git/`

Base interne de Git : commits, branches, index et historique. Ce n'est pas du code applicatif.

### `.agents/`

Dossier de configuration reserve aux agents/outils de developpement. Il n'intervient pas dans l'execution de Smart Faculty.

### `.vscode/settings.json`

Preferences locales de Visual Studio Code. Elles n'appartiennent pas a la logique metier.

### `.pytest_cache/`

Cache cree par Pytest pour accelerer ou memoriser les derniers tests. Il peut etre supprime et recree ; ce n'est pas du code source.

## 3. Backend FastAPI

### Fichiers a la racine de `backend/`

- `README.md` : instructions propres au backend.
- `requirements.txt` : liste et versions des bibliotheques Python.
- `.env` : configuration locale reelle du backend.
- `.env.example` : modele de configuration sans secret.
- `.env.test.example` : modele reserve a la base de test.
- `alembic.ini` : configuration de l'outil de migrations Alembic.

### `backend/app/main.py`

Point d'entree officiel de FastAPI. Il cree l'application, configure CORS, enregistre les gestionnaires d'erreurs, branche le routeur `/api/v1` et expose la route racine.

### Fichiers `__init__.py`

Ils indiquent que les dossiers Python sont des paquets importables. Celui de `modeles/` importe aussi les modeles afin que SQLAlchemy et Alembic connaissent les tables.

## 4. Configuration et base de donnees

### `backend/app/configuration/parametres.py`

Lit les variables d'environnement avec Pydantic Settings : MySQL, JWT, CORS, seuils de risque, stockage de la valve et biometrie. Il construit aussi l'URL MySQL.

### `backend/app/configuration/securite.py`

Fonctions cryptographiques partagees : hachage et verification bcrypt des mots de passe, creation/lecture des JWT, generation et hachage des refresh tokens.

### `backend/app/base_de_donnees/base.py`

Declare la classe `Base` dont heritent tous les modeles SQLAlchemy.

### `backend/app/base_de_donnees/connexion.py`

Cree le moteur SQLAlchemy, la fabrique de sessions, la dependance `obtenir_session()` et le controle `SELECT 1` de sante MySQL.

## 5. Authentification, erreurs et reponses

### `backend/app/dependances/authentification.py`

Lit le Bearer token, recharge l'utilisateur, verifie le compte et le role, puis fournit `exiger_role()` et `exiger_un_des_roles()` aux routes protegees.

### `backend/app/exceptions/erreurs.py`

Definit les erreurs metier : authentification requise, acces interdit, ressource introuvable, conflit de donnees, etc.

### `backend/app/exceptions/gestionnaires.py`

Transforme les exceptions Python, Pydantic, HTTP et SQLAlchemy en reponses JSON propres sans exposer les details internes.

### `backend/app/utilitaires/reponses.py`

Uniformise les reponses API avec `succes`, `message`, `donnees` ou `erreurs`.

## 6. Les quatre familles metier du backend

Pour presque chaque domaine, quatre fichiers travaillent ensemble :

```text
modeles/X.py  -> structure des tables
schemas/X.py  -> forme et validation des entrees API
routes/X.py   -> URL, methode HTTP et autorisation
services/X.py -> regles metier et transactions
```

### Authentification

- `modeles/securite.py` : utilisateurs, roles, permissions, associations et refresh tokens.
- `schemas/authentification.py` : connexion, actualisation, deconnexion et changement de mot de passe.
- `routes/authentification.py` : endpoints `/auth/...`.
- `services/authentification.py` : verification bcrypt, roles, JWT, rotation et revocation des jetons.

### Inscriptions et reinitialisations

- `modeles/inscriptions.py` : demandes publiques d'inscription.
- `schemas/inscriptions.py` : validation des formulaires etudiant/enseignant.
- `routes/inscriptions.py` : soumission, consultation, approbation et rejet.
- `services/inscriptions.py` : workflow de creation du compte et du profil.
- `modeles/reinitialisations.py` : demandes et jetons de mot de passe oublie.
- `schemas/reinitialisations.py` : donnees attendues pour ce workflow.
- `services/reinitialisations.py` : demande, approbation et changement securise.

### Referentiel academique

- `modeles/academique.py` : annees, semestres, promotions, cours, etudiants, enseignants, affectations et inscriptions aux cours.
- `schemas/academique.py` : donnees valides pour ces entites.
- `routes/academique.py` : endpoints de gestion du referentiel.
- `services/academique.py` : creation, modification, recherche et controles de coherence.
- `routes/enseignants.py` et `services/enseignants.py` : espace et operations propres aux enseignants.
- `routes/etudiants.py` : espace personnel etudiant derive du token.
- `services/espace_etudiant.py` : tableau de bord, cours et historique academique de l'etudiant.
- `services/dashboard.py` et `routes/dashboard.py` : indicateurs des tableaux de bord.

### Enrolements

- `modeles/enrolements.py` : fiche d'enrolement annuel et statut.
- `routes/enrolements.py` : gestion par l'appariteur.
- `services/enrolements.py` : creation, validation, annulation, reference et controle des doublons.
- `services/fiches_pdf.py` : generation en memoire de la fiche PDF avec ReportLab.

### Notes et resultats

- `modeles/notes.py` : types d'evaluations, evaluations, notes et resultats de cours.
- `schemas/notes.py` : validation des notes, ponderations et publications.
- `routes/notes.py` : endpoints d'encodage et consultation.
- `services/notes.py` : regles d'encodage, verrouillage et calcul.
- `services/calcul_academique.py` : formules academiques reutilisables.
- `routes/resultats.py` : exposition des resultats.
- `services/resultats_academiques.py` : calcul et serialisation des resultats academiques.

### Deliberations LMD

- `modeles/deliberations.py` : sessions, membres du jury, decisions et resultats officiels.
- `schemas/deliberations.py` : ouverture, cloture, membres et decisions valides.
- `routes/deliberations.py` : endpoints du workflow du jury.
- `services/deliberations.py` : calcul pondere, snapshots, validation et publication.

### Notifications

- `modeles/notifications.py` : notifications et statut de lecture.
- `schemas/notifications.py` : filtres et donnees d'entree.
- `routes/notifications.py` : liste et marquage comme lu.
- `services/notifications.py` : creation et consultation des notifications.

### Valve academique

- `modeles/valve.py` : publications, pieces jointes et lectures.
- `schemas/valve.py` : creation et modification des publications.
- `routes/valve.py` : publication, consultation, upload et telechargement.
- `services/valve.py` : perimetres par cours, stockage, validation des fichiers et autorisation de telechargement.

### Reclamations

- `modeles/reclamations.py` : reclamations, messages et historique des statuts.
- `schemas/reclamations.py` : creation, message et changement de statut.
- `routes/reclamations.py` : endpoints etudiant et personnel.
- `services/reclamations.py` : perimetres, transitions, messages et audit.

### Risques academiques

- `modeles/suivi.py` : presences historiques et evaluations de risque.
- `schemas/risques.py` : lots de presences et portee du recalcul.
- `routes/risques.py` : endpoints enseignant, etudiant et direction.
- `services/risques.py` : score notes/absences/retards, niveau, historique et notification.

### Projets et encadrements

- `modeles/projets.py` : projets academiques et encadrements.
- `modeles/specialites.py` : domaines d'encadrement declares pour les enseignants.
- `schemas/projets.py` : creation, attribution et decisions.
- `routes/projets.py` : soumission, gestion appariteur et consultation enseignant/etudiant.
- `services/projets.py` : compatibilite, attribution, remplacement, archivage et perimetres.

### Presences academiques

- `modeles/presences_academiques.py` : seances, presences et corrections.
- `schemas/presences_academiques.py` : ouverture, identification et correction.
- `routes/presences_academiques.py` : endpoints surveillant, etudiant, enseignant et chef de promotion.
- `services/presences_academiques.py` : controle d'acces, seuil administratif, absences, taux et audit.

### Biometrie

- `modeles/biometrie.py` : profils biometriques et encodages faciaux.
- `schemas/biometrie.py` : consentement, enrolement, revocation et reconnaissance.
- `routes/biometrie.py` : endpoints appariteur et surveillant.
- `services/biometrie.py` : workflow, autorisations, integrite et journalisation.
- `services/moteur_faciale.py` : adaptateur vers le moteur facial reel lorsqu'il est disponible.

### Audit

- `modeles/audit.py` : table generique des actions sensibles.

### Pagination et reponses

- `schemas/pagination.py` : page, taille, offset et format des listes paginees.
- `schemas/reponses.py` : schemas generiques de reponse.

## 7. Routeur principal

### `backend/app/routes/api.py`

Cree le prefixe `/api/v1`, importe et branche tous les routeurs metier. Il fournit aussi les endpoints de statut et de sante MySQL.

### `backend/app/routes/__init__.py`

Marque le dossier comme paquet Python.

### `backend/app/controleurs/` et `backend/app/depots/`

Dossiers actuellement reserves. Ils ne contiennent pas de logique active, seulement `__init__.py`. L'architecture active utilise surtout `routes/` et `services/`.

### `backend/app/api/` et `backend/app/core/`

Dossiers reserves ou anciens selon l'etat courant. Le routeur actif est `app/routes/api.py`; le moteur facial actif est dans `app/services/moteur_faciale.py`.

## 8. Migrations Alembic

### `backend/alembic/env.py`

Relie Alembic a la configuration MySQL et aux metadonnees SQLAlchemy. Il contient aussi des protections particulieres pour la base de test.

### `backend/alembic/script.py.mako`

Modele utilise quand Alembic genere une nouvelle migration.

### `backend/alembic/versions/`

- `20260705_0001_structure_initiale.py` : tables initiales.
- `20260705_0002_valve_lectures_et_pieces.py` : lectures et pieces jointes de la valve.
- `20260711_0003_demandes_inscription.py` : demandes publiques d'inscription.
- `20260713_0004_deliberations_lmd.py` : jury et resultats officiels.
- `20260713_0005_projets_encadrements.py` : projets et encadreurs.
- `20260713_0006_enrolements_academiques.py` : enrolements annuels.
- `20260713_0007_specialites_encadrement.py` : compatibilite des encadreurs.
- `20260714_0008_presences_academiques.py` : seances et presences academiques.
- `20260715_0009_corrections_presences.py` : historique des corrections.
- `20260715_0010_fondation_biometrique.py` : profils et encodages faciaux.
- `20260715_0011_workflows_defense.py` : evolutions ajoutees pour les workflows finalises avant la defense.

Une migration possede normalement `upgrade()` pour avancer et `downgrade()` pour revenir en arriere.

## 9. Scripts et schemas backend

### `backend/scripts/`

- `creer_donnees_initiales.py` : cree/verifie le referentiel et les comptes initiaux.
- `preparer_base_test.sql` : prepare la base de test.
- `reinitialiser_base_test.py` : recree uniquement la base autorisee finissant par `_test`.
- `preparer_demo_defense.py` : prepare un scenario de demonstration coherent.
- `provisionner_compte_role.py` : cree ou configure un compte pour un role donne.
- `verifier_auth_etape_d.py` : diagnostic cible de l'authentification.
- `verifier_academique_etape_e.py` : diagnostic cible du domaine academique.

### `backend/base_de_donnees/`

- `schema.sql` : schema SQL de reference.
- `schema_smart_faculty_20260713_0007.sql` : photographie historique du schema a la revision 0007.
- `donnees_test.sql` : ancien jeu SQL de test/reference.
- `sauvegarder_base.ps1` : script PowerShell de sauvegarde MySQL.
- `migrations/20260703_nettoyage_schema_academique.sql` : ancienne migration SQL manuelle conservee comme reference.

La source officielle des evolutions actuelles reste Alembic.

### `backend/stockage/`

Contient les fichiers produits localement : pieces de valve, logs et sessions selon les modules. Les `.gitignore` permettent de garder les dossiers sans versionner leur contenu sensible ou temporaire.

## 10. Tests backend

### `backend/tests/conftest.py`

Configure FastAPI pour les tests, refuse une base ne finissant pas par `_test` et isole chaque test avec transactions/savepoints.

### Fichiers de tests

- `test_authentification.py` : connexion, roles, statuts, JWT, refresh et falsifications.
- `test_cors.py` : origines autorisees et refusees.
- `test_academique.py` : referentiel academique.
- `test_dashboard.py` : indicateurs des tableaux de bord.
- `test_inscriptions.py` : demandes, approbations et rejets.
- `test_enseignants.py` : gestion et perimetre enseignant.
- `test_notes_resultats.py` : evaluations, notes et resultats.
- `test_resultats_academiques.py` : calcul et publication academique.
- `test_deliberations.py` : workflow du jury LMD.
- `test_notifications.py` : notifications et lecture.
- `test_valve.py` : publications, pieces, lectures et autorisations.
- `test_reclamations.py` : reclamations, messages et statuts.
- `test_risques.py` : score et perimetres des risques.
- `test_enrolements.py` : workflow administratif annuel.
- `test_projets_enseignant.py` : consultation par l'encadreur.
- `test_projets_appariteur.py` : attribution et specialites.
- `test_espace_etudiant.py` : enrolements et projets etudiant.
- `test_espace_etudiant_academique.py` : dashboard, cours et historique.
- `test_presences_academiques.py` : creation, ouverture et controle d'acces.
- `test_presences_7b.py` : consultation, fermeture et corrections.
- `test_biometrie_7c_a.py` : consentement, enrolement, revocation et delegation.
- `test_moteur_faciale_reel.py` : comportement du moteur facial reel/optionnel.
- `test_defense_workflows.py` : scenarios transversaux prepares pour la defense.

## 11. Frontend Flutter

### Fichiers a la racine de `frontend/`

- `pubspec.yaml` : nom, version, SDK, dependances et assets Flutter.
- `pubspec.lock` : versions exactes resolues des dependances.
- `analysis_options.yaml` : regles d'analyse statique Dart.
- `.metadata` : informations generees par Flutter sur le projet.
- `.flutter-plugins-dependencies` : plugins resolus automatiquement.
- `.gitignore` : exclusions propres a Flutter.
- `README.md` : instructions du frontend.
- `main.dart` : petit relais vers `lib/main.dart`, conserve pour compatibilite avec certaines commandes.

### Demarrage Flutter

- `lib/main.dart` : appelle `runApp(SmartFacultyApp)`.
- `lib/application.dart` : restaure la session, affiche l'attente puis cree `MaterialApp` avec theme et routes.

## 12. Coeur et composants Flutter

### `frontend/lib/core/config/api_config.dart`

Adresse de base de FastAPI, construction des URLs et messages de connexion.

### `frontend/lib/coeur/`

- `constantes/constantes_application.dart` : nom et textes globaux.
- `routes/routes_application.dart` : noms des routes, ecrans associes et controle de navigation par role.
- `theme/couleurs_application.dart` : palette officielle.
- `theme/theme_application.dart` : `ThemeData`, champs, boutons, typographie et styles.
- `utilitaires/adaptatif.dart` : aides pour adapter l'interface a la largeur.

### `frontend/lib/commun/composants/`

- `badge_statut.dart` : badge colore pour un statut.
- `capture_camera_partagee.dart` : composant camera reutilise par la biometrie.
- `carte_statistique.dart` : carte d'indicateur.
- `composants_graphiques.dart` : elements de graphiques/visualisations.
- `grille_adaptative.dart` : grille responsive.
- `logo_application.dart` : logo commun.
- `panneau_section.dart` : conteneur visuel d'une section.
- `tableau_intelligent.dart` : tableau reutilisable et adaptable.
- `tuile_fonctionnalite.dart` : tuile de navigation/action.

### `frontend/lib/commun/mises_en_page/structure_adaptative.dart`

Structure generale responsive : navigation, contenu et comportement selon la taille d'ecran.

## 13. Modeles et services Flutter

### `donnees/modeles/modeles_faculte.dart`

Modeles Dart partages, utilisateur courant, roles, conversions entre noms Flutter et valeurs FastAPI.

### Client HTTP

- `service_api.dart` : client central GET/POST/PUT/PATCH/DELETE, Bearer token, refresh automatique, JSON, erreurs et octets.
- `client_api_reponse.dart` : classes de reponses HTTP et types d'erreurs reseau.
- `client_api_web.dart` : implementation HTTP pour navigateur avec `dart:html`.
- `client_api_io.dart` : implementation HTTP pour plateformes Dart IO.
- `client_api_stub.dart` : solution de compilation quand aucune implementation n'est disponible.
- `client_multipart_reponse.dart` : representation d'une partie de fichier multipart.
- `client_multipart_web.dart` : upload multipart Web.
- `client_multipart_io.dart` : upload multipart IO.
- `client_multipart_stub.dart` : remplacement de compilation.

### Fichiers et liens

- `fichier_valve_picker.dart` : choisit automatiquement l'implementation de selection de fichier.
- `fichier_valve_picker_web.dart` : selection de fichier dans le navigateur.
- `fichier_valve_picker_stub.dart` : remplacement hors Web.
- `lien_externe.dart` : choisit l'implementation des liens/telechargements.
- `lien_externe_web.dart` : Blob, URL temporaire et clic de telechargement Web.
- `lien_externe_stub.dart` : remplacement hors Web.

### Session et authentification

- `service_authentification.dart` : connexion, restauration, conversion utilisateur et deconnexion.
- `service_session.dart` : utilisateur courant en memoire.
- `service_persistence.dart` : persistance access token, refresh token et role avec SharedPreferences.

### Services metier Flutter

- `service_appariteur.dart` : appels de gestion appariteur.
- `service_biometrie.dart` : enrolement, revocation et reconnaissance biometrie.
- `service_enseignant.dart` : espace enseignant, cours et encadrements.
- `service_etudiant.dart` : dashboard, cours, enrolements, PDF et projets etudiant.
- `service_inscriptions.dart` : demandes publiques et traitement.
- `service_notes.dart` : evaluations, notes, resultats et deliberations.
- `service_notifications.dart` : liste et lecture des notifications.
- `service_presences.dart` : seances, controle, consultation et corrections.
- `service_reclamations.dart` : reclamations et messages.
- `service_reinitialisations.dart` : mot de passe oublie.
- `service_risques.dart` : risques academiques.
- `service_tableau_de_bord.dart` : indicateurs de dashboards.
- `service_valve.dart` : publications et pieces jointes.
- `referentiel_faculte.dart` : point d'acces a certaines donnees de referentiel, avec dependance historique aux donnees fictives.

## 14. Ecrans Flutter par fonctionnalite

### `fonctionnalites/authentification/presentation/`

- `ecran_connexion.dart` : formulaire de connexion et choix du role.
- `ecran_demande_inscription.dart` : demande de compte etudiant/enseignant.
- `ecran_mot_de_passe_oublie.dart` : workflow de reinitialisation.

### `fonctionnalites/administration/presentation/`

- `ecran_tableau_bord_administration.dart` : accueil administrateur.
- `ecran_gestion_administration.dart` : gestion generique des entites ; certaines mutations y restent simulees.

### `fonctionnalites/apparitorat/presentation/`

- `ecran_tableau_bord_apparitorat.dart` : accueil appariteur.
- `ecran_supervision_appariteur.dart` : gestion et supervision du referentiel.
- `ecran_enrolements_appariteur.dart` : creation, validation et annulation d'enrolements.
- `ecran_projets_encadrements_appariteur.dart` : projets, specialites et attribution des encadreurs.
- `ecran_biometrie_appariteur.dart` : consentement, capture, enrolement et revocation.
- `ecran_assistant_appariteur.dart` : assistant de workflows appariteur prepare pour les operations transversales.

### `fonctionnalites/etudiant/presentation/`

- `ecran_tableau_bord_etudiant.dart` : resume academique reel.
- `ecran_cours_etudiant.dart` : liste et detail des cours.
- `ecran_enrolements_etudiant.dart` : fiches et telechargement PDF.
- `ecran_historique_academique_etudiant.dart` : resultats regroupes par annee/semestre.
- `ecran_notes_etudiant.dart` : notes publiees.
- `ecran_projet_etudiant.dart` : projet et encadreurs.
- `ecran_valve_etudiant.dart` : publications de cours.
- `ecran_alertes_etudiant.dart` : alertes academiques.

### `fonctionnalites/enseignant/presentation/`

- `ecran_tableau_bord_enseignant.dart` : accueil enseignant.
- `ecran_cours_enseignant.dart` : cours et details.
- `ecran_encadrements_enseignant.dart` : projets encadres.

### `fonctionnalites/notes/presentation/`

- `ecran_evaluations_enseignant.dart` : creation et gestion des evaluations.
- `ecran_notes.dart` : encodage des notes.
- `ecran_resultats_academiques.dart` : resultats calcules/publies.
- `ecran_deliberation.dart` : sessions de jury et decisions.

### `fonctionnalites/presences/presentation/`

- `ecran_controle_acces_surveillant.dart` : seance, identification, ouverture et fermeture.
- `ecran_consultation_presences.dart` : vue etudiant, enseignant ou chef selon le mode.
- `ecran_confirmation_cours_2_chef.dart` : confirmation du deuxieme cours par le chef de promotion.

### Autres domaines

- `chef_promotion/ecran_tableau_bord_chef_promotion.dart` : accueil du chef ; conserve certaines donnees historiques fictives.
- `doyen/ecran_tableau_bord_doyen.dart` : accueil du doyen.
- `notifications/ecran_notifications.dart` : liste et lecture.
- `reclamations/ecran_reclamations.dart` : liste et creation.
- `reclamations/ecran_detail_reclamation.dart` : conversation et historique.
- `etudiants_risque/ecran_etudiants_risque.dart` : affichage des niveaux de risque ; une partie historique peut utiliser le referentiel fictif.
- `profil/ecran_profil.dart` : profil utilisateur ; certaines modifications restent simulees.
- `projets/ecran_projets.dart` : ancien ecran generique de projets, distinct des nouveaux espaces specialises.
- `stages/ecran_stages.dart` : module indicatif/historique des stages.
- `analyses/ecran_analyses.dart` : indicateurs analytiques historiques.

Les fichiers utilisant `donnees_faculte_fictives.dart`, ou affichant `mocke`, ne doivent pas etre presentes comme des workflows API totalement finalises.

## 15. Tests Flutter

- `test_application.dart` : lancement, navigation et comportements generaux.
- `theme_application_test.dart` : palette et theme.
- `service_api_test.dart` : client HTTP, erreurs, refresh et persistance.
- `student_service_test.dart` : services etudiant.
- `enseignant_service_test.dart` : services enseignant.
- `appariteur_service_test.dart` : services appariteur.
- `notes_service_test.dart` : notes et deliberations.
- `presence_service_test.dart` : seances et presences.
- `biometrie_service_test.dart` : biometrie.
- `valve_service_test.dart` : valve.
- `reinitialisations_service_test.dart` : mot de passe oublie.

## 16. Flutter Web et assets

### `frontend/web/index.html`

Page HTML qui charge l'application Flutter Web.

### `frontend/web/manifest.json`

Metadonnees PWA : nom, icones, couleurs et mode d'affichage.

### `frontend/web/favicon.png` et `web/icons/`

Icones affichees par le navigateur ou lors de l'installation PWA.

### `frontend/assets/images/logo.PNG`

Logo utilise par les composants Flutter et declare dans `pubspec.yaml`.

## 17. Scripts racine

- `scripts/demarrer_backend.bat` : verifie l'environnement et lance Uvicorn sur le port 8000.
- `scripts/demarrer_frontend.bat` : lance Flutter Web, normalement sur Chrome.
- `scripts/test_backend.bat` : force la base `smart_faculty_test`, la prepare puis lance Pytest.

## 18. Documentation

### `docs/00_Admission/`

Documents de presentation, vision, objectifs, perimetre, acteurs et planification.

### `docs/01_Analyse/`

Analyse fonctionnelle, besoins fonctionnels/non fonctionnels, cas d'utilisation, scenarios et regles metier.

### `docs/02_Conception/`

Architecture generale, base de donnees, structure du projet et API REST.

### Documents Markdown principaux

- `CAHIER_DES_CHARGES_TECHNIQUE.md` : decisions techniques permanentes.
- `JOURNAL_DE_DEVELOPPEMENT.md` : historique detaille des interventions et validations.
- `REGLES_LMD_RDC.md` : regles academiques utilisees par les calculs.
- `ESPACE_ETUDIANT_ACADEMIQUE.md` : perimetre de l'espace etudiant.
- `ENROLEMENTS_ACADEMIQUES_MVP.md` : workflow des enrolements.
- `PROJETS_ENCADREMENTS_MVP.md` : projets et encadreurs.
- `PRESENCES_ACADEMIQUES_MVP.md` : controle d'acces et presences.
- `RECONNAISSANCE_FACIALE_MVP.md` : choix, limites et securite biometrie.
- `DEMONSTRATION_PRESENCES.md` : scenario de demonstration du module.
- `AUDIT_NETTOYAGE_CODE.md` : constats sur le code actif, historique et nettoyage.
- `references_techniques/frontend_smart_faculty.md` : reference de conception Flutter.
- `references_techniques/merise/modelisation_base_donnees_smart_faculty.md` : modelisation Merise.

### `docs/output/`

Contient les livrables generes : monographies Word/PDF, presentation PowerPoint, inventaire JSON de la base, guide LMD et images des modeles Merise. Ce ne sont pas des sources executees par l'application.

## 19. Dossier `legacy/`

### `legacy/php/`

Ancienne implementation PHP avec controleurs, modeles, services, middlewares, routeur et scripts SQL. Elle est archivee et n'est pas lancee par les scripts officiels.

### `legacy/flask/`

Ancien prototype backend Flask, remplace par FastAPI.

### `legacy/autres/`

Anciennes bases SQL, experience IA, fichiers racine obsoletes et scripts vides. Ils servent uniquement de reference historique.

Reponse a donner au jury :

> L'architecture active est Flutter, FastAPI et MySQL. Les anciennes versions PHP et Flask sont conservees dans `legacy` pour la tracabilite, mais elles ne sont plus executees.

## 20. Les fichiers a connaitre en priorite pour une defense

Si le temps est limite, etudier dans cet ordre :

1. `frontend/lib/main.dart` et `application.dart`.
2. `frontend/lib/coeur/routes/routes_application.dart`.
3. `frontend/lib/donnees/services/service_api.dart`.
4. `frontend/lib/donnees/services/service_authentification.dart`.
5. `backend/app/main.py` et `backend/app/routes/api.py`.
6. `backend/app/base_de_donnees/connexion.py`.
7. `backend/app/dependances/authentification.py`.
8. `backend/app/routes/authentification.py` et `services/authentification.py`.
9. Un domaine complet : route, schema, service, modele et test.
10. `backend/tests/conftest.py` et une migration Alembic.

Il n'est pas necessaire de memoriser chaque ligne. Il faut etre capable d'identifier la couche d'un fichier et de raconter le trajet d'une action de Flutter jusqu'a MySQL.

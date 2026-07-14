# Espace Etudiant academique

## Regles

- Le profil est derive du token; le compte utilisateur et le statut academique doivent etre actifs.
- Les cours courants sont les `InscriptionCours` actives de l'etudiant, pour sa promotion, un cours actif et l'annee academique active.
- Une publication Valve et une evaluation sont visibles uniquement avec le statut `publiee`.
- Une note zero est une valeur publiee valide; une absence de ligne reste une absence de note.
- Un resultat de cours non publie n'est jamais presente comme officiel.
- Les resultats semestriels officiels viennent des snapshots publies du moteur de deliberation existant.

Dans le MVP, les inscriptions de cours actives determinent le perimetre
academique courant. `EnrolementAcademique` conserve le dossier administratif
annuel et peut etre absent du seed sans rendre une inscription de cours
invisible.

## Routes

| Route | Usage |
| --- | --- |
| `GET /api/v1/etudiants/moi/tableau-de-bord` | Profil, cours, Valve recente, resultats publies, enrolement et projets |
| `GET /api/v1/etudiants/moi/cours` | Catalogue filtre par le backend |
| `GET /api/v1/etudiants/moi/cours/{id}` | Detail d'un cours inscrit |
| `GET /api/v1/etudiants/moi/cours/{id}/notes` | Notes publiees du cours inscrit |
| `GET /api/v1/etudiants/moi/historique-academique` | Groupes annee/promotion/semestre/cours |
| `GET /api/v1/etudiant/valve` | Valve des cours courants, route historique reutilisee |
| `GET /api/v1/resultats/mes-semestres/{id}/officiel` | Snapshot semestriel publie |

Le backend ne prend jamais un `etudiant_id` libre pour ces routes. Les
reponses excluent les secrets, les champs internes d'encodage et les donnees
d'autres etudiants.

## Interface et limites

Le dashboard presente le profil reel, la promotion, l'annee, les cours
actuels, les publications recentes, les resultats de cours publies, l'etat
du dossier administratif et les projets. Il ne fabrique pas de moyenne, de
presence, de paiement, d'alerte ou de risque. `Historique academique` groupe
les cours par annee, promotion et semestre; un resultat absent est affiche
comme non publie. `Mes resultats` reutilise `AcademicResultsScreen` et le
moteur de deliberation LMD sans recalcul Flutter.

L'attribution des encadreurs, la fiche d'enrolement et la consultation des
projets restent les modules 5B/5C. Presences, paiements, messagerie, risques,
reclamations, seconde session et export PDF restent hors 6A. Aucune migration
n'est requise et les tests utilisent exclusivement `smart_faculty_test`.

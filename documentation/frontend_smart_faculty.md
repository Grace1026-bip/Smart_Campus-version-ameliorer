# Smart Faculty - Architecture frontend

## Architecture proposée

Le frontend Flutter est organisé pour séparer les responsabilités:

- `lib/app.dart`: configuration globale de l'application.
- `lib/core`: constantes, thème, routes, widgets et utilitaires transversaux.
- `lib/data/models`: modèles métier utilisés par l'interface.
- `lib/data/mock`: données fictives pour développer sans backend.
- `lib/data/services`: contrat de repository et session mock, remplaçables par une future couche PHP POO/API REST.
- `lib/features`: écrans organisés par domaine fonctionnel.
- `lib/shared`: composants et layouts réutilisables.

## Charte graphique

- Style: SaaS moderne, institutionnel, sobre et crédible.
- Couleur principale: bleu institutionnel `#0B4A7A`.
- Couleurs secondaires: cyan `#178CA4`, vert succès `#17A673`, ambre alerte `#F59E0B`, rouge risque `#DC2626`.
- Fond principal: gris clair `#F4F7FB`.
- Surfaces: blanc avec bordures discrètes `#D9E2EC`.
- Formes: rayons de 8 px pour garder un rendu professionnel.
- Navigation: sidebar web/tablette, bottom navigation mobile.

## Modules frontend créés

- Authentification et mot de passe oublié.
- Dashboard Administrateur.
- Dashboard Étudiant.
- Dashboard Enseignant.
- Dashboard Chef de promotion.
- Dashboard Doyen.
- Réclamations avec liste, création, détail, statut et historique.
- Analytics avec cartes statistiques, bar charts, pie/donut charts et courbes.
- Projets académiques avec avancement et livrables.
- Stages avec offres, candidature, suivi et validation.
- Notes et résultats avec publication enseignant.
- Étudiants à risque avec niveaux faible, moyen et élevé.

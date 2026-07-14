# Presences academiques et controle d'acces MVP

## Regles retenues

- Une presence est rattachee a une seance et a un cours, jamais uniquement a une journee.
- Les types de seance controles sont `cours_1`, `cours_2` et `autre`.
- Les horaires restent configurables ; les plages 08h00-12h00 et 13h00-17h00 sont des reperes, pas des contraintes de base.
- Le surveillant ouvre, controle et ferme la seance.
- L'identification MVP est manuelle par matricule. Aucune donnee biometrique n'est stockee.
- L'etudiant doit avoir un compte actif, un enrôlement `valide` pour l'annee, une promotion coherente et une inscription active ou validee au cours.
- Le pourcentage administratif de paiement est lu dans `EnrolementAcademique.pourcentage_paiement` ; il n'est pas modifiable par le module Presence et aucun paiement en ligne n'est implemente.
- Un paiement inferieur a 50 % refuse l'acces. Un paiement egal ou superieur a 50 % autorise l'acces si les autres verifications reussissent.
- La contrainte unique `(seance_id, etudiant_id)` empeche les doublons. Le pourcentage observe et le motif de refus sont conserves pour la tracabilite.
- Une seance fermee n'accepte plus de nouvelle presence.
- Pour `cours_2`, le chef de promotion actif confirme la seance uniquement si son profil Etudiant appartient a la promotion concernee.

## Compatibilite avec l'existant

La table historique `presences` du module de suivi des risques est conservee et ses routes Enseignant restent compatibles. Le nouveau moteur utilise `seances_academiques` et `presences_academiques`, sans supprimer ni reinterpreter les anciennes donnees.

Le projet ne possedant pas encore de table active `chefs_promotion`, le perimetre du chef repose sur la convention documentee existante : un utilisateur portant `chef_promotion` doit disposer d'un profil Etudiant actif lie a la promotion. Une table de mandat annuel pourra etre ajoutee ulterieurement si la gestion administrative l'exige.

## API

- `GET/POST /api/v1/surveillant/seances`
- `GET /api/v1/surveillant/seances/{id}`
- `POST /api/v1/surveillant/seances/{id}/ouvrir`
- `POST /api/v1/surveillant/seances/{id}/fermer`
- `GET /api/v1/surveillant/seances/{id}/etudiants`
- `GET /api/v1/surveillant/seances/{id}/presences`
- `POST /api/v1/surveillant/seances/{id}/controle-acces`
- `GET /api/v1/chef-promotion/seances`
- `GET /api/v1/chef-promotion/seances/{id}/presences`
- `POST /api/v1/chef-promotion/seances/{id}/confirmer-cours-2`

Les routes derivent l'autorite du role actif confirme par le token. Flutter n'envoie ni surveillant_id, ni pourcentage, ni promotion autorisee.

## Migration et limites

La migration additive `20260714_0008` ajoute le pourcentage administratif aux enrôlements et les deux tables de presence avec index, cles et contraintes. Elle a ete testee par downgrade puis upgrade sur `smart_faculty_test` uniquement. `smart_faculty` n'est pas une cible de deploiement pour ce prompt.

Le MVP ne couvre pas la reconnaissance faciale, OpenCV, camera, anti-spoofing, biometrie, paiement en ligne, statistiques avancees ni detection des etudiants a risque.

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

## Prompt 7B - Consultation, absences et corrections

La fermeture d'une seance genere idempotemment une presence `absent` pour chaque etudiant actif, enrole `valide`, inscrit au cours et appartenant a la promotion. Les statuts `present`, `retard` et `refuse` existants ne sont jamais remplaces. Un refus d'acces reste donc distinct d'une absence.

Le taux de presence est calcule par FastAPI. Flutter ne recalcule aucune valeur officielle. Les vues Etudiant, Enseignant et Chef de promotion ne retournent pas le pourcentage financier observe.

Les consultations sont derivees du token :

- `GET /api/v1/etudiants/moi/presences` ne retourne que les presences de l'etudiant connecte et son resume ;
- `GET /api/v1/enseignants/moi/seances` et `/enseignants/moi/seances/{id}/presences` filtrent les cours affectes a l'enseignant ;
- les routes Chef de promotion restent limitees a la promotion du profil Etudiant actif ;
- `GET /api/v1/surveillant/seances/{id}/resume` retourne les compteurs de la seance ;
- `PATCH /api/v1/surveillant/seances/{id}/presences/{presence_id}` exige un role Surveillant ou Appariteur et un motif obligatoire.

La migration additive `20260715_0009` cree `corrections_presences_academiques`. Elle conserve l'ancienne valeur, la nouvelle valeur, le motif, l'utilisateur et la date. Les corrections apres fermeture restent possibles uniquement avec cette justification et sont journalisees. Cette migration est appliquee uniquement a `smart_faculty_test` ; `smart_faculty` reste a `20260714_0008` jusqu'a un deploiement separe.

## Prompt 7C-A - Reconnaissance faciale complementaire

La reconnaissance faciale est un moyen d'identification complementaire pour
une seance academique. Elle ne contourne jamais le controle d'acces central :
le compte doit etre actif, l'etudiant doit etre enrole et inscrit selon les
regles du module Presence, et le seuil administratif de 50 % reste applique.

L'Appariteur gere l'enrolement avec consentement explicite. Trois a cinq
captures JPEG ou PNG sont controlees par FastAPI ; les images originales ne
sont pas conservees. Le Surveillant declenche la reconnaissance depuis une
seance ouverte. Un visage inconnu ou ambigu est refuse et ne cree aucune
presence. La presence reste unique par etudiant et seance.

Les profils et encodages sont isoles dans `profils_biometriques` et
`encodages_faciaux`, crees par la migration additive `20260715_0010`. Cette
migration est validee uniquement sur `smart_faculty_test`; `smart_faculty` ne
recoit pas les tables biometriques. La camera Flutter est fournie par le
plugin officiel `camera`; l'anti-spoofing et la vivacite renforcee sont
reportes au Prompt 7C-B.

Le moteur facial reel est injectable mais n'est pas installe dans
l'environnement actuel. La disponibilite du moteur doit donc etre traitee
comme un etat explicite et non comme une reconnaissance simulee. Les details
techniques et les limites sont dans `docs/RECONNAISSANCE_FACIALE_MVP.md`.

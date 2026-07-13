# Projets et encadrements - MVP enseignant

## Regle fonctionnelle confirmee

L'appariteur attribue les enseignants encadreurs en fonction du type de
projet. L'enseignant consulte les etudiants et projets qui lui sont attribues.
L'etudiant consulte les enseignants qui encadrent son projet. La partie
appariteur et la consultation etudiante sont reservees aux modules suivants.

Pour le Prompt 5B, la regle de gestion est precisee ainsi: l'appariteur gere
les projets academiques et attribue les enseignants encadreurs selon le domaine
du projet. Les enseignants consultent uniquement les projets qui leur sont
attribues. Les etudiants consulteront ensuite les encadreurs affectes a leur
projet.

## Types de projets controles

Les valeurs techniques acceptees par le backend sont:

- `reseaux`: Reseaux;
- `systemes_embarques`: Systemes embarques;
- `intelligence_artificielle`: Intelligence artificielle;
- `genie_logiciel`: Genie logiciel.

Flutter ne choisit pas une valeur libre: les valeurs sont validees par le
backend.

## Modele actif du MVP

Un projet appartient a un etudiant, une promotion et une annee academique. Un
projet peut avoir plusieurs encadrements actifs. Un encadrement relie un
enseignant actif a un projet et conserve l'auteur de l'attribution, son role et
sa date.

La contrainte MVP empeche un meme enseignant d'etre actif deux fois sur le meme
projet. Le projet doit toujours referencer un etudiant et un type valide.
Messagerie, depot de fichiers, reunions, evaluation et note de projet sont
hors perimetre.

## Consultation enseignant

Les routes `GET /api/v1/enseignants/moi/encadrements` et
`GET /api/v1/enseignants/moi/encadrements/{encadrement_id}` utilisent
l'enseignant du token. Aucun `enseignant_id` fourni par Flutter ne determine
l'autorite. Les donnees exposees se limitent au projet, a l'etudiant, a la
promotion, a l'annee, au statut, au role d'encadrement et aux autres encadreurs
actifs du meme projet.

L'absence d'encadrement est un etat vide normal et non une erreur.

## Implementation Prompt 4D

La migration `20260713_0005` cree de maniere additive `projets_academiques`
et `encadrements_projet`, avec cles etrangeres, index et contrainte unique
projet-enseignant. Elle ne remplace pas `20260713_0004` et n'a ete appliquee
que sur `smart_faculty_test` pendant la validation.

L'ecran Flutter `Mes encadrements` est accessible par
`/teacher/supervisions`. Il gere le chargement, la liste, l'etat vide, les
erreurs, la session expiree, l'acces refuse et le detail d'un projet. Le
service Flutter utilise les routes `/moi/encadrements` et ne recalcule
aucune donnee metier.

Validation: 13 scenarios backend dedies inclus dans une suite de `120 passed`,
executee deux fois; Flutter `39 passed`, execute deux fois; analyse sans
erreur avec 6 informations historiques; build Web release reussi.

L'attribution appariteur, la consultation etudiante des encadreurs, les
fichiers, la messagerie, les reunions et l'evaluation du projet restent hors
perimetre.

## Gestion appariteur - Prompt 5B

L'appariteur peut creer et gerer un projet pour un etudiant disposant d'un
enrolement academique `valide` pour l'annee concernee. Un etudiant ne peut
avoir qu'un seul projet actif par annee academique. Le type reste limite aux
quatre valeurs techniques controlees ci-dessus.

Les specialites d'encadrement sont des declarations explicites de l'appariteur
pour un enseignant actif. Elles sont filtrees par type de projet, ne sont pas
deduites du nom, du grade ou de l'adresse email, et leur desactivation conserve
l'historique. Un projet accepte un encadreur `principal` et plusieurs
`coencadreurs`; le remplacement ou la desactivation ne supprime jamais
l'ancien encadrement.

La gestion est reservee a un compte actif dont le role actif est
`appariteur`. Les routes de lecture Enseignant restent separees et continuent
de filtrer par l'enseignant issu du token. La consultation des encadreurs par
l'Etudiant et la fiche PDF restent reportees.

# Enrolements academiques - MVP Appariteur

## Regle fonctionnelle

L'appariteur gere les enrolements academiques des etudiants. Un enrolement
valide relie un etudiant, une promotion et une annee academique. L'etudiant
pourra ensuite telecharger sa fiche d'enrolement depuis son propre espace.

Cette notion est distincte de la demande d'inscription au compte. La demande
d'inscription cree ou approuve un utilisateur; l'enrolement rattache ensuite
un etudiant existant a son parcours academique.

## Modele actif

Le socle existant contient `Etudiant`, `Promotion`, `AnneeAcademique`, `Cours`
et `InscriptionCours`. `InscriptionCours` reste une inscription individuelle
a un cours et ne remplace pas l'enrolement annuel. Le MVP ajoute
`EnrolementAcademique` pour conserver le rattachement officiel, son statut,
sa reference et les traces de creation, validation et annulation.

Les cours du programme sont determines par les cours actifs de la promotion.
Le MVP ne cree pas automatiquement de nouvelles lignes `InscriptionCours` et
ne genere pas encore de PDF.

## Regles et statuts

Les statuts sont `en_attente`, `valide` et `annule`. Un etudiant, une
promotion et une annee doivent exister; le compte etudiant doit etre actif,
la promotion doit etre active et son annee doit correspondre a l'annee de
l'enrolement.

Un seul enrolement non annule est autorise pour le triplet etudiant,
promotion, annee. Une validation enregistre l'appariteur, la date et la
reference unique. Une annulation conserve l'historique et libere le triplet
pour un nouvel enrolement. Aucun pourcentage de paiement ne conditionne
l'enrolement dans ce MVP.

## Autorisations et routes

Seul le role actif `appariteur`, verifie depuis le token, peut gerer les
enrolements. Flutter n'envoie jamais d'identifiant d'appariteur d'autorite.

- `GET /api/v1/appariteur/enrolements`;
- `POST /api/v1/appariteur/enrolements`;
- `GET /api/v1/appariteur/enrolements/{id}`;
- `PATCH /api/v1/appariteur/enrolements/{id}` pour un enrolement en attente;
- `POST /api/v1/appariteur/enrolements/{id}/valider`;
- `POST /api/v1/appariteur/enrolements/{id}/annuler`;
- `GET /api/v1/appariteur/etudiants/{etudiant_id}/enrolements`;
- `GET /api/v1/appariteur/enrolements/{id}/fiche/donnees`.

La derniere route expose des donnees structurees pour une future fiche, mais
ne genere aucun fichier.

## Limites

Le telechargement etudiant, l'attribution des encadreurs, les paiements, les
notes, la deliberation, les presences et les inscriptions de comptes sont
hors perimetre du Prompt 5A.

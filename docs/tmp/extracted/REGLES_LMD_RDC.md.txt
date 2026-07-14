# Regles academiques LMD appliquees par Smart Faculty

## Portee

Ce document formalise les decisions de maitrise d'ouvrage retenues pour le
MVP de deliberation Smart Faculty. Elles sont fondees sur les textes
reglementaires communiques par la maitrise d'ouvrage et ne constituent pas une
invention propre a l'application.

## Sources reglementaires de reference

- Decret n°22/39 du 8 decembre 2022 portant organisation et fonctionnement du systeme LMD en Republique Democratique du Congo.
- Arrete ministeriel n°093/MINESU/CAB.MIN/MNB/RMM/2023 du 10 fevrier 2023 portant Cadre normatif du systeme LMD en RDC.
- Arrete ministeriel n°401/MINESU/CABMIN/MNB/RMM/MKK/2023 du 28 aout 2023 portant modalites d'evaluation, de progression et d'orientation en Licence et Maitrise.
- Instruction academique n°027 de l'annee academique 2025-2026.

La page officielle du ministere publie l'Instruction n°027/MINESURS/CAB.MIN/SASM/MMK/2025 du 22 octobre 2025:
https://minesursi.gouv.cd/images/INSTRUCTION%20027.pdf

## Echelle et acquisition

Les resultats internes historiques de Smart Faculty restent stockes sur 100 pour compatibilite avec `ResultatCours`. Le moteur LMD convertit cette valeur vers l'echelle officielle sur 20:

`note_officielle_sur_20 = note_source_sur_100 / 5`

Le seuil d'acquisition est 10/20, soit 50/100 dans la valeur source. Cette regle s'applique aux cours ou elements constitutifs representes, aux UE, au semestre, a l'annee et au cycle selon les donnees disponibles.

Un cours acquis individuellement capitalise ses credits. Un cours inferieur a 10/20 ne capitalise pas ses credits, meme si son semestre est valide par compensation.

## Moyenne, credits et decisions

La moyenne semestrielle est ponderee par les credits:

`sum(note_cours_sur_20 * credits_cours) / sum(credits_cours)`

Le calcul utilise `Decimal`, sans arrondir les contributions. Seul le resultat final est arrondi a deux decimales pour l'affichage. Un semestre normal vaut 30 credits et une annee normale 60 credits.

Une compensation est possible si la moyenne ponderee atteint 10/20, qu'au moins une composante est sous 10/20, qu'aucune note obligatoire ne manque et que les resultats sont publies, verrouilles et coherents.

Les decisions de jury sont limitees a:

- `ADM`: admis, avec capitalisation definitive des credits acquis;
- `COMP`: admis avec compensation, sans capitaliser les cours echoues;
- `DEF`: defaillant en raison de donnees ou notes obligatoires manquantes;
- `AJ`: ajourne ou non admis, avec donnees completes et moyenne sous 10/20.

`en_attente_de_validation` reste un statut technique pre-jury et n'est pas une decision academique finale.

## Convention de modelisation MVP

Le modele actuel `Cours` porte directement les credits et represente l'entite evaluee. Il est donc traite provisoirement comme une UE autonome. Une evolution EC-UE-BCC pourra etre ajoutee plus tard sans modifier la decision actuelle ni casser les donnees existantes. Il n'existe pas encore de modele distinct d'inscription academique: la coherence MVP s'appuie sur les `InscriptionCours` actives.

## Jury, cloture et publication

Les enseignants publient et verrouillent leurs resultats. Le doyen ou le vice-doyen ouvre une session de deliberation, associe les enseignants concernes et designe un president parmi les membres enseignants autorises.

Le president enregistre les decisions collectives et cloture le jury. L'appariteur prepare la grille, controle les anomalies administratives et peut publier une session deja cloturee, mais ne peut ni choisir une decision, ni modifier une moyenne ou des credits, ni publier avant la cloture.

La cloture genere un snapshot officiel immuable. La publication est explicite, atomique et idempotente; l'etudiant ne voit ce snapshot qu'apres publication. Une correction exige une demande motivee du doyen ou du vice-doyen, conserve l'ancienne version et ouvre une nouvelle version de deliberation.

## Limites du MVP

La progression annuelle complete, la seconde session, les releves PDF et la decomposition EC-UE-BCC sont hors perimetre de cette intervention.

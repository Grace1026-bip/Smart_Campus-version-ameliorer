from __future__ import annotations

from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.configuration.parametres import obtenir_parametres
from app.modeles.academique import Cours
from app.modeles.notes import Evaluation, Note, ResultatCours


def arrondir_note(valeur: Decimal) -> Decimal:
    return valeur.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def calculer_resultat_cours(session: Session, etudiant_id: int, cours_id: int) -> ResultatCours:
    parametres = obtenir_parametres()
    seuil_reussite = Decimal(str(parametres.seuil_reussite_cours))
    ponderation_complete = Decimal(str(parametres.ponderation_max_cours))

    cours = session.get(Cours, cours_id)
    if cours is None:
        raise ValueError("Cours introuvable")

    evaluations = session.scalars(
        select(Evaluation).where(
            Evaluation.cours_id == cours_id,
            Evaluation.statut == "publiee",
        )
    ).all()

    moyenne = Decimal("0.00")
    ponderation_publiee = Decimal("0.00")

    for evaluation in evaluations:
        note = session.scalar(
            select(Note).where(
                Note.evaluation_id == evaluation.id,
                Note.etudiant_id == etudiant_id,
            )
        )
        if note is None:
            continue
        note_normalisee = (note.note_obtenue / evaluation.note_maximale) * Decimal("100")
        moyenne += note_normalisee * (evaluation.ponderation / Decimal("100"))
        ponderation_publiee += evaluation.ponderation

    moyenne = arrondir_note(moyenne)
    if not evaluations or ponderation_publiee <= 0 or ponderation_publiee < ponderation_complete:
        statut_resultat = "en_attente"
        credits_obtenus = 0
    elif moyenne >= seuil_reussite:
        statut_resultat = "reussi"
        credits_obtenus = cours.nombre_credits
    else:
        statut_resultat = "echoue"
        credits_obtenus = 0

    resultat = session.scalar(
        select(ResultatCours).where(
            ResultatCours.etudiant_id == etudiant_id,
            ResultatCours.cours_id == cours_id,
        )
    )
    if resultat is None:
        resultat = ResultatCours(
            etudiant_id=etudiant_id,
            cours_id=cours_id,
            moyenne=moyenne,
            credits_obtenus=credits_obtenus,
            statut_resultat=statut_resultat,
        )
        session.add(resultat)
    else:
        resultat.moyenne = moyenne
        resultat.credits_obtenus = credits_obtenus
        resultat.statut_resultat = statut_resultat
        resultat.calcule_le = datetime.utcnow()

    session.flush()
    return resultat
